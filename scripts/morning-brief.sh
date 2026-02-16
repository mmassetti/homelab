#!/bin/bash
# Morning Brief — daily summary sent via Telegram at 8:00 AM
# Crontab: 0 8 * * * /home/matias/homelab/scripts/morning-brief.sh
#
# Sources:
#   Calendar: Google Calendar OAuth2 API (via gcal-today.py)
#   Dollar: dolarapi.com
#   Disk: df (NAS + Mini PC)
#   Infra: docker-quick.js via gateway container
#   Weather: wttr.in API
#   Tech/AI: TechCrunch RSS (weekdays)
#   Sports: Olé RSS (daily)
#   Argentina: La Nación RSS
#   Bahía Blanca: La Brújula 24 RSS

set -uo pipefail

FECHA=$(TZ="America/Argentina/Buenos_Aires" date '+%d/%m/%Y')
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
    curl -sL --max-time 15 "$url" 2>/dev/null \
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
add "☀️ Morning Brief — ${FECHA}"
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
    TECH=$(rss_titles "https://techcrunch.com/feed/" 3)
    if [ -n "$TECH" ]; then
        while IFS= read -r title; do
            title=$(echo "$title" | decode_html)
            add "• ${title}"
        done <<< "$TECH"
    else
        add "• No se pudieron obtener noticias tech"
    fi
fi

# --- 7. Sports (always) ---
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

add ""
# --- 8. Infra ---
INFRA=$(docker exec openclaw-gateway node /home/node/.openclaw/workspace/scripts/docker-quick.js 2>&1 || echo "⚠️ No se pudo chequear infra")
TOTAL=$(echo "$INFRA" | grep -oP 'Running: \K\d+' || echo "?")
DOWN_LIST=$(echo "$INFRA" | grep "^DOWN:" | grep -v "openclaw-cli" || true)

if [ -z "$DOWN_LIST" ]; then
    add "🖥 ✓ Infra OK (${TOTAL} containers running)"
else
    add "🖥 ⚠️ Infra: ${TOTAL} running"
    while IFS= read -r line; do
        add "  ${line}"
    done <<< "$DOWN_LIST"
fi

add ""
# --- 9. Disk ---
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

# --- Footer ---
add ""
add "Buen día, Mati! 🦞"

# --- Send via Telegram ---
docker exec openclaw-gateway node dist/index.js message send -t 959522546 -m "$BRIEF"
