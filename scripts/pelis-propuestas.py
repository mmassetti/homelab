#!/usr/bin/env python3
"""Pelis para bajar — movie suggestions from film-critic RSS feeds, sent to the admin via Telegram.

Crontab: 0 21 * * 1,3,5 (21:00 UTC = 6:00 PM America/Argentina/Buenos_Aires, Mon/Wed/Fri)

Pulls recent reviews from a few critic feeds, extracts the reviewed title, resolves it via
Radarr's lookup (TMDB-backed: year, genres, IMDb rating, digital/physical release dates,
and whether it's already in the library), then sends two short lists:
  - "Para bajar ya": already released digitally/physically, not on the server
  - "Se viene": good reviews, digital release date in the next 60 days
Floor: IMDb >= 6.5, except horror (often rated low but worth a look).
Titles already sent (per section) are remembered in STATE_FILE and never repeated.
If there's nothing new, no message is sent.

DRY_RUN=1 ./pelis-propuestas.py  → prints the message, sends nothing, doesn't touch state.

Secrets (Telegram bot token/chat id, Radarr API key) live in
~/.config/secrets/homelab_bots.env — NOT committed, this script is pushed to GitHub.
"""
import html
import json
import os
import re
import sys
from datetime import date, timedelta
from pathlib import Path
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen

SECRETS = Path.home() / ".config/secrets/homelab_bots.env"
STATE_FILE = Path.home() / ".local/state/pelis-propuestas/sent.json"
RADARR = "http://127.0.0.1:7878/api/v3"
PEDIDOS = "https://pedidos.matiasmassetti.com/movie/"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

FEEDS = {
    "Micropsia": "https://www.micropsiacine.com/feed/",
    "Slant": "https://www.slantmagazine.com/category/film/feed/",
    "THR": "https://www.hollywoodreporter.com/c/movies/movie-reviews/feed/",
    "IndieWire": "https://www.indiewire.com/feed/",
}
MIN_RATING = 6.5
MAX_PER_SECTION = 5
UPCOMING_DAYS = 60
DRY_RUN = os.environ.get("DRY_RUN") == "1"


def load_secrets():
    for line in SECRETS.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip().strip("'\""))


def fetch(url, headers=None):
    req = Request(url, headers={"User-Agent": UA, **(headers or {})})
    return urlopen(req, timeout=20).read().decode("utf-8", "replace")


def reviewed_titles(feed_xml):
    """Yield the quoted film title from each review headline, e.g. "‘Tony’ Review: ..." → Tony."""
    for raw in re.findall(r"<item.*?<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>", feed_xml, re.S):
        headline = html.unescape(raw).strip()
        if not re.search(r"review|crítica", headline, re.I):
            continue
        # Curly quotes or straight double quotes only — straight singles collide with apostrophes
        m = re.search(r"‘(.+?)’|“(.+?)”|\"(.+?)\"", headline)
        if m:
            yield next(g for g in m.groups() if g)


def lookup(title, api_key):
    """Best recent match from Radarr's TMDB-backed lookup (skips old films sharing the name)."""
    results = json.loads(fetch(f"{RADARR}/movie/lookup?term={quote(title)}", {"X-Api-Key": api_key}))
    min_year = date.today().year - 2
    return next((r for r in results if (r.get("year") or 0) >= min_year), None)


def rating(movie):
    r = movie.get("ratings", {})
    return (r.get("imdb") or {}).get("value") or (r.get("tmdb") or {}).get("value")


def release_date(movie):
    """Earliest home release (digital or physical) as a date, or None."""
    dates = [movie.get("digitalRelease", "")[:10], movie.get("physicalRelease", "")[:10]]
    dates = [date.fromisoformat(d) for d in dates if d]
    return min(dates) if dates else None


def passes_floor(movie):
    if "Horror" in movie.get("genres", []):
        return True
    r = rating(movie)
    return r is not None and r >= MIN_RATING


def line(movie, source, extra=""):
    r = rating(movie)
    horror = " 👻" if "Horror" in movie.get("genres", []) else ""
    score = f" ⭐ {r:.1f}" if r else ""
    return f"• {movie['title']} ({movie['year']}){score}{horror}{extra} — {source}\n  {PEDIDOS}{movie['tmdbId']}"


def send_telegram(text):
    data = urlencode({
        "chat_id": os.environ["TELEGRAM_CHAT_ID"],
        "text": text,
        "disable_web_page_preview": "true",
    }).encode()
    url = f"https://api.telegram.org/bot{os.environ['TELEGRAM_BOT_TOKEN']}/sendMessage"
    resp = urlopen(Request(url, data=data), timeout=15)
    print("Telegram send OK:", resp.status)


def main():
    load_secrets()
    api_key = os.environ["RADARR_API_KEY"]
    sent = set(json.loads(STATE_FILE.read_text())) if STATE_FILE.exists() else set()
    today = date.today()

    candidates = {}  # tmdbId → (movie, source)
    for source, url in FEEDS.items():
        try:
            titles = list(reviewed_titles(fetch(url)))
        except Exception as e:
            print(f"[{source}] feed failed: {e}", file=sys.stderr)
            continue
        for title in titles:
            try:
                movie = lookup(title, api_key)
            except Exception as e:
                print(f"[{source}] lookup failed for {title!r}: {e}", file=sys.stderr)
                continue
            if movie and movie["tmdbId"] not in candidates:
                candidates[movie["tmdbId"]] = (movie, source)

    ready, upcoming = [], []
    for tmdb_id, (movie, source) in candidates.items():
        if movie.get("id") or not passes_floor(movie):  # id > 0 → already in Radarr
            continue
        released = release_date(movie)
        if released and released <= today and f"ready:{tmdb_id}" not in sent:
            ready.append((movie, source))
        elif released and today < released <= today + timedelta(days=UPCOMING_DAYS) \
                and f"upcoming:{tmdb_id}" not in sent:
            upcoming.append((movie, source, released))

    by_rating = lambda item: -(rating(item[0]) or 0)
    ready = sorted(ready, key=by_rating)[:MAX_PER_SECTION]
    upcoming = sorted(upcoming, key=lambda item: item[2])[:MAX_PER_SECTION]

    if not ready and not upcoming:
        print("Nothing new to suggest, not sending.")
        return

    parts = ["🍿 Pelis para bajar"]
    if ready:
        parts += ["", "🎬 Para bajar ya"] + [line(m, s) for m, s in ready]
    if upcoming:
        parts += ["", "📅 Se viene"] + [line(m, s, f" · sale {d:%d/%m}") for m, s, d in upcoming]
    text = "\n".join(parts)

    if DRY_RUN:
        print("=== DRY RUN — no se manda nada ===")
        print(text)
        return

    send_telegram(text)
    sent |= {f"ready:{m['tmdbId']}" for m, _ in ready}
    sent |= {f"upcoming:{m['tmdbId']}" for m, _, _ in upcoming}
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(sorted(sent)))


if __name__ == "__main__":
    main()
