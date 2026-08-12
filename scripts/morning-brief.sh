#!/bin/bash
# Resumen Matutino — daily summary sent via Telegram at 8:00 AM Argentina time
# Crontab: 0 11 * * * /home/matias/homelab/scripts/morning-brief.sh >> /tmp/morning-brief.log 2>&1
# (11:00 UTC = 8:00 AM America/Argentina/Buenos_Aires)
#
# Sources:
#   Calendar: Google Calendar OAuth2 API (via gcal-today.py)
#   Dollar: dolarapi.com
#   Disk: df (NAS + Mini PC)
#   Infra: docker ps (host, no agent dependency)
#   Weather: wttr.in API
#   Tech/AI: WWWhat's New RSS, Spanish-language (weekdays)
#   Sports (news): Olé RSS (daily)
#   Sports (matches): promiedos.com.ar embedded JSON, TV-broadcast games only
#   Twitter/X trends: trends24.in (Buenos Aires), scraped HTML — no official API
#   Argentina: La Nación RSS
#   Bahía Blanca: La Brújula 24 RSS
#   Jellyseerr: pending requests via its own API
#   Downloads: Radarr/Sonarr history, last 24h imports
#
# Secrets (Telegram bot token/chat id, Radarr/Sonarr/Jellyseerr API keys) live in
# ~/.config/secrets/morning_brief.env — NOT committed, this script is pushed to GitHub.

set -uo pipefail

SECRETS="/home/matias/.config/secrets/morning_brief.env"
if [ -f "$SECRETS" ]; then
    set -a
    source "$SECRETS"
    set +a
else
    echo "Missing $SECRETS — cannot send Telegram message, aborting." >&2
    exit 1
fi

FECHA=$(TZ="America/Argentina/Buenos_Aires" date '+%d/%m/%Y')
FECHA_DASH=$(TZ="America/Argentina/Buenos_Aires" date '+%d-%m-%Y')
DOW=$(TZ="America/Argentina/Buenos_Aires" date '+%u')  # 1=Mon, 7=Sun
WEEKEND=false
[ "$DOW" -ge 6 ] && WEEKEND=true
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GCAL_OAUTH="/home/matias/.config/secrets/gcal_oauth.json"
BRIEF=""

add() { BRIEF="${BRIEF}${1}"$'\n'; }

# --- Helper: extract N article titles from RSS feed ---
rss_titles() {
    local url="$1" count="$2"
    curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" --max-time 15 "$url" 2>/dev/null \
        | sed -n '/<item>/,/<\/item>/p' \
        | grep -oP '<title>(<!\[CDATA\[)?\K[^]<]+' \
        | grep -vxE "LA NACION|www\..*" \
        | head -n "$count" || true
}

# --- Helper: decode common HTML entities ---
decode_html() {
    sed "s/&#8217;/'/g; s/&#8216;/'/g; s/&#8220;/\"/g; s/&#8221;/\"/g; s/&amp;/\&/g; s/&#039;/'/g; s/&quot;/\"/g"
}

# --- Header ---
add "☀️ Resumen Matutino — ${FECHA}"
add ""

# --- 1. Weather ---
WEATHER=$(curl -s --max-time 15 "wttr.in/Bahia+Blanca?format=%t+%C&lang=es" 2>/dev/null || echo "N/A")
add "🌡 Bahía Blanca: ${WEATHER}"

# --- 2. Calendar (weekdays only) ---
if [ "$WEEKEND" = false ] && [ -f "$GCAL_OAUTH" ]; then
    EVENTS=$(python3 "$SCRIPT_DIR/gcal-today.py" "$GCAL_OAUTH" 2>/dev/null || true)
    if [ -n "$EVENTS" ]; then
        add ""
        add "📅 Agenda"
        while IFS= read -r event; do
            add "• ${event}"
        done <<< "$EVENTS"
    fi
fi

# --- 3. Dollar ---
DOLAR_JSON=$(curl -s --max-time 10 "https://dolarapi.com/v1/dolares" 2>/dev/null || true)
if [ -n "$DOLAR_JSON" ]; then
    BLUE=$(echo "$DOLAR_JSON" | python3 -c "import sys,json; d=next(x for x in json.load(sys.stdin) if x['casa']=='blue'); print(f'Blue \${d[\"venta\"]}')" 2>/dev/null || echo "N/A")
    OFICIAL=$(echo "$DOLAR_JSON" | python3 -c "import sys,json; d=next(x for x in json.load(sys.stdin) if x['casa']=='oficial'); print(f'Oficial \${d[\"venta\"]}')" 2>/dev/null || echo "N/A")
    MEP=$(echo "$DOLAR_JSON" | python3 -c "import sys,json; d=next(x for x in json.load(sys.stdin) if x['casa']=='bolsa'); print(f'MEP \${d[\"venta\"]}')" 2>/dev/null || echo "N/A")
    add "💵 ${BLUE} | ${OFICIAL} | ${MEP}"
fi

# --- 4. Bahía Blanca ---
add ""
add "📍 Bahía Blanca"
LOCAL=$(rss_titles "https://www.labrujula24.com/feed/" 3)
if [ -n "$LOCAL" ]; then
    while IFS= read -r title; do
        title=$(echo "$title" | decode_html)
        add "• ${title}"
    done <<< "$LOCAL"
