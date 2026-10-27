#!/usr/bin/env python3
"""Pelis y series para bajar — suggestions from critic RSS feeds, sent to the admin via Telegram.

Crontab: 0 21 * * 1,3,5 (21:00 UTC = 6:00 PM America/Argentina/Buenos_Aires, Mon/Wed/Fri)

Pulls recent reviews from a few critic feeds and extracts the reviewed title. Movies resolve via
Radarr's lookup (TMDB-backed: year, genres, IMDb rating, digital/physical release dates, already
in the library?), series via Sonarr's (TVDB-backed: rating, status, seasons, already in the
library?). The message has up to four short lists:
  - "Para bajar ya": movies already released digitally/physically, not on the server
  - "Se viene": movies with good reviews, digital release date in the next 60 days
  - "Series nuevas": reviewed series not on the server, marked "completa" or "en emisión"
  - "Nuevas temporadas": a reviewed "Season N" of a series already on the server, with no files yet
Floor: rating >= 6.5, except horror (often rated low but worth a look).
Titles already sent (per section) are remembered in STATE_FILE and never repeated.
If there's nothing new, no message is sent.

DRY_RUN=1 ./pelis-propuestas.py  → prints the message, sends nothing, doesn't touch state.

Secrets (Telegram bot token/chat id, Radarr/Sonarr API keys) live in
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
SONARR = "http://127.0.0.1:8989/api/v3"
PEDIDOS = "https://pedidos.matiasmassetti.com"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

MOVIE_FEEDS = {
    "Micropsia": "https://www.micropsiacine.com/feed/",
    "Slant": "https://www.slantmagazine.com/category/film/feed/",
    "THR": "https://www.hollywoodreporter.com/c/movies/movie-reviews/feed/",
    "IndieWire": "https://www.indiewire.com/feed/",
}
# Decider was tested too but left out: its "Stream It Or Skip It" mixes movies and series
TV_FEEDS = {
    "Micropsia": "https://www.micropsiacine.com/category/series/feed/",
    "Slant": "https://www.slantmagazine.com/category/tv/feed/",
    "THR": "https://www.hollywoodreporter.com/c/tv/tv-reviews/feed/",
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
    """Yield (title, season) from each review headline, e.g. "‘Adults’ Season 2 Review: ..." → (Adults, 2)."""
    for raw in re.findall(r"<item.*?<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>", feed_xml, re.S):
        headline = html.unescape(raw).strip()
        if not re.search(r"review|crítica", headline, re.I):
            continue
        # Curly quotes or straight double quotes only — straight singles collide with apostrophes
        m = re.search(r"‘(.+?)’|“(.+?)”|\"(.+?)\"", headline)
        if not m:
            continue
        title = next(g for g in m.groups() if g)
        title = re.sub(r"\s*[–-]\s*Temporada\s*\d+$", "", title)  # Micropsia: "Coppola – Temporada 2"
        season = re.search(r"(?:Season|Temporada)\s*(\d+)", headline, re.I)
        yield title, int(season.group(1)) if season else None


def reviewed(feeds):
    """Yield (title, season, source) across feeds, skipping feeds that fail."""
    for source, url in feeds.items():
        try:
            titles = list(reviewed_titles(fetch(url)))
        except Exception as e:
            print(f"[{source}] feed failed: {e}", file=sys.stderr)
            continue
        for title, season in titles:
            yield title, season, source


def lookup_movie(title, api_key):
    """Best recent match from Radarr's TMDB-backed lookup (skips old films sharing the name)."""
    results = json.loads(fetch(f"{RADARR}/movie/lookup?term={quote(title)}", {"X-Api-Key": api_key}))
    min_year = date.today().year - 2
    return next((r for r in results if (r.get("year") or 0) >= min_year), None)


def lookup_series(title, season, api_key):
    """Best match from Sonarr's lookup: one already in the library first, then (for a "Season N"
    review) any show with that many seasons, else only shows from the last 2 years."""
    results = json.loads(fetch(f"{SONARR}/series/lookup?term={quote(title)}", {"X-Api-Key": api_key}))
    in_library = next((r for r in results if r.get("id")), None)
    if in_library and in_library["title"].lower().startswith(title.lower()[:5]):
        return in_library
    if season:
        return next((r for r in results if len([s for s in r["seasons"] if s["seasonNumber"]]) >= season), None)
    # Newest exact-name match wins: "Minimum Wage" has 2012/2017/2024 namesakes before the 2026 one
    min_year = date.today().year - 2
    recent = [r for r in results if (r.get("year") or 0) >= min_year]
    exact = [r for r in recent if clean_title(r["title"]).lower() == title.lower()]
    return max(exact, key=lambda r: r.get("firstAired", ""), default=recent[0] if recent else None)


def clean_title(title):
    """Drop the disambiguating year TVDB appends to some titles, e.g. "East of Eden (2026)"."""
    return re.sub(r"\s*\(\d{4}\)$", "", title)


def season_has_files(series_id, season, api_key):
    series = json.loads(fetch(f"{SONARR}/series/{series_id}", {"X-Api-Key": api_key}))
    stats = next((s.get("statistics", {}) for s in series["seasons"] if s["seasonNumber"] == season), {})
    return stats.get("episodeFileCount", 0) > 0


def movie_rating(movie):
    r = movie.get("ratings", {})
    return (r.get("imdb") or {}).get("value") or (r.get("tmdb") or {}).get("value")


def series_rating(series):
    return series.get("ratings", {}).get("value") or None


