#!/bin/bash
# Viernes de Novedades — weekly digest sent via Telegram to every Jellyseerr user who has
# Telegram notifications linked (auto-discovered, not a hardcoded list).
# Crontab: 0 19 * * 5 /home/matias/homelab/scripts/weekly-digest.sh >> /tmp/weekly-digest.log 2>&1
# (19:00 UTC = 4:00 PM America/Argentina/Buenos_Aires, Fridays)
#
# Sections (each optional, only appears if it has content):
#   - Estrenos en cines esta semana (carteleraargentina.com.ar, scraped — no official API)
#   - Se sumó al server de Masa (Radarr/Sonarr history, last 7 days)
#   - Lo más visto esta semana (Jellyfin Playback Reporting plugin SQL query)
#   - Tendencias que todavía no tenemos (Jellyseerr discover, with direct pedidos.matiasmassetti.com links)
#   - Rescate del catálogo (random pick: never played + added 90+ days ago)
#   - Espacio libre (NAS df)
# Sends the top suggestion's poster as a photo first (if any), then the text digest.
# If literally nothing to report, no message is sent that week (no filler).
#
# DRY_RUN=1 ./weekly-digest.sh   → prints what would be sent and to whom, sends nothing.
#
# Secrets (Telegram bot token, Radarr/Sonarr/Jellyseerr/Jellyfin API keys) live in
# ~/.config/secrets/homelab_bots.env — NOT committed, this script is pushed to GitHub.

set -uo pipefail

SECRETS="/home/matias/.config/secrets/homelab_bots.env"
if [ -f "$SECRETS" ]; then
    set -a
    source "$SECRETS"
    set +a
else
    echo "Missing $SECRETS — aborting." >&2
    exit 1
fi

DRY_RUN="${DRY_RUN:-0}"
FECHA=$(TZ="America/Argentina/Buenos_Aires" date '+%d/%m/%Y')
FECHA_DASH=$(TZ="America/Argentina/Buenos_Aires" date '+%d-%m-%Y')
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"

