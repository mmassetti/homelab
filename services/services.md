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
| slskd | slskd | 5030 (web), 50300 (P2P listen) | slskd/slskd | /opt/docker/configs/slskd | /mnt/nas/downloads/soulseek/{complete,incomplete} — Soulseek P2P client, added 2026-08-16. Not a hotio image (own env/config conventions), joined to `arr_network` manually. `shares.directories` deliberately empty — download-only, doesn't share the local library back to the network. Credentials (Soulseek account + web UI + API key) in `~/.config/secrets/slskd.env`, not committed. |
| Soularr | soularr | 8265 (web UI) | mrusse08/soularr | /opt/docker/configs/soularr | /mnt/nas/downloads/soulseek/complete — bridges Lidarr's wanted list to slskd (searches, grabs, tells Lidarr to import), added 2026-08-16. Polls every 300s. Config (incl. both API keys) in `/opt/docker/configs/soularr/config.ini`. |
| Bazarr | bazarr | 6767 | ghcr.io/hotio/bazarr | /opt/docker/configs/bazarr | /mnt/nas/Series, /mnt/nas/Peliculas |
| Subgen | subgen | 9000 | mccloud/subgen:cpu | /opt/docker/configs/subgen/models | — (Whisper ASR provider for Bazarr, CPU-only) |
| Jellystat | jellystat + jellystat-db | 3002 | cyfershepard/jellystat + postgres:18.1 | /opt/docker/configs/jellystat/{postgres-data,backup-data} | — (Jellyfin stats dashboard) |
| qBittorrent | qbittorrent | 8080 (web), 6881 (torrent) | ghcr.io/hotio/qbittorrent | /opt/docker/configs/qbittorrent | /mnt/nas/downloads |
| Prowlarr | prowlarr | 9696 | ghcr.io/hotio/prowlarr | /opt/docker/configs/prowlarr | — |
| FlareSolverr | flaresolverr | 8191 | ghcr.io/flaresolverr/flaresolverr | — | — |
| Jellyseerr | jellyseerr | 5055 | ghcr.io/seerr-team/seerr (3.4.1) | /opt/docker/configs/jellyseerr | Migrated from `fallenbagel/jellyseerr` 2026-08-12, see decision log. `init: true` is required in compose — the image no longer provides its own init process |
| Profilarr | profilarr | 6868 | santiagosayshey/profilarr | /opt/docker/configs/profilarr | — |
| SABnzbd | sabnzbd | 8085 | ghcr.io/hotio/sabnzbd | /opt/docker/configs/sabnzbd | /mnt/nas/downloads (Usenet client, added since last audit — alt. to qBittorrent) |

### Media Flow

```
Jellyseerr (request) → Radarr/Sonarr (search via Prowlarr) → qBittorrent/SABnzbd (download)
  → auto-rename/move to NAS → Bazarr (subtitles: Spanish + English) → Jellyfin (auto-scan)
```

### Radarr/Sonarr Notes

- **Quality profile setup is a full TRaSH Guides/Recyclarr template** — 20+ pre-built profiles,
  240+ custom formats. Jellyseerr's default profile for new requests (both Radarr and Sonarr)
  is **"2160p Efficient"** (switched from "2160p Remux" 2026-08-12 — see decision log; remux
  was 88% of the tracked library and the main driver of the NAS running low on space).
- **Usenet vs. torrent**: both `qBittorrent` (torrent) and `SABnzbd` (usenet, via `NZBgeek`)
  are enabled download clients/indexers, alongside 3 torrent indexers (`1337x`, `Nyaa.si`,
  `YTS`). Checked 2026-08-12: Radarr's Delay Profile already has `preferredProtocol: usenet`
  with both delays at 0 (no artificial wait, but usenet wins ties) — this was already correctly
  configured, nothing needed changing. In practice usenet availability is limited by having
  only one usenet indexer vs. three torrent ones, especially for older/rarer titles.
