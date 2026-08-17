#!/usr/bin/env python3
"""Backfill .lrc lyrics sidecars for the music library using the free LRCLIB API.

Idempotent: re-running skips tracks that already have a .lrc next to them, so
it's safe to invoke again after future Lidarr/Soularr imports pull in new
albums. Not wired into any automated hook on purpose -- re-run manually.

Usage:
    python3 backfill_lyrics.py --dry-run   # see hit rate without writing files
    python3 backfill_lyrics.py             # actual write pass
"""
import argparse
import logging
import sys
import time
from pathlib import Path
from urllib.parse import urlencode

import requests
from mutagen import File as MutagenFile

LRCLIB_URL = "https://lrclib.net/api/get"
USER_AGENT = "homelab-lyrics-backfill/1.0"
AUDIO_EXTS = {".flac", ".mp3", ".m4a", ".ogg"}

logging.basicConfig(level=logging.INFO, format="%(message)s")
log = logging.getLogger("backfill_lyrics")


def read_tags(path: Path):
    easy = MutagenFile(path, easy=True)
    full = MutagenFile(path)
    if easy is None or full is None:
        return None
    artist = (easy.get("artist") or [None])[0]
    title = (easy.get("title") or [None])[0]
    album = (easy.get("album") or [None])[0]
    duration = int(full.info.length) if full.info and full.info.length else None
    if not artist or not title or duration is None:
        return None
    return {"artist": artist, "title": title, "album": album or "", "duration": duration}


def fetch_lyrics(tags: dict, session: requests.Session, retries: int = 3):
    params = {
        "artist_name": tags["artist"],
        "track_name": tags["title"],
        "album_name": tags["album"],
        "duration": tags["duration"],
    }
    url = f"{LRCLIB_URL}?{urlencode(params)}"
    backoff = 1
    for attempt in range(retries + 1):
        try:
            resp = session.get(url, headers={"User-Agent": USER_AGENT}, timeout=10)
        except requests.RequestException as e:
            if attempt == retries:
                return ("error", str(e))
            time.sleep(backoff)
            backoff *= 2
            continue

        if resp.status_code == 404:
            return ("not_found", None)
        if resp.status_code == 200:
            data = resp.json()
            synced = (data.get("syncedLyrics") or "").strip()
            plain = (data.get("plainLyrics") or "").strip()
            if synced:
                return ("synced", synced)
            if plain:
                return ("plain", plain)
            return ("found_but_empty", None)
        if resp.status_code >= 500 and attempt < retries:
            time.sleep(backoff)
            backoff *= 2
            continue
        return ("error", f"HTTP {resp.status_code}")
    return ("error", "exhausted retries")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library-path", default="/mnt/nas/Music")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--sleep", type=float, default=0.75)
    args = parser.parse_args()

    root = Path(args.library_path)
    if not root.is_dir():
        log.error("Library path not found: %s", root)
        sys.exit(1)

    counts = {
        "scanned": 0,
        "already_had_lrc": 0,
        "missing_tags": 0,
        "synced": 0,
        "plain": 0,
        "found_but_empty": 0,
        "not_found": 0,
        "error": 0,
    }

    session = requests.Session()
    files = sorted(p for p in root.rglob("*") if p.suffix.lower() in AUDIO_EXTS)

    for path in files:
        counts["scanned"] += 1
        sidecar = path.with_suffix(".lrc")
        if sidecar.exists():
            counts["already_had_lrc"] += 1
            continue

        tags = read_tags(path)
        if tags is None:
            counts["missing_tags"] += 1
            log.info("SKIP (missing tags): %s", path)
            continue

        status, payload = fetch_lyrics(tags, session)
        counts[status] = counts.get(status, 0) + 1

        if status in ("synced", "plain"):
            if args.dry_run:
                log.info("[dry-run] would write %s lyrics: %s", status, path)
            else:
                sidecar.write_text(payload, encoding="utf-8")
                log.info("Wrote %s lyrics: %s", status, sidecar)
        elif status == "not_found":
            log.info("Not found on LRCLIB: %s - %s", tags["artist"], tags["title"])
        elif status == "error":
            log.warning("Error fetching lyrics for %s: %s", path, payload)

        time.sleep(args.sleep)

    log.info("\n=== Summary ===")
    for key, value in counts.items():
        log.info("%s: %s", key, value)


if __name__ == "__main__":
    main()