else
    add "• No se pudieron obtener noticias locales"
fi

# --- 5. Argentina ---
add ""
add "🇦🇷 Argentina"
ARG=$(rss_titles "https://www.lanacion.com.ar/arcio/rss/" 3)
if [ -n "$ARG" ]; then
    while IFS= read -r title; do
        title=$(echo "$title" | decode_html)
        add "• ${title}"
    done <<< "$ARG"
else
    add "• No se pudieron obtener noticias nacionales"
fi

# --- 6. Tech/AI (weekdays only) ---
if [ "$WEEKEND" = false ]; then
    add ""
    add "🤖 Tech / AI"
    TECH=$(rss_titles "https://wwwhatsnew.com/feed/" 3)
    if [ -n "$TECH" ]; then
        while IFS= read -r title; do
            title=$(echo "$title" | decode_html)
            add "• ${title}"
        done <<< "$TECH"
    else
        add "• No se pudieron obtener noticias tech"
    fi
fi

# --- 7. Sports news ---
add ""
add "⚽ Deportes"
SPORTS=$(rss_titles "https://www.ole.com.ar/rss/ultimas-noticias/" 3)
if [ -n "$SPORTS" ]; then
    while IFS= read -r title; do
        title=$(echo "$title" | decode_html)
        add "• ${title}"
    done <<< "$SPORTS"
else
    add "• No se pudieron obtener noticias deportivas"
fi