- **Stalled/dead torrent recovery**: if a queued download shows `"errorMessage": "stalled with
  no connections"`, check `GET /api/v3/release?movieId={id}` sorted by `seeders` — Radarr's
  quality-format rejections (e.g., "Banned Groups") can hide perfectly healthy, high-seeder
  releases from automatic grabs. `DELETE /api/v3/queue/{id}?removeFromClient=true&blocklist=
  true&skipRedownload=false` clears the dead one; a manual `POST /api/v3/release` with that
  release's `guid`+`indexerId` force-grabs a specific rejected release if there's a good reason
  to override the filter (e.g., a healthy YIFY release when nothing else has real seeders).

### Hardware Transcoding (fixed 2026-08-12)

- Host has an AMD Radeon 780M iGPU (Phoenix3, VCN video engine) exposing `/dev/dri/card1` +
  `/dev/dri/renderD128` (owned by host group `render`, gid 993). Jellyfin's own encoding config
  was already set to VAAPI (`HardwareAccelerationType: vaapi`, `VaapiDevice:
  /dev/dri/renderD128`) but the `jellyfin` service in `/opt/docker/docker-compose.yml` never
  had the device passed through — every real video transcode (not just audio remux) was
  silently failing (`FFmpeg exited with code 237`) and presumably falling back to CPU-only
  software encoding, or failing outright on heavy 4K/HDR content.
- Fixed by adding to the `jellyfin` service:
  ```yaml
  devices:
    - /dev/dri:/dev/dri
  group_add:
    - "993"   # host render group, owns /dev/dri/renderD128
  ```
- Verified with a direct `ffmpeg -hwaccel vaapi` re-encode of a 2160p HDR HEVC title inside the
  container: 1.32x realtime speed, zero errors. See decision log for full investigation
  (Playback Reporting showed ~13 real video-transcode sessions in the last 30 days that would
  have been hitting this).

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
    Latinoamérica ex-Argentina (15). Membership rule: a movie's country is its **first**
    entry in `ProductionLocations` (not "any of these countries appears in the list" —
    see fix below), refined further by a full manual per-country review (see decisions
    log) since production-financing credits (esp. German/British co-production financing
    schemes) don't always match creative/cultural origin. All 7 subcollections have now
    been manually reviewed — 256 movies total, down from 761 after the original
    "primary country" fix.
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
  - **Plugins installed** (2026-08-10, required one Jellyfin container restart — done only
    after confirming zero active sessions): **JavaScript Injector** (n00bcodr fork of the
    unmaintained johnpc plugin) injects a script that hides the 22 nested subcollection tiles
    (Cine Argentino decades, Sagas, Cine del Mundo countries) from the flat Collections grid,
    while still showing them inside their parent hub's detail page — script source lives in
    the plugin's own config (`Jellyfin.Plugin.JavaScriptInjector.xml`), logic: hide by ID
    everywhere except when `location.hash` contains `/details` for one of the 3 parent hub
    IDs. Also installed **Jellyfin Enhanced** (shortcuts, ratings, hidden-content management,
    Jellyseerr integration) from the same repo. Repo URL:
    `https://raw.githubusercontent.com/n00bcodr/jellyfin-plugins/main/10.11/manifest.json`.
    Enabled its rating badges (`ShowUserRatingOnPosters`, `RatingTagsEnabled`,
    `ColoredRatingsEnabled` — colored rating tag bottom-right + rating shown on the poster
    itself) via `POST /Plugins/{id}/Configuration`, live, no restart. Quality tags
    (resolution/source/codec badges) and genre/language tags exist in the same plugin but
    weren't turned on.
  - **TMDb Box Sets** (pre-existing plugin, not installed by us): auto-creates un-curated
    native collections from TMDB franchise data every 24h. Its scheduled task
    (`TMDbBoxSetsRefreshLibraryTask`) had its trigger cleared (empty `Triggers` array) so it
    won't auto-run again. The 44 collections it had already generated were audited and
    curated: 10 deleted (4 empty, 3 single-movie, 3 duplicating the Sagas hub), 34 kept and
    nested into **Sagas** (29 already had TMDB art, 5 Argentine series got custom posters) —
    Sagas hub is now 37 subcollections total, all hidden from the flat view like the rest.
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
- Already-enabled providers (as of 2026-08-12) cover Latino/Argentina sources well:
  `opensubtitlescom`, `embeddedsubtitles`, `subdl`, `tvsubtitles`, `yifysubtitles`, `wizdom`,
  `subtis`, `subdivx`, `subtitulamostv`.
