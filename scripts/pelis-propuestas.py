#!/usr/bin/env python3
"""Pelis y series para bajar — suggestions from critic RSS feeds, sent to the admin via Telegram.

Crontab (21:00 UTC = 6:00 PM America/Argentina/Buenos_Aires):
  0 21 * * 0,2,3,5,6  pelis-propuestas.py          → collect only (queue new suggestions)
  0 21 * * 1,4        pelis-propuestas.py --send   → collect, then send the queue (Mon/Thu)
Collection runs daily because Micropsia's feed only keeps its last ~10 posts (~2 days).

Pulls recent reviews from a few critic feeds and extracts the reviewed title. Movies resolve via
Radarr's lookup (TMDB-backed: year, genres, IMDb rating, digital/physical release dates, already
in the library?), series via Sonarr's (TVDB-backed: rating, status, seasons, already in the
library?). The message has up to four short lists:
  - "Para bajar ya": movies already released digitally/physically, not on the server
  - "Se viene": movies with good reviews, digital release date in the next 60 days
  - "Series nuevas": reviewed series not on the server, marked "completa" or "en emisión"
  - "Nuevas temporadas": a reviewed "Season N" of a series already on the server, with no files yet
Floor: rating >= 6.5, except horror (often rated low but worth a look).
STATE_FILE holds the pending queue and the keys already sent (per section), which are never
repeated. At send time, queued items that reached the library or are older than PENDING_DAYS
are dropped, and upcoming movies that are out by now move to "Para bajar ya". Items over a
section's cap stay queued for the next send. If there's nothing new, no message is sent.

DRY_RUN=1 ./pelis-propuestas.py --send  → prints the message, sends nothing, doesn't touch state.

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
PENDING_DAYS = 30  # a collected suggestion not sent within this many days is dropped
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


def line(c):
    horror = " 👻" if c["horror"] else ""
    score = f" ⭐ {c['rating']:.1f}" if c["rating"] else ""
    text = f"• {c['title']} ({c['year']}){score}{horror}{c['extra']} — {c['source']}"
    return f"{text}\n  {c['link']}" if c["link"] else text


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


def candidate(section, key, item, rating, source, link, extra="", **fields):
    """A suggestion as stored in the pending queue (plain JSON, so it survives between runs)."""
    return {
        "section": section, "key": key, "title": clean_title(item["title"]), "year": item["year"],
        "rating": rating, "horror": "Horror" in item.get("genres", []), "source": source,
        "link": link, "extra": extra, "found": date.today().isoformat(), **fields,
    }


def movie_candidates(api_key, today):
    movies = {}  # tmdbId → (movie, source)
    for title, _, source in reviewed(MOVIE_FEEDS):
        try:
            movie = lookup_movie(title, api_key)
        except Exception as e:
            print(f"[{source}] movie lookup failed for {title!r}: {e}", file=sys.stderr)
            continue
        if movie and movie["tmdbId"] not in movies:
            movies[movie["tmdbId"]] = (movie, source)

    for tmdb_id, (movie, source) in movies.items():
        rating = movie_rating(movie)
        if movie.get("id") or not passes_floor(movie, rating):  # id > 0 → already in Radarr
            continue
        released = release_date(movie)
        link = f"{PEDIDOS}/movie/{tmdb_id}"
        if released and released <= today:
            yield candidate("ready", f"ready:{tmdb_id}", movie, rating, source, link, tmdbId=tmdb_id)
        elif released and released <= today + timedelta(days=UPCOMING_DAYS):
            yield candidate("upcoming", f"upcoming:{tmdb_id}", movie, rating, source, link,
                            tmdbId=tmdb_id, release=released.isoformat())


def series_candidates(api_key):
    seen = set()
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
            if season and not season_has_files(series["id"], season, api_key):
                yield candidate("season", f"season:{series['tvdbId']}:{season}", series, rating, source,
                                tv_link(series), f" · T{season}", seriesId=series["id"], season=season)
        elif passes_floor(series, rating):
            status = " · completa" if series.get("status") == "ended" else " · en emisión"
            yield candidate("series", f"series:{series['tvdbId']}", series, rating, source,
                            tv_link(series), (f" · T{season}" if season else "") + status,
                            tvdbId=series["tvdbId"])


def load_state():
    if not STATE_FILE.exists():
        return {"sent": [], "pending": {}}
    state = json.loads(STATE_FILE.read_text())
    return {"sent": state, "pending": {}} if isinstance(state, list) else state  # pre-queue format


def collect(state, today):
    """Add newly reviewed titles to the pending queue. Runs daily: Micropsia's feed only keeps ~2 days."""
    sent, pending = set(state["sent"]), state["pending"]
    added = 0
    for c in [*movie_candidates(os.environ["RADARR_API_KEY"], today),
              *series_candidates(os.environ["SONARR_API_KEY"])]:
        if c["key"] not in sent and c["key"] not in pending:
            pending[c["key"]] = c
            added += 1
    print(f"Collected {added} new suggestions, {len(pending)} pending.")


