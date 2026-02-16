#!/bin/bash
# Morning Brief — daily summary sent via Telegram at 8:00 AM
# Crontab: 0 8 * * * /home/matias/homelab/scripts/morning-brief.sh
#
# Sources:
#   Infra: docker-quick.js via gateway container
#   Weather: wttr.in API
#   Tech/AI: TechCrunch RSS
#   Argentina: La Nación RSS
#   Bahía Blanca: La Brújula 24 RSS

set -uo pipefail

FECHA=$(TZ="America/Argentina/Buenos_Aires" date '+%d/%m/%Y')
BRIEF=""

add() { BRIEF="${BRIEF}${1}"$'\n'; }

# --- Helper: extract N article titles from RSS feed ---
# Handles both CDATA and plain <title> formats.
# Uses sed to isolate <item> blocks, then extracts titles.
rss_titles() {
    local url="$1" count="$2"
    curl -sL --max-time 15 "$url" 2>/dev/null \
        | sed -n '/<item>/,/<\/item>/p' \
        | grep -oP '<title>(<!\[CDATA\[)?\K[^]<]+' \
        | grep -vxF "LA NACION" \
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

# --- 2. Bahía Blanca ---
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

# --- 3. Argentina ---
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

# --- 4. Tech/AI ---
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

# --- 5. Infra ---
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

# --- Footer ---
add ""
add "Buen día, Mati! 🦞"

# --- Send via Telegram ---
docker exec openclaw-gateway node dist/index.js message send -t 959522546 -m "$BRIEF"