- **Whisper AI provider (`whisperai`), added 2026-08-12**: backed by the `subgen` container
  (`mccloud/subgen:cpu`, image handles Whisper-ASR-webservice-compatible HTTP calls from
  Bazarr — no path mapping or webhooks needed for this mode). Config:
  `whisperai.endpoint: http://subgen:9000` (Docker network hostname, not `127.0.0.1` —
  Bazarr and subgen are different containers). Model `medium`, CPU-only (no NVIDIA GPU on
  this host; the AMD iGPU used for Jellyfin transcoding doesn't accelerate Whisper).
  `PROCESS_ADDED_MEDIA`/`PROCESS_MEDIA_ON_PLAY` left `False` — subgen only runs when Bazarr
  calls it as a provider, not on its own webhook triggers.
  **Known limitation**: Whisper's `translate` task only outputs **English**, never Spanish or
  any other target language — it's transcribe-in-original-language or translate-to-English,
  full stop. So this provider only helps for (a) Spanish/other-language audio missing a
  same-language subtitle, or (b) English audio missing an English subtitle. It does **not**
  solve the more common case of English-audio movies needing a Spanish subtitle. Verified
  working via a live provider search on "Mercano, el marciano" (Spanish-language Argentine
  film): Bazarr returned a `whisperai` candidate labeled "transcribe Spanish audio -> Spanish
  SRT".

### Jellystat (added 2026-08-12)

- `cyfershepard/jellystat` + a dedicated `postgres:18.1` container (`jellystat-db`), both on
  `arr_network`. Jellystat connects to Jellyfin as `http://jellyfin:8096` (Docker network
  hostname) using the same `JELLYFIN_API_KEY` as other tools.
- Web UI on port 3002 (`http://192.168.1.239:3002` / Tailscale `http://100.112.136.118:3002`).
  Credentials in `/home/matias/.config/secrets/jellystat.env`. Postgres password and JWT secret
  generated with `openssl rand`, stored directly in `/opt/docker/docker-compose.yml`
  (consistent with how `pihole`/`opencloud`/`cloudflared` already handle secrets in that file —
  it lives outside the git repo).
- Setup was fully scripted via Jellystat's own API (no browser needed): `POST /auth/createuser`
  for the admin account, then `POST /auth/configSetup` with `JF_HOST`/`JF_API_KEY`. Its Swagger
  schema isn't served at the usual `/swagger.json` path (that 404s to the SPA) — the real one
  is baked into the image at `/app/backend/swagger.json`, readable via `docker exec`.
- **Not exposed via Cloudflare Tunnel/Access** — hit an "Authentication error" reading DNS
  records for the zone with the existing Cloudflare API token (it can edit the tunnel and list
  zones, but not read/write DNS records for this zone specifically — scope mismatch not yet
  diagnosed). Matias opted to leave it local/Tailscale-only for now rather than debug the token;
  revisit if he wants it public later.
- **Login bug fixed same day**: the frontend hashes the password with SHA3 client-side before
  sending it to `/auth/login`, but `/auth/createuser` and `/api/updatePassword` store whatever
  they're sent verbatim (no hashing). Any password set via those API endpoints directly (as
  opposed to through Jellystat's own web UI forms) will silently never work. Fixed by writing
  the correct `SHA3(password)` value straight into `app_config.APP_PASSWORD` via `psql`. Always
  change the Jellystat password through its own UI going forward, or replicate the SHA3 hash
  manually if scripting it.
- **Historical data imported**: by default Jellystat starts empty and only captures activity
  going forward via its Jellyfin websocket connection — it does *not* backfill automatically.
  Triggered the backfill manually: `GET /sync/syncPlaybackPluginData` (JWT-authenticated, not
  listed in the served `/swagger.json` — found by reading `routes/sync.js` directly) pulls in
  everything from Jellyfin's Playback Reporting plugin. Took the activity table from 1 row to
  860, covering 2025-10-26 through today.

### Notifications (added 2026-08-11)

- **Radarr + Sonarr**: Telegram connection ("Telegram - Claudito") added via each app's `/api/v3/notification` REST endpoint (schema fetched from `/api/v3/notification/schema` first — event flags differ: Radarr uses `onMovie*`, Sonarr uses `onSeries*`/`onEpisode*`). Both fire on Grab, Download, Upgrade, Health Issue, Health Restored, Manual Interaction Required, to the admin's Telegram chat.
- **Jellyfin**: official **Webhook** plugin (GUID `71552a5a5c5c4350a2aeebe451a30173`, v18.0.0.0, installed via `/Packages/Installed/Webhook` + container restart) with one Generic destination whose `WebhookUri` points straight at the Telegram Bot API `sendMessage` endpoint. `Content-Type: application/json` header set explicitly; body is a Handlebars template (stored **base64-encoded** in the plugin config's `Template` field — that's the plugin's own convention, not an obfuscation choice) rendering `{{NotificationUsername}}`, `{{Name}}`, `{{SeriesName}}`. Fires on `PlaybackStart` only, for Movies/Episodes/Songs. Plugin config lives at `/opt/docker/configs/jellyfin/data/plugins/configurations/Jellyfin.Plugin.Webhook.xml` — edit via the `/Plugins/{id}/Configuration` API, not the file directly (it's read on startup, not watched).
- **Jellyseerr**: admin-level Telegram notifications under Settings → Notifications → Telegram (Bot Token + admin Chat ID, events: Pending Approval/Approved/Declined/Available/Issue Reported). Per-user notifications are separate — each user either self-serves via their own Profile → Settings → Notifications → Telegram (needs their own Chat ID, obtained by DMing the bot and reading `getUpdates`, or via a helper bot like `@userinfobot`), or the admin pastes a user's Chat ID into Settings → Users → [user] → Notifications on their behalf.
- Bot: `@masa_server_bot`. **Secrets (bot token, API keys) deliberately not written into this repo** — it has a GitHub remote (`origin` → `mmassetti/homelab`), so anything committed here should be treated as effectively public. Look them up live: Radarr/Sonarr API keys in `/opt/docker/configs/{radarr,sonarr}/config.xml`, Jellyfin API key under Dashboard → Advanced → API Keys, Telegram bot token via @BotFather (`/mybots`) if it needs to be regenerated.

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
| Cloudflare Tunnel | cloudflared | — | homelab | Exposes services to internet, no port forwarding needed. Token-based (`tunnel --token`) — ingress routing is in the Cloudflare Zero Trust dashboard, not a local file |
| Homepage | homepage | 3000 | homelab | Dashboard — **replaced Homarr** (removed from stack entirely; not even a stopped container remains) |
| Uptime Kuma | uptime-kuma | 3001 | homelab | Service monitoring |
| Glances | glances | — | host network | System monitoring (web: `-w` flag) |
| Netdata | netdata | 19999 | homelab | Advanced monitoring |
| Cinemateca | cinemateca | 8001 | homelab | Personal movie catalog/enricher — Letterboxd (`matimassetti`) + Jellyfin + TMDB director data, reads `/mnt/nas/Peliculas:ro`, writes to `cinemateca` DB inside the `media_tracker_db` Postgres instance. Built from `~/Code/tracker-nas/webapp` (private GitHub repo `mmassetti/tracker-nas`) — a multi-stage Dockerfile builds the React frontend and FastAPI serves it via `StaticFiles` at `/`, same origin as the `/api/*` routes. `env_file` still points at `/opt/docker/configs/cinemateca/.env` (secrets weren't moved). Old build path (`/opt/docker/configs/cinemateca` as the Docker build context) is superseded but the directory/`.env` are still there. |

## Cloud & Storage

| Service | Container | Port | Network | Notes |
|---------|-----------|------|---------|-------|
| OpenCloud | opencloud | 9200 | homelab | Cloud storage, URL: cloud.matiasmassetti.com, data on NAS via /mnt/opencloud |
| Image Server | image-server | 4010 | homelab | Static file server for /opt/images |

**Nextcloud decommissioned** — `nextcloud` and `nextcloud-db` containers, and their entries in `/opt/docker/docker-compose.yml`, no longer exist. The `nextcloud-db`/`nextcloud-app` named volumes below may be orphaned leftovers; check with `docker volume ls` / `docker system df -v` before assuming they're safe to prune, in case anything was never migrated off them.

## Documentation — LeafWiki — TRIED AND DROPPED (2026-08-15)

Trialed as a possible complement to plain `~/homelab` markdown+git (search/backlinks over the
docs). **Verdict: dropped the same day.** Its Markdown import is web-UI-only (drag/drop a ZIP,
no API), and its API keys are read-only — there's no way to push updates into it
programmatically. That means every doc change would need a manually-regenerated ZIP and a
manual browser upload to stay current, which is more friction than plain markdown+git already
has, not less. Full story in `decisions/log.md`.

`docker compose down` run in `/opt/docker/configs/leafwiki/`; container and its network are
gone. The `./data/` folder (~1MB) is still on disk there in case anything's worth a last look —
safe to delete whenever, nothing depends on it.

## OpenClaw (AI Agent) — RETIRED (2026-08-12)

Formally retired, not just dormant. Was already fully torn down (zero `openclaw-*` containers,
`openclaw_network` gone) as of the 2026-08-11 audit; its one remaining active dependent — the
Morning Brief cron job — has since been rebuilt to run standalone (see below), so nothing on
this server depends on OpenClaw anymore. The compose file and workspace config are still on
disk at `/opt/docker/configs/openclaw/` if it's ever worth reviving, but treat that as archived,
not "paused." Full history (what it was, the security hardening it had, why it was replaced by
Claude Code's own Remote Control feature for phone access) is in `decisions/log.md` rather than
duplicated here — this used to be a long section describing an actively-run service; keeping
that framing after retirement was itself misleading, so it's trimmed to this pointer.

## Morning Brief (Host Crontab)

Standalone since 2026-08-12 — previously sent via OpenClaw's `message send` CLI, now posts
directly to the Telegram Bot API (`@masa_server_bot`), so it has no dependency on any agent
being up. Runs from host crontab, not Claude Code or any scheduler — reliability for something
that must fire at a fixed time every day beats the flexibility of an AI-driven trigger here.

| Job | Schedule (crontab, UTC) | Local time | Delivery |
|-----|--------------------------|------------|----------|
| Resumen Matutino | `0 11 * * *` | 8:00 AM America/Argentina/Buenos_Aires | Telegram Bot API `sendMessage` |

Script: `~/homelab/scripts/morning-brief.sh` (committed, no secrets in it)
Helper: `~/homelab/scripts/gcal-today.py` (Google Calendar OAuth2 API, Workspace account `matias@honeydewcare.com`)
Secrets: `~/.config/secrets/homelab_bots.env` (Telegram bot token/chat id, Radarr/Sonarr/Jellyseerr/Jellyfin API keys — 0600, not committed, shared with Viernes de Novedades below) + `~/.config/secrets/gcal_oauth.json`
Log: `/tmp/morning-brief.log`

**Sources**:
- Weather: wttr.in
- Agenda: Google Calendar (weekdays only)
- Dollar: dolarapi.com (Blue/Oficial/MEP)
- Bahía Blanca news: La Brújula 24 RSS
- Argentina news: La Nación RSS
- Tech/AI: WWWhat's New RSS, Spanish-language (weekdays only) — replaced TechCrunch (English) per request
- Sports news: Olé RSS
- Twitter/X trends: `trends24.in/argentina/buenos-aires/`, scraped from static HTML (no official API — X's own trends API requires paid access)
- Football matches with TV coverage today: scraped from `promiedos.com.ar`'s embedded Next.js `__NEXT_DATA__` JSON (no official API either; this is the same technique as the trends scrape, not a third-party wrapper). Filtered to games with a `tv_networks` entry as a proxy for "worth mentioning" — un-televised games are omitted
- Infra: `docker ps` on the host directly (was `docker exec openclaw-gateway ...`)
- Disk: `df` (NAS + Mini PC)
- Jellyseerr: pending request count + titles via its own API
- Downloads: Radarr/Sonarr history API, items imported in the last 24h

Weekend mode: no calendar section, no tech/AI section.

**Gotcha for future edits**: the football-matching and any other "what's today" logic must use
`TZ="America/Argentina/Buenos_Aires" date` (or pass that computed date string into any embedded
Python), never a bare `datetime.now()` — **the host's system timezone is UTC**, not Argentina,
so naive local-time code silently computes the wrong calendar day for a chunk of each evening.
This bit the football section on first build (empty results) until fixed.

## Viernes de Novedades (Host Crontab)

Weekly digest, added 2026-08-12, same standalone architecture as Morning Brief (host cron,
direct Telegram Bot API, no agent dependency). Unlike Morning Brief it's a broadcast: every
Jellyseerr user with Telegram notifications enabled + a chat ID set gets it, auto-discovered
via Jellyseerr's own user API each run — no hardcoded recipient list, so newly-linked users are
included automatically. If there's nothing to report (no downloads, no cinema data, no
suggestions) that week, no message is sent at all — no filler "nothing new this week" text.

| Job | Schedule (crontab, UTC) | Local time | Delivery |
|-----|--------------------------|------------|----------|
| Viernes de Novedades | `0 19 * * 5` | 4:00 PM America/Argentina/Buenos_Aires, Fridays | Telegram Bot API `sendPhoto` (top suggestion's poster) then `sendMessage` |

Script: `~/homelab/scripts/weekly-digest.sh` (committed, no secrets)
Curated list: `~/homelab/scripts/rescate-catalogo.txt` — one title per line, edit anytime; script
validates each against the real Jellyfin library and silently skips anything that doesn't match
Secrets: `~/.config/secrets/homelab_bots.env` (shared with Morning Brief)
Log: `/tmp/weekly-digest.log`
Testing: `DRY_RUN=1 ./weekly-digest.sh` prints without sending; `TEST_CHAT_ID=<id> ./weekly-digest.sh`
sends a real message to one chat only, bypassing the normal recipient discovery — use this
instead of the real run whenever testing changes, so edits don't spam every linked user.

**Sections** (each optional — only appears if it has content):
- Estrenos en cines esta semana: `carteleraargentina.com.ar` homepage, `<h2>Estrenos de la
  semana</h2>` block scraped for `<h3>` titles (no official API)
- En cartelera en Bahía Blanca: **not a heuristic** — the real current listing for Matias's
  local Cinemacenter, extracted from their own published weekly schedule PDF
  (`cinemacenter.com.ar/pdf/horariospdf.php?cityId=2`) via `pdftotext -layout`, deduped across
  formats (2D/3D/Sala Turbo all list the same film separately in the PDF) and cross-excluded
  against the national Estrenos list (accent/case-insensitive match) to avoid repeating a title
  in both sections. An earlier version approximated "still showing" from poster upload dates on
  the national site — replaced once a real per-cinema source was found; prefer an authoritative
  source over a heuristic whenever one exists
- Se sumó al server de Masa: Radarr/Sonarr history, items imported in the last 7 days (same
  history-API pattern as Morning Brief's 24h version, wider window)
- Lo más visto esta semana: Jellyfin Playback Reporting plugin, direct SQL via
  `/user_usage_stats/submit_custom_query` (`GROUP BY ItemName ... last 7 days`)
- Tendencias que todavía no tenemos: Jellyseerr's `/discover/trending` (TMDB-backed, Spanish
  titles), filtered to `mediaInfo.status` of `None` or `1` (unknown/not requested — excludes
  anything already pending/processing/available), each with a direct
  `pedidos.matiasmassetti.com/{movie,tv}/{tmdbId}` link so tapping goes straight to the request
  page. The first suggestion's poster is sent as a Telegram photo before the text digest.
- 🎯 Pick de la semana: random pick from the curated `rescate-catalogo.txt` list (validated
  against the live library), shown with year, up to 2 genres, and a trimmed synopsis — all
  pulled from Jellyfin's `Fields=Genres,ProductionYear,Overview`. Originally an algorithmic
  "never played + added 90+ days ago" pick; replaced with a manually curated list per request
  (more reliable taste signal than an algorithm, and Matias wanted control over what gets
  suggested here)
- Espacio libre: NAS free space, with a tiered message rather than bare numbers — **>100GB
  free**: "pedí tranqui, hay espacio 😌"; **≤30GB free**: "se está quedando sin espacio, pedí
  con cuidado ⚠️"; in between: just the numbers, no extra line. Based on absolute GB free, not
  percent-used — this NAS runs at ~96% used by design (large array, redundancy headroom) so a
  percent-based threshold would falsely alarm every week

## Project Containers (Separate Compose Files)

| Service | Container | Port | Compose File | Running 2026-08-11? | Notes |
|---------|-----------|------|--------------|----------------------|-------|
| CEN Dashboard | cen-dashboard-cen-dashboard-1 | 3003 | ~/Code/cen-dashboard/docker-compose.yml | ✅ | Dashboard app |
| Media Tracker DB | media_tracker_db | 5432 | ~/Code/media-tracker-db/docker-compose.yml | ✅ | PostgreSQL 16. Its `pgadmin` service (port 5050) is defined but not currently up |
| Ricota DB | ricota-db-db-1, ricota-db-rest-1, ricota-caddy | 80 (caddy) | ~/homelab/ricota-db/docker-compose.yml | ✅ | Postgres 17 + PostgREST + Caddy (CORS-friendly REST API in front of Postgres, Supabase-style routing at `/rest/v1/*`). **Untracked in git** as of 2026-08-11 — lives inside the homelab repo dir but was never committed |
| USA 2026 | usa2026 | 3000 | ~/Code/usa-2026/docker-compose.yml | ❌ | FIFA World Cup trip planner. Would conflict with `homepage` on :3000 if started |
| Scraper Autoentrada | — | — | ~/Code/scraper-autoentrada/docker-compose.yml | ❌ | Ticket scraper bot |
| Reporte Minoritario | — | — | ~/Code/reporteminoritario-transcript-fetcher/docker-compose.yml | ❌ | Podcast transcript AI |

## Docker Networks

_(verified via `docker network ls`, 2026-08-11)_

| Network | Subnet | Purpose |
|---------|--------|---------|
| arr_network | (bridge, auto) | ARR stack services |
| docker_homelab | (bridge, auto) | Infrastructure + cloud services |
| dns_network | 172.30.0.0/24 | Pi-hole + Unbound |
| cen-dashboard_default | (bridge, auto) | CEN Dashboard project |
| media-tracker-db_media_tracker_network | (bridge, auto) | Media tracker project (name is compose-project-prefixed, not the plain `media_tracker_network` this doc used to say) |
| ricota-db_ricota | (bridge, auto) | Ricota DB internal network (db + rest); `ricota-caddy` also joins `docker_homelab` to be reachable |

`openclaw_network` (172.31.0.0/24) no longer exists — removed along with the OpenClaw containers.

## Docker Named Volumes

- `nextcloud-db`, `nextcloud-app` — likely orphaned since Nextcloud was decommissioned; verify with `docker volume ls` before pruning (see note in Cloud & Storage above)