# --- 1. Estrenos en cines esta semana ---
CARTELERA=$(curl -sL -A "$UA" --max-time 15 "https://www.carteleraargentina.com.ar/" 2>/dev/null | python3 -c "
import sys, re
html = sys.stdin.read()
m = re.search(r'<h2>Estrenos de la semana</h2>(.*?)<h2', html, re.S)
if not m:
    sys.exit(0)
titles = re.findall(r'<h3>([^<]+)</h3>', m.group(1))
for t in titles[:10]:
    print(t.strip())
" 2>/dev/null || true)

# --- 1b. En cartelera en Bahía Blanca: PDF real de Cinemacenter (cityId=2), no una aproximación ---
SIGUEN=$(curl -sL -A "$UA" --max-time 15 "https://www.cinemacenter.com.ar/pdf/horariospdf.php?cityId=2" 2>/dev/null | \
    pdftotext -layout - - 2>/dev/null | python3 -c "
import sys, re, unicodedata

def norm(s):
    s = unicodedata.normalize('NFKD', s).encode('ascii', 'ignore').decode().lower().strip()
    return re.sub(r'\s+', ' ', s)

text = sys.stdin.read()
estrenos_norm = {norm(l) for l in '''${CARTELERA}'''.split(chr(10)) if l.strip()}

seen = set()
out = []
for line in text.split(chr(10)):
    line = line.strip()
    m = re.match(r'^(.*?)\s*-\s*\d?[A-Z]*\s*(CAST|SUB)(\s*\(SALA[^)]*\))?$', line)
    if not m:
        continue
    title = m.group(1).strip().title()
    key = norm(title)
    if key in seen or key in estrenos_norm:
        continue
    seen.add(key)
    out.append(title)
for t in out[:10]:
    print(t)
" 2>/dev/null || true)

# --- 2. Se sumó al server de Masa (Radarr movies + Sonarr series with new episodes) ---
ADDED=$(python3 -c "
import urllib.request, json
from datetime import datetime, timedelta, timezone

cutoff = datetime.now(timezone.utc) - timedelta(days=7)
lines = []

def fetch(url, key):
    req = urllib.request.Request(url, headers={'X-Api-Key': key})
    return json.loads(urllib.request.urlopen(req, timeout=10).read())

try:
    d = fetch('http://localhost:7878/api/v3/history?page=1&pageSize=100&sortKey=date&sortDirection=descending&eventType=3&includeMovie=true', '${RADARR_API_KEY}')
    seen = set()
    for r in d.get('records', []):
        dt = datetime.fromisoformat(r['date'].replace('Z', '+00:00'))
        if dt < cutoff:
            break
        title = r.get('movie', {}).get('title', r.get('sourceTitle', '?'))
        if title not in seen:
            seen.add(title)
            lines.append(f'🎬 {title}')
except Exception:
    pass

try:
    d = fetch('http://localhost:8989/api/v3/history?page=1&pageSize=200&sortKey=date&sortDirection=descending&eventType=3&includeSeries=true&includeEpisode=true', '${SONARR_API_KEY}')
    seen_series = set()
    for r in d.get('records', []):
        dt = datetime.fromisoformat(r['date'].replace('Z', '+00:00'))
        if dt < cutoff:
            break
        s = r.get('series', {}).get('title', '?')
        if s not in seen_series:
            seen_series.add(s)
            lines.append(f'📺 {s} (nuevos episodios)')
except Exception:
    pass

for line in lines[:8]:
    print(line)
" 2>/dev/null || true)

# --- 3. Lo más visto esta semana (Playback Reporting) ---
TOP_WATCHED=$(python3 -c "
import urllib.request, json
key = '${JELLYFIN_API_KEY}'
query = 'SELECT ItemName, COUNT(*) as PlayCount FROM PlaybackActivity WHERE DateCreated >= datetime(\"now\", \"-7 days\") GROUP BY ItemName ORDER BY PlayCount DESC LIMIT 5'
req = urllib.request.Request(
    'http://localhost:8096/user_usage_stats/submit_custom_query',
    data=json.dumps({'CustomQueryString': query, 'ReplaceUserId': False}).encode(),
    headers={'X-Emby-Token': key, 'Content-Type': 'application/json'}
)
try:
    d = json.loads(urllib.request.urlopen(req, timeout=10).read())
    for name, count in d.get('results', []):
        plural = 'reproducciones' if int(count) != 1 else 'reproducción'
        print(f'{name} ({count} {plural})')
except Exception:
    pass
" 2>/dev/null || true)

# --- 4. Tendencias que todavía no tenemos (con link directo a pedidos) ---
SUGGESTIONS_RAW=$(python3 -c "
import urllib.request, json
key = '${JELLYSEERR_API_KEY}'
req = urllib.request.Request('http://localhost:5055/api/v1/discover/trending?page=1', headers={'X-Api-Key': key})
lines = []
try:
    d = json.loads(urllib.request.urlopen(req, timeout=10).read())
    for r in d.get('results', []):
        mtype = r.get('mediaType')
        if mtype not in ('movie', 'tv'):
            continue
        mi = r.get('mediaInfo')
        status = mi.get('status') if mi else None
        if status not in (None, 1):
            continue
        title = r.get('title') or r.get('name')
        year = (r.get('releaseDate') or r.get('firstAirDate') or '')[:4]
        icon = '🎬' if mtype == 'movie' else '📺'
        label = f'{icon} {title} ({year})' if year else f'{icon} {title}'
        link = f'https://pedidos.matiasmassetti.com/{mtype}/{r[\"id\"]}'
        poster = r.get('posterPath', '')
        lines.append(f'{label}\t{link}\t{poster}\t{title}')
        if len(lines) >= 6:
            break
except Exception:
    pass
for l in lines:
    print(l)
" 2>/dev/null || true)

SUGGESTIONS=""
TOP_POSTER=""
TOP_TITLE=""
if [ -n "$SUGGESTIONS_RAW" ]; then
    first=true
    while IFS=$'\t' read -r label link poster title; do
        SUGGESTIONS="${SUGGESTIONS}${label} → ${link}"$'\n'
        if [ "$first" = true ]; then
            TOP_POSTER="$poster"
            TOP_TITLE="$title"
            first=false
        fi
    done <<< "$SUGGESTIONS_RAW"
    SUGGESTIONS="${SUGGESTIONS%$'\n'}"
fi

# --- 5. Pick de la semana: pick random de una lista curada a mano, con año/género/sinopsis ---
# Editable en scripts/rescate-catalogo.txt — un título por línea, se valida contra
# la biblioteca real de Jellyfin (Movies + Series) antes de elegir.
RESCATE_FILE="/home/matias/homelab/scripts/rescate-catalogo.txt"
RESCUE=$(python3 -c "
import urllib.request, json, random

jf_key = '${JELLYFIN_API_KEY}'

def jf_get(path):
    req = urllib.request.Request(f'http://localhost:8096{path}', headers={'X-Emby-Token': jf_key})
    return json.loads(urllib.request.urlopen(req, timeout=15).read())

try:
    with open('${RESCATE_FILE}') as f:
        curated = [l.strip() for l in f if l.strip() and not l.strip().startswith('#')]
    if not curated:
        raise SystemExit

    movies = jf_get('/Items?IncludeItemTypes=Movie,Series&Recursive=true&Fields=Genres,ProductionYear,Overview&Limit=5000')
    library = {m['Name']: m for m in movies.get('Items', [])}

    valid = [t for t in curated if t in library]
    if valid:
        pick = library[random.choice(valid)]
        year = pick.get('ProductionYear', '')
        genres = ', '.join(pick.get('Genres', [])[:2])
        overview = (pick.get('Overview') or '').strip().replace(chr(10), ' ')
        if len(overview) > 140:
            overview = overview[:140].rsplit(' ', 1)[0] + '…'
        print(f\"{pick['Name']}\t{year}\t{genres}\t{overview}\")
except Exception:
    pass
" 2>/dev/null || true)

# --- 6. Espacio libre (NAS), con mensaje según cuánto queda ---
NAS_USE=$(df /mnt/nas --output=pcent,avail 2>/dev/null | tail -1 | xargs || true)
DISK_LINE=""
if [ -n "$NAS_USE" ]; then
    NAS_PCT=$(echo "$NAS_USE" | awk '{print $1}')
    NAS_FREE=$(echo "$NAS_USE" | awk '{print $2}')
    NAS_FREE_H=$(numfmt --from=iec --to=iec "${NAS_FREE}K" 2>/dev/null || echo "${NAS_FREE}")
    NAS_FREE_GB=$(( NAS_FREE / 1024 / 1024 ))
    if [ "$NAS_FREE_GB" -gt 100 ]; then
        DISK_MSG=" — pedí tranqui, hay espacio 😌"
    elif [ "$NAS_FREE_GB" -le 30 ]; then
        DISK_MSG=" — se está quedando sin espacio, pedí con cuidado ⚠️"
    else
        DISK_MSG=""
    fi
    DISK_LINE="NAS: ${NAS_PCT} usado, ${NAS_FREE_H} libre${DISK_MSG}"
fi

# --- Skip entirely if nothing to report ---
if [ -z "$CARTELERA" ] && [ -z "$SIGUEN" ] && [ -z "$ADDED" ] && [ -z "$TOP_WATCHED" ] && [ -z "$SUGGESTIONS" ] && [ -z "$RESCUE" ]; then
    echo "Nada para reportar esta semana, no se manda nada."
    exit 0
fi

BODY=""
add() { BODY="${BODY}${1}"$'\n'; }

add "🎬 Viernes de Novedades — ${FECHA}"

if [ -n "$CARTELERA" ]; then
    add ""
    add "🎦 Estrenos en cines esta semana"
    while IFS= read -r line; do
        add "• ${line}"
    done <<< "$CARTELERA"
fi

if [ -n "$SIGUEN" ]; then
    add ""
    add "🎟 En cartelera en Bahía Blanca"
    while IFS= read -r line; do
        add "• ${line}"
    done <<< "$SIGUEN"
fi

if [ -n "$ADDED" ]; then
    add ""
    add "🆕 Se sumó al server de Masa"
    while IFS= read -r line; do
        add "• ${line}"
    done <<< "$ADDED"
fi

if [ -n "$TOP_WATCHED" ]; then
    add ""
    add "🔥 Lo más visto esta semana"
    while IFS= read -r line; do
        add "• ${line}"
    done <<< "$TOP_WATCHED"
fi

if [ -n "$SUGGESTIONS" ]; then
    add ""
    add "💡 Tendencias que todavía no tenemos"
    while IFS= read -r line; do
        add "• ${line}"
    done <<< "$SUGGESTIONS"
fi

if [ -n "$RESCUE" ]; then
    IFS=$'\t' read -r rescue_title rescue_year rescue_genres rescue_overview <<< "$RESCUE"
    add ""
    add "🎯 Pick de la semana"
    meta=""
    [ -n "$rescue_year" ] && meta="${rescue_year}"
    [ -n "$rescue_genres" ] && meta="${meta}${meta:+ · }${rescue_genres}"
    if [ -n "$meta" ]; then
        add "• ${rescue_title} (${meta})"
    else
        add "• ${rescue_title}"
    fi
    [ -n "$rescue_overview" ] && add "  ${rescue_overview}"
fi

if [ -n "$DISK_LINE" ]; then
    add ""
    add "💾 ${DISK_LINE}"
fi

# --- Recipients: every Jellyseerr user with Telegram notifications enabled + a chat ID set ---
# TEST_CHAT_ID overrides this to send only to one chat, for safe testing.
if [ -n "${TEST_CHAT_ID:-}" ]; then
    RECIPIENTS="${TEST_CHAT_ID}"$'\t'"test"
else
RECIPIENTS=$(python3 -c "
import urllib.request, json
key = '${JELLYSEERR_API_KEY}'
req = urllib.request.Request('http://localhost:5055/api/v1/user?take=100', headers={'X-Api-Key': key})
users = json.loads(urllib.request.urlopen(req, timeout=10).read())['results']
for u in users:
    uid = u['id']
    req2 = urllib.request.Request(f'http://localhost:5055/api/v1/user/{uid}/settings/notifications', headers={'X-Api-Key': key})
    try:
        settings = json.loads(urllib.request.urlopen(req2, timeout=10).read())
    except Exception:
        continue
    chat_id = settings.get('telegramChatId')
    enabled = settings.get('telegramEnabled')
    if chat_id and enabled:
        print(f\"{chat_id}\t{u.get('displayName','?')}\")
")
fi

if [ -z "$RECIPIENTS" ]; then
    echo "No hay destinatarios con Telegram configurado. Nada que enviar."
    exit 0
fi

if [ "$DRY_RUN" = "1" ]; then
    echo "=== DRY RUN — no se manda nada ==="
    if [ -n "$TOP_POSTER" ]; then
        echo "--- Poster que se mandaría primero ---"
        echo "https://image.tmdb.org/t/p/w500${TOP_POSTER}  (${TOP_TITLE})"
    fi
    echo "--- Contenido ---"
    echo "$BODY"
    echo "--- Destinatarios ---"
    echo "$RECIPIENTS"
    exit 0
fi

while IFS=$'\t' read -r chat_id name; do
    if [ -n "$TOP_POSTER" ]; then
        python3 -c "
import urllib.request, urllib.parse, sys
token = '${TELEGRAM_BOT_TOKEN}'
data = urllib.parse.urlencode({
    'chat_id': '$chat_id',
    'photo': f'https://image.tmdb.org/t/p/w500${TOP_POSTER}',
    'caption': 'Sugerencia de la semana: ${TOP_TITLE}'
}).encode()
req = urllib.request.Request(f'https://api.telegram.org/bot{token}/sendPhoto', data=data)
try:
    urllib.request.urlopen(req, timeout=15)
except Exception as e:
    print(f'Photo failed for $name: {e}', file=sys.stderr)
"
    fi
    python3 -c "
import urllib.request, urllib.parse, sys
token = '${TELEGRAM_BOT_TOKEN}'
chat_id = '$chat_id'
text = sys.stdin.read()
data = urllib.parse.urlencode({'chat_id': chat_id, 'text': text}).encode()
req = urllib.request.Request(f'https://api.telegram.org/bot{token}/sendMessage', data=data)
try:
    resp = urllib.request.urlopen(req, timeout=15)
    print(f'Sent to $name ($chat_id): {resp.status}')
except Exception as e:
    print(f'FAILED for $name ($chat_id): {e}', file=sys.stderr)
" <<< "$BODY"
done <<< "$RECIPIENTS"