# --- 7b. Twitter/X trending topics (Buenos Aires) ---
TRENDS=$(curl -sL -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" --max-time 15 "https://trends24.in/argentina/buenos-aires/" 2>/dev/null | python3 -c "
import sys, re, html
content = sys.stdin.read()
m = re.search(r'<ol class=trend-card__list>(.*?)</ol>', content, re.S)
if not m:
    sys.exit(0)
names = re.findall(r'class=trend-link[^>]*>([^<]+)</a>', m.group(1))
for name in names[:8]:
    print(html.unescape(name))
" 2>/dev/null || true)
if [ -n "$TRENDS" ]; then
    add ""
    add "🐦 Tendencias en X (Buenos Aires)"
    add "$(echo "$TRENDS" | paste -sd, - | sed 's/,/, /g')"
fi

# --- 8. Today's TV matches (Promiedos) ---
MATCHES=$(curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" --max-time 15 "https://www.promiedos.com.ar/" 2>/dev/null | python3 -c "
import sys, re, json
html = sys.stdin.read()
m = re.search(r'<script id=\"__NEXT_DATA__\"[^>]*>(.*?)</script>', html, re.S)
if not m:
    sys.exit(0)
try:
    data = json.loads(m.group(1))
    leagues = data['props']['pageProps']['data']['leagues']
except Exception:
    sys.exit(0)
today = '${FECHA_DASH}'
lines = []
for league in leagues:
    for g in league.get('games', []):
        tv = g.get('tv_networks') or []
        if not tv:
            continue
        start = g.get('start_time', '')
        if not start.startswith(today):
            continue
        time_part = start.split(' ')[-1]
        teams = g.get('teams', [])
        if len(teams) != 2:
            continue
        t1, t2 = teams[0]['short_name'], teams[1]['short_name']
        tv_names = ', '.join(x['name'] for x in tv[:2])
        lines.append(f'{time_part} {t1} vs {t2} ({tv_names}) — {league[\"name\"]}')
for line in lines[:6]:
    print(line)
" 2>/dev/null || true)
if [ -n "$MATCHES" ]; then
    add ""
    add "📺 Partidos de hoy"
    while IFS= read -r line; do
        add "• ${line}"
    done <<< "$MATCHES"
fi

add ""
# --- 9. Infra ---
INFRA_TOTAL=$(docker ps --format '{{.Names}}' 2>/dev/null | wc -l)
INFRA_DOWN=$(docker ps -a --filter "status=exited" --format '{{.Names}}' 2>/dev/null || true)
if [ -z "$INFRA_DOWN" ]; then
    add "🖥 ✓ Infra OK (${INFRA_TOTAL} containers running)"
else
    add "🖥 ⚠️ Infra: ${INFRA_TOTAL} running, caídos:"
    while IFS= read -r line; do
        add "  ${line}"
    done <<< "$INFRA_DOWN"
fi

# --- 10. Disk ---
NAS_USE=$(df /mnt/nas --output=pcent,avail 2>/dev/null | tail -1 | xargs || true)
MINIPC_USE=$(df / --output=pcent,avail 2>/dev/null | tail -1 | xargs || true)
if [ -n "$NAS_USE" ] && [ -n "$MINIPC_USE" ]; then
    NAS_PCT=$(echo "$NAS_USE" | awk '{print $1}')
    NAS_FREE=$(echo "$NAS_USE" | awk '{print $2}')
    MINIPC_PCT=$(echo "$MINIPC_USE" | awk '{print $1}')
    MINIPC_FREE=$(echo "$MINIPC_USE" | awk '{print $2}')
    NAS_FREE_H=$(numfmt --from=iec --to=iec "${NAS_FREE}K" 2>/dev/null || echo "${NAS_FREE}")
    MINIPC_FREE_H=$(numfmt --from=iec --to=iec "${MINIPC_FREE}K" 2>/dev/null || echo "${MINIPC_FREE}")
    DISK_LINE="💾 NAS ${NAS_PCT} (${NAS_FREE_H} libre) | Mini PC ${MINIPC_PCT} (${MINIPC_FREE_H} libre)"
    NAS_NUM=${NAS_PCT//%/}
    MINIPC_NUM=${MINIPC_PCT//%/}
    if [ "$NAS_NUM" -gt 90 ] 2>/dev/null || [ "$MINIPC_NUM" -gt 90 ] 2>/dev/null; then
        DISK_LINE="💾 ⚠️ NAS ${NAS_PCT} (${NAS_FREE_H} libre) | Mini PC ${MINIPC_PCT} (${MINIPC_FREE_H} libre)"
    fi
    add "$DISK_LINE"
fi

# --- 11. Jellyseerr pending requests ---
PENDING=$(curl -s --max-time 10 "http://localhost:5055/api/v1/request?filter=pending&take=10" -H "X-Api-Key: ${JELLYSEERR_API_KEY}" 2>/dev/null | python3 -c "
import sys, json, urllib.request
d = json.load(sys.stdin)
results = d.get('results', [])
if not results:
    sys.exit(0)
print(f\"{d['pageInfo']['results']} pedido(s) esperando aprobación\")
for r in results[:5]:
    media = r.get('media', {})
    mtype = media.get('mediaType')
    tmdb = media.get('tmdbId')
    who = r.get('requestedBy', {}).get('displayName', '?')
    title = f'{mtype} {tmdb}'
    try:
        req = urllib.request.Request(f'http://localhost:5055/api/v1/{mtype}/{tmdb}', headers={'X-Api-Key': '${JELLYSEERR_API_KEY}'})
        info = json.loads(urllib.request.urlopen(req, timeout=5).read())
        title = info.get('title') or info.get('name') or title
    except Exception:
        pass
    print(f'{title} (pedido por {who})')
" 2>/dev/null || true)
if [ -n "$PENDING" ]; then
    add ""
    add "🎬 Jellyseerr"
    first=true
    while IFS= read -r line; do
        if [ "$first" = true ]; then
            add "• ${line}"
            first=false
        else
            add "  - ${line}"
        fi
    done <<< "$PENDING"
fi

# --- 12. What got downloaded in the last 24h ---
DOWNLOADS=$(python3 -c "
import urllib.request, json
from datetime import datetime, timedelta, timezone

cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
lines = []

def fetch(url, key):
    req = urllib.request.Request(url, headers={'X-Api-Key': key})
    return json.loads(urllib.request.urlopen(req, timeout=10).read())

try:
    d = fetch('http://localhost:7878/api/v3/history?page=1&pageSize=50&sortKey=date&sortDirection=descending&eventType=3&includeMovie=true', '${RADARR_API_KEY}')
    for r in d.get('records', []):
        dt = datetime.fromisoformat(r['date'].replace('Z', '+00:00'))
        if dt < cutoff:
            break
        title = r.get('movie', {}).get('title', r.get('sourceTitle', '?'))
        lines.append(f'🎬 {title}')
except Exception:
    pass

try:
    d = fetch('http://localhost:8989/api/v3/history?page=1&pageSize=50&sortKey=date&sortDirection=descending&eventType=3&includeSeries=true&includeEpisode=true', '${SONARR_API_KEY}')
    for r in d.get('records', []):
        dt = datetime.fromisoformat(r['date'].replace('Z', '+00:00'))
        if dt < cutoff:
            break
        s = r.get('series', {}).get('title', '?')
        e = r.get('episode', {})
        lines.append(f\"📺 {s} S{e.get('seasonNumber',0):02d}E{e.get('episodeNumber',0):02d}\")
except Exception:
    pass

for line in lines[:8]:
    print(line)
" 2>/dev/null || true)
if [ -n "$DOWNLOADS" ]; then
    add ""
    add "⬇️ Se bajó en las últimas 24hs"
    while IFS= read -r line; do
        add "• ${line}"
    done <<< "$DOWNLOADS"
fi

# --- Footer ---
add ""
add "Buen día, Mati!"

# --- Send via Telegram (direct Bot API, no OpenClaw dependency) ---
python3 -c "
import urllib.request, urllib.parse, json, sys
token = '${TELEGRAM_BOT_TOKEN}'
chat_id = '${TELEGRAM_CHAT_ID}'
text = sys.stdin.read()
data = urllib.parse.urlencode({'chat_id': chat_id, 'text': text}).encode()
req = urllib.request.Request(f'https://api.telegram.org/bot{token}/sendMessage', data=data)
try:
    resp = urllib.request.urlopen(req, timeout=15)
    print('Telegram send OK:', resp.status)
except Exception as e:
    print('Telegram send FAILED:', e, file=sys.stderr)
    sys.exit(1)
" <<< "$BRIEF"