def release_date(movie):
    """Earliest home release (digital or physical) as a date, or None."""
    dates = [movie.get("digitalRelease", "")[:10], movie.get("physicalRelease", "")[:10]]
    dates = [date.fromisoformat(d) for d in dates if d]
    return min(dates) if dates else None


def passes_floor(item, rating):
    return "Horror" in item.get("genres", []) or (rating is not None and rating >= MIN_RATING)


def line(item, rating, source, link, extra=""):
    horror = " 👻" if "Horror" in item.get("genres", []) else ""
    score = f" ⭐ {rating:.1f}" if rating else ""
    text = f"• {clean_title(item['title'])} ({item['year']}){score}{horror}{extra} — {source}"
    return f"{text}\n  {link}" if link else text


def tv_link(series):
    return f"{PEDIDOS}/tv/{series['tmdbId']}" if series.get("tmdbId") else ""


def send_telegram(text):
    data = urlencode({
        "chat_id": os.environ["TELEGRAM_CHAT_ID"],
        "text": text,
        "disable_web_page_preview": "true",
    }).encode()
    url = f"https://api.telegram.org/bot{os.environ['TELEGRAM_BOT_TOKEN']}/sendMessage"
    resp = urlopen(Request(url, data=data), timeout=15)
    print("Telegram send OK:", resp.status)


def movie_sections(sent, api_key, today):
    candidates = {}  # tmdbId → (movie, source)
    for title, _, source in reviewed(MOVIE_FEEDS):
        try:
            movie = lookup_movie(title, api_key)
        except Exception as e:
            print(f"[{source}] movie lookup failed for {title!r}: {e}", file=sys.stderr)
            continue
        if movie and movie["tmdbId"] not in candidates:
            candidates[movie["tmdbId"]] = (movie, source)

    ready, upcoming = [], []
    for tmdb_id, (movie, source) in candidates.items():
        if movie.get("id") or not passes_floor(movie, movie_rating(movie)):  # id > 0 → already in Radarr
            continue
        released = release_date(movie)
        if released and released <= today and f"ready:{tmdb_id}" not in sent:
            ready.append((movie, source))
        elif released and today < released <= today + timedelta(days=UPCOMING_DAYS) \
                and f"upcoming:{tmdb_id}" not in sent:
            upcoming.append((movie, source, released))

    ready = sorted(ready, key=lambda item: -(movie_rating(item[0]) or 0))[:MAX_PER_SECTION]
    upcoming = sorted(upcoming, key=lambda item: item[2])[:MAX_PER_SECTION]
    return ready, upcoming


def series_sections(sent, api_key):
    new_series, new_seasons, seen = [], [], set()
    for title, season, source in reviewed(TV_FEEDS):
        try:
            series = lookup_series(title, season, api_key)
        except Exception as e:
            print(f"[{source}] series lookup failed for {title!r}: {e}", file=sys.stderr)
            continue
        if not series or (series["tvdbId"], season) in seen:
            continue
        seen.add((series["tvdbId"], season))
        rating = series_rating(series)
        if series.get("id"):  # already in Sonarr: only a reviewed season we don't have yet is news
            key = f"season:{series['tvdbId']}:{season}"
            if season and key not in sent and not season_has_files(series["id"], season, api_key):
                new_seasons.append((series, source, season, key))
        elif passes_floor(series, rating) and f"series:{series['tvdbId']}" not in sent:
            new_series.append((series, source, season))

    new_series = sorted(new_series, key=lambda item: -(series_rating(item[0]) or 0))[:MAX_PER_SECTION]
    return new_series, new_seasons


def main():
    load_secrets()
    sent = set(json.loads(STATE_FILE.read_text())) if STATE_FILE.exists() else set()
    today = date.today()

    ready, upcoming = movie_sections(sent, os.environ["RADARR_API_KEY"], today)
    new_series, new_seasons = series_sections(sent, os.environ["SONARR_API_KEY"])

    if not (ready or upcoming or new_series or new_seasons):
        print("Nothing new to suggest, not sending.")
        return

    parts = ["🍿 Pelis y series para bajar"]
    if ready:
        parts += ["", "🎬 Para bajar ya"]
        parts += [line(m, movie_rating(m), s, f"{PEDIDOS}/movie/{m['tmdbId']}") for m, s in ready]
    if upcoming:
        parts += ["", "📅 Se viene"]
        parts += [line(m, movie_rating(m), s, f"{PEDIDOS}/movie/{m['tmdbId']}", f" · sale {d:%d/%m}")
                  for m, s, d in upcoming]
    if new_series:
        parts += ["", "📺 Series nuevas"]
        parts += [line(x, series_rating(x), s, tv_link(x),
                       (f" · T{n}" if n else "") + (" · completa" if x.get("status") == "ended" else " · en emisión"))
                  for x, s, n in new_series]
    if new_seasons:
        parts += ["", "🔁 Nuevas temporadas de lo que ya tenés"]
        parts += [line(x, series_rating(x), s, tv_link(x), f" · T{n}") for x, s, n, _ in new_seasons]
    text = "\n".join(parts)

    if DRY_RUN:
        print("=== DRY RUN — no se manda nada ===")
        print(text)
        return

    send_telegram(text)
    sent |= {f"ready:{m['tmdbId']}" for m, _ in ready}
    sent |= {f"upcoming:{m['tmdbId']}" for m, _, _ in upcoming}
    sent |= {f"series:{x['tvdbId']}" for x, _, _ in new_series}
    sent |= {key for _, _, _, key in new_seasons}
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(sorted(sent)))


if __name__ == "__main__":
    main()
