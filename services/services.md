# Services

All services run on the mini PC (192.168.1.239) via Docker.
Main compose file: `/opt/docker/docker-compose.yml`
Config base: `/opt/docker/configs/<service>/`

## ARR Stack (Media Automation)

All ARR services use Hotio images, share `arr_network`, and use common env (PUID=1000, PGID=1000, TZ=America/Argentina/Buenos_Aires).

| Service | Container | Port | Image | Config | Volumes |
|---------|-----------|------|-------|--------|---------|
| Jellyfin | jellyfin | 8096 | ghcr.io/hotio/jellyfin | /opt/docker/configs/jellyfin | /mnt/nas/Peliculas, /mnt/nas/Series, /mnt/nas/Music |
| Radarr | radarr | 7878 | ghcr.io/hotio/radarr | /opt/docker/configs/radarr | /mnt/nas/downloads, /mnt/nas/Peliculas |
| Sonarr | sonarr | 8989 | ghcr.io/hotio/sonarr | /opt/docker/configs/sonarr | /mnt/nas/downloads, /mnt/nas/Series |
| Lidarr | lidarr | 8686 | ghcr.io/hotio/lidarr | /opt/docker/configs/lidarr | /mnt/nas/downloads, /mnt/nas/Music |
| Bazarr | bazarr | 6767 | ghcr.io/hotio/bazarr | /opt/docker/configs/bazarr | /mnt/nas/Series, /mnt/nas/Peliculas |
| qBittorrent | qbittorrent | 8080 (web), 6881 (torrent) | ghcr.io/hotio/qbittorrent | /opt/docker/configs/qbittorrent | /mnt/nas/downloads |
| Prowlarr | prowlarr | 9696 | ghcr.io/hotio/prowlarr | /opt/docker/configs/prowlarr | — |
| FlareSolverr | flaresolverr | 8191 | ghcr.io/flaresolverr/flaresolverr | — | — |
| Jellyseerr | jellyseerr | 5055 | fallenbagel/jellyseerr | /opt/docker/configs/jellyseerr | — |
| Profilarr | profilarr | 6868 | santiagosayshey/profilarr | /opt/docker/configs/profilarr | — |

### Media Flow

```
Jellyseerr (request) → Radarr/Sonarr (search via Prowlarr) → qBittorrent (download)
  → auto-rename/move to NAS → Bazarr (subtitles: Spanish + English) → Jellyfin (auto-scan)
```

### Jellyfin Customization (since 2026-08-09/10)