def still_relevant(c, today):
    """Drop stale suggestions and anything that reached the library since it was collected."""
    if date.fromisoformat(c["found"]) < today - timedelta(days=PENDING_DAYS):
        return False
    if c["section"] in ("ready", "upcoming"):
        movies = json.loads(fetch(f"{RADARR}/movie?tmdbId={c['tmdbId']}",
                                  {"X-Api-Key": os.environ["RADARR_API_KEY"]}))
        return not movies
    if c["section"] == "series":
        series = json.loads(fetch(f"{SONARR}/series?tvdbId={c['tvdbId']}",
                                  {"X-Api-Key": os.environ["SONARR_API_KEY"]}))
        return not series
    return not season_has_files(c["seriesId"], c["season"], os.environ["SONARR_API_KEY"])


def build_message(state, today):
    """Pick what to send from the pending queue. Returns (text, sent keys) or (None, [])."""
    sent, pending = set(state["sent"]), state["pending"]
    for key, c in list(pending.items()):
        if not still_relevant(c, today):
            del pending[key]
            continue
        # An upcoming movie that's out by now moves to "Para bajar ya"
        if c["section"] == "upcoming" and date.fromisoformat(c["release"]) <= today:
            del pending[key]
            ready_key = f"ready:{c['tmdbId']}"
            if ready_key not in sent:
                pending[ready_key] = {**c, "section": "ready", "key": ready_key}

    def pick(section, order, limit=MAX_PER_SECTION):
        items = sorted((c for c in pending.values() if c["section"] == section), key=order)
        return items[:limit] if limit else items

    by_rating = lambda c: -(c["rating"] or 0)
    ready = pick("ready", by_rating)
    upcoming = pick("upcoming", lambda c: c["release"])
    new_series = pick("series", by_rating)
    new_seasons = pick("season", by_rating, limit=None)
    for c in upcoming:
        c["extra"] = f" · sale {date.fromisoformat(c['release']):%d/%m}"

    sections = [("🎬 Para bajar ya", ready), ("📅 Se viene", upcoming), ("📺 Series nuevas", new_series),
                ("🔁 Nuevas temporadas de lo que ya tenés", new_seasons)]
    if not any(items for _, items in sections):
        return None, []
    parts = ["🍿 Pelis y series para bajar"]
    for header, items in sections:
        if items:
            parts += ["", header] + [line(c) for c in items]
    return "\n".join(parts), [c["key"] for _, items in sections for c in items]


def main():
    load_secrets()
    state = load_state()
    today = date.today()
    collect(state, today)

    if "--send" in sys.argv:
        text, keys = build_message(state, today)
        if not text:
            print("Nothing new to suggest, not sending.")
        elif DRY_RUN:
            print("=== DRY RUN — no se manda nada ===")
            print(text)
        else:
            send_telegram(text)
            state["sent"] = sorted(set(state["sent"]) | set(keys))
            for key in keys:
                state["pending"].pop(key, None)

    if DRY_RUN:
        return
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