- **Custom CSS**: applied live via Dashboard → General → Branding → Custom CSS (no
  restart needed). Source kept at `~/homelab/scripts/jellyfin_custom.css` — rounder card
  corners, hover elevation, blurred translucent header, celeste (#75AADB) accent color.
- **Collections**: built via Jellyfin REST API (`/Collections`, `/Collections/{id}/Items`,
  `/Items/{id}/Images/Primary`), all read/write, no server restart required. Custom
  1000x1500 poster art generated locally with ImageMagick (gradient + text, no external
  images) for every collection listed below.
  - **Cine Argentino** (hub) — 1178 movies (filtered by `ProductionLocations` containing
    "Argentina"), nested into 12 decade subcollections (1910s–2020s).
  - **Sagas** (hub) — Harry Potter (9), Mission: Impossible (7), Piratas del Caribe (5).
  - **Cine del Mundo** (hub) — by `ProductionLocations`: Francia (226), Reino Unido (197),
    España (37), Alemania (17), Italia (18), Francia (56), Reino Unido (79), Japón (34),
    Latinoamérica ex-Argentina (22). Membership rule: a movie's country is its **first**
    entry in `ProductionLocations` (not "any of these countries appears in the list" —
    see fix below), refined further by a manual per-country review (see decisions log)
    since production-financing credits (esp. German/British co-production financing
    schemes) don't always match creative/cultural origin. Alemania, España, Italia,
    Francia, Reino Unido and Japón have been manually reviewed; Latinoamérica is the
    only one left.
  - **Standalone thematic collections** — Imprescindibles (rating ≥8.5, 60), Basadas en
    Libros (TMDB tag, 179), Basadas en Hechos Reales (TMDB tag, 63), Dirigidas por Mujeres
    (TMDB tag, 97), Terror (207), Documentales (262), Ciencia Ficción (119), Animación (28),
    Western (33), Musicales (88).
  - **Backdrops + descriptions** (2026-08-10): every one of the 35 collections (13 Cine
    Argentino, 4 Sagas, 8 Cine del Mundo, 10 thematic) also got a landscape backdrop
    (1920x1080, same gradient/palette as its poster, generated with ImageMagick) via
    `POST /Items/{id}/Images/Backdrop`, plus a short Spanish description via
    `POST /Items/{id}` (fetch full item from `/Users/{userId}/Items/{id}` first, set
    `Overview`, POST the full object back — a partial body resets other fields). Note:
    plain `GET /Items/{id}` without a user context 400s on this Jellyfin version; use the
    `/Users/{userId}/Items/{id}` route for reads.
  - **Country-collection filter bug fix** (2026-08-10): the 7 Cine del Mundo subcollections
    were originally built with "country appears anywhere in `ProductionLocations`", which
    badly over-included co-productions — e.g. Spain-Argentina arthouse co-productions (very
    common via Ibermedia funding) showed up in "España" even though they're really Argentine
    films, and multi-country films like *Il buono, il brutto, il cattivo* (Italy/Spain/
    Germany/USA co-production) showed up in "España" too. 63% of "España" (84/133) and 77%
    of "Latinoamérica" (75/97) were actually Argentine co-productions. Rebuilt using "country
    is the first entry in `ProductionLocations`" instead — a much stronger signal of actual
    country of origin. New counts above. When diffing old vs new membership via the API,
    note `GET /Items?ParentId={collectionId}` returns 0 items without a user context — must
    use `GET /Users/{userId}/Items?ParentId={collectionId}` or the removal step silently
    no-ops (this bit us on the first attempt: additions worked, removals didn't).
  - **Original-language titles** (2026-08-10): 441 Spanish-language movies (primary
    `ProductionLocations` = Argentina/Spain/Mexico/Uruguay/Chile) had their display `Name`
    switched from the English TMDB title to `OriginalTitle` (e.g. "Every Stewardess Goes to
    Heaven" → "Todas las azafatas van al cielo"), with `Name` added to `LockedFields` so it
    sticks. Gotcha: items with generated Trickplay data 500 on the `POST /Items/{id}`
    round-trip unless the `Trickplay` key is stripped from the body first (Jellyfin bug —
    its own GET response isn't valid input for its own POST).
  - **Known limitation**: Jellyfin's flat "Collections" library view does not hide BoxSets
    that are nested inside a parent collection — all decade/franchise/country subcollections
    also show up as ordinary top-level tiles. No native fix exists. Planned resolution:
    install `jellyfin-plugin-custom-javascript` to inject DOM-hiding JS for subcollection
    tiles on the root view only — **requires a container restart**, deferred until no
    active playback sessions (`GET /Sessions`) are found.

### Bazarr Notes

- `general.ignore_pgs_subs: true` (since 2026-08-09) — PGS (image-based) embedded subtitle
  tracks no longer count as satisfying a movie/series' language profile. Some BluRay REMUX
  releases embed both PGS and true-text (SubRip) tracks for the same language with identical
  labels in Jellyfin's subtitle picker (e.g. multiple "Spanish" entries), and picking the PGS
  one silently fails to render in Jellyfin's web/Mac client (no burn-in transcode happens on
  direct play). With this flag, Bazarr treats PGS-only releases as missing subtitles and
  downloads a proper external `.srt` instead of assuming the embedded PGS track is good enough.
- Language profile "Spanish Preferred" (profileId 1): requires Spanish (`es`), Spanish Latino
  (`ea`), and English (`en`).
- API key at `/opt/docker/configs/bazarr/config/config.yaml` → `auth.apikey` (also usable for
  `X-API-KEY` header against `http://localhost:6767/api/...`).

## DNS Stack (Pi-hole + Unbound)

Dedicated `dns_network` (172.30.0.0/24).

| Service | Container | Port | IP (dns_network) | Notes |
|---------|-----------|------|-------------------|-------|
| Unbound | unbound | 5335 (internal) | 172.30.0.2 | Recursive DNS resolver |
| Pi-hole | pihole | 53 (DNS), 8888 (web UI) | 172.30.0.3 | DNS sinkhole, upstream → Unbound |

Pi-hole is the DNS server for the entire network (containers use 192.168.1.239 as DNS).
Router should point DNS to 192.168.1.239 for whole-network ad blocking.

## Infrastructure

| Service | Container | Port | Network | Notes |
|---------|-----------|------|---------|-------|
| Cloudflare Tunnel | cloudflared | — | homelab | Exposes services to internet, no port forwarding needed |
| Homarr | homarr | 7575 | homelab | Dashboard, mounts docker.sock |
| Uptime Kuma | uptime-kuma | 3001 | homelab | Service monitoring |
| Glances | glances | — | host network | System monitoring (web: `-w` flag) |
| Netdata | netdata | 19999 | homelab | Advanced monitoring |

## Cloud & Storage

| Service | Container | Port | Network | Notes |
|---------|-----------|------|---------|-------|
| OpenCloud | opencloud | 9200 | homelab | Cloud storage, URL: cloud.matiasmassetti.com, data on NAS via /mnt/opencloud |
| Nextcloud | nextcloud | 8090 | homelab | Personal cloud, mounts /mnt/nas |
| Nextcloud DB | nextcloud-db | — (3306 internal) | homelab | MariaDB 10.11 |
| Image Server | image-server | 4010 | homelab | Static file server for /opt/images |

## OpenClaw (AI Agent)

Separate compose file: `/opt/docker/configs/openclaw/docker-compose.yml`
Dedicated `openclaw_network` (172.31.0.0/24), isolated from all other stacks.

| Service | Container | Port | Image | Config | Notes |
|---------|-----------|------|-------|--------|-------|
| OpenClaw Gateway | openclaw-gateway | 127.0.0.1:18789, 127.0.0.1:18790, 127.0.0.1:3333 | openclaw:local (built from source) | /opt/docker/configs/openclaw | AI agent with Telegram integration |
| Mission Control | openclaw-mission-control | 3333 (shared via network_mode) | openclaw:local | /opt/docker/configs/openclaw/workspace/mission-control | Web dashboard for agent management |

### Security Hardening
- **Ports**: Bound to `127.0.0.1` only — not accessible from LAN or internet
- **Filesystem**: `read_only: true` with `tmpfs: /tmp`
- **Capabilities**: `cap_drop: ALL`, `cap_add: NET_BIND_SERVICE`
- **Privileges**: `no-new-privileges: true`
- **Network**: Isolated `openclaw_network`, not connected to arr/dns/homelab networks
- **Sandbox**: Agent commands run in throwaway containers (`openclaw-sandbox-bookworm-slim`) with `network: none`
- **Telegram**: Outbound polling only, user ID allowlisted
- **Docker socket**: Mounted for sandbox spawning + container monitoring. `group_add: "987"` (docker GID) allows gateway process to query socket API
- **NOT exposed via Cloudflare Tunnel** — access Web UI via SSH tunnel only

### Bot Personality ("Claudito" 🦞)
- Workspace files fully personalized at `/opt/docker/configs/openclaw/workspace/`
- Files: IDENTITY.md, SOUL.md, USER.md, TOOLS.md, AGENTS.md, MEMORY.md, HEARTBEAT.md
- Monitoring scripts: `workspace/scripts/docker-status.js` (full report), `workspace/scripts/docker-quick.js` (summary)
- Spanish by default, English when addressed in English
- Model: OpenRouter `auto` (routes to cheapest adequate model)

### Installed ClaWHub Skills (workspace/skills/)
| Skill | Version | Purpose |
|-------|---------|---------|
| qmd | 1.0.0 | Local semantic search for markdown/docs (BM25 + vectors), reduces token usage |
| prompt-injection-guard | 1.0.0 | Prompt injection defense — detects and blocks malicious prompts |
| openclaw-mission-control | 1.0.0 | Skill manifest for Mission Control dashboard integration |
| morning-brief | — | Reference for daily morning brief cron job (management commands) |

ClaWHub CLI installed at: `workspace/.npm-global/bin/clawhub`
QMD binary installed at: `workspace/tools/qmd/` (npm local install with better-sqlite3 compiled)

### Morning Brief (Host Crontab)
| Job | Schedule | Delivery | Description |
|-----|----------|----------|-------------|
| Morning Brief | 8:00 AM daily | Telegram via `message send` | Weather, calendar, dollar, news, infra, disk |

Host crontab script: `~/homelab/scripts/morning-brief.sh`
Helper: `~/homelab/scripts/gcal-today.py` (Google Calendar OAuth2 API, Workspace account `matias@honeydewcare.com`)
Sources: wttr.in (weather), Google Calendar OAuth2 (agenda, weekdays), dolarapi.com (Blue/Oficial/MEP), La Brújula 24 RSS (local), La Nación RSS (national), TechCrunch RSS (tech/AI, weekdays), Olé RSS (sports, daily), docker-quick.js (infra), df (disk)
Weekend mode: No calendar, no tech/AI section
Secrets: `~/.config/secrets/gcal_oauth.json` (OAuth2 client_id, client_secret, refresh_token — perms 600)
Log: `/tmp/morning-brief.log`

### Ongoing Maintenance
- **ClaWHub skills**: Allowed with audit — always inspect skills before installing, watch for VirusTotal flags. VAN-210 (hidden npm script attack) is partially mitigated by `--ignore-scripts` default.
- **Never install VS Code extensions** for OpenClaw — fake extensions distribute malware
- **To update**: `cd /opt/docker/configs/openclaw/source && git pull`, rebuild image, restart — **never re-run `docker-setup.sh`** (overwrites security config)
- **Check logs periodically**: `docker logs openclaw-gateway --tail 50`
- **Mission Control logs**: `docker logs openclaw-mission-control --tail 50`

### Access
- **Primary**: Telegram bot (`@clauditomassetti_bot`)
- **Web UI**: `ssh -L 18789:127.0.0.1:18789 matias@192.168.1.239` then open `http://127.0.0.1:18789`
- **Mission Control**: `ssh -L 3333:127.0.0.1:3333 matias@192.168.1.239` then open `http://127.0.0.1:3333`

## Project Containers (Separate Compose Files)

| Service | Container | Port | Compose File | Notes |
|---------|-----------|------|--------------|-------|
| USA 2026 | usa2026 | 3000 | ~/Code/usa-2026/docker-compose.yml | FIFA World Cup trip planner |
| CEN Dashboard | cen-dashboard-cen-dashboard-1 | 3003 | ~/Code/cen-dashboard/docker-compose.yml | Dashboard app |
| Media Tracker DB | media_tracker_db | 5432 | ~/media-tracker-db/docker-compose.yml | PostgreSQL 16 |
| Scraper Autoentrada | — | — | ~/Code/scraper-autoentrada/docker-compose.yml | Ticket scraper bot |
| Reporte Minoritario | — | — | ~/Code/reporteminoritario-transcript-fetcher/docker-compose.yml | Podcast transcript AI |

## Docker Networks

| Network | Subnet | Purpose |
|---------|--------|---------|
| arr_network | (bridge, auto) | ARR stack services |
| docker_homelab | (bridge, auto) | Infrastructure + cloud services |
| dns_network | 172.30.0.0/24 | Pi-hole + Unbound |
| media_tracker_network | 172.21.0.0/16 | Media tracker project |
| openclaw_network | 172.31.0.0/24 | OpenClaw AI agent (isolated) |

## Docker Named Volumes

- `nextcloud-db` — MariaDB data for Nextcloud
- `nextcloud-app` — Nextcloud application data
