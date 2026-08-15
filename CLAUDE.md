# Matias's Homelab — Claude Code Context

> Auto-loaded when working in `~/homelab/`. Dense summary of entire setup.
> Last updated: 2026-08-11. See individual files for full details.

## Hardware

### Mini PC — Beelink SER8
- **CPU**: AMD Ryzen 7 8745HS (8c/16t, 3.8/5.1 GHz) | **RAM**: 32GB DDR5 | **GPU**: Radeon 780M (RDNA 3)
- **Storage**: 931.5GB NVMe (LVM, ext4, `/`) + Seagate 4TB USB at `/DATA/Media` (exFAT, 99% full, legacy)
- **OS**: Ubuntu Server 24.04.2 LTS, kernel 6.8.0-94-generic
- **IP**: 192.168.1.239 | **Tailscale**: 100.112.136.118 | **Hostname**: `homelab` | **SSH**: `ssh matias@homelab` (MagicDNS)
- Runs 24/7, ~30-50W, headless, 2x 2.5GbE (using enp1s0)

### NAS — Synology DS423
- **IP**: 192.168.1.119 | **OS**: DSM 7.x | 4-bay, currently 1x WD Red Pro 14TB
- **SMB Mount**: `//192.168.1.119/Media` → `/mnt/nas` via SMB/CIFS (fstab, `_netdev`) — media
- **NFS Mount**: `192.168.1.119:/volume1/Media` → `/mnt/nas-nfs` (fstab, `_netdev`) — OpenCloud data
- **Loop Mount**: `/mnt/nas-nfs/opencloud-data/opencloud.img` → `/mnt/opencloud` (ext4, loop) — OpenCloud container volume
- **No redundancy yet** — 2nd drive planned June 2026
- SHR pool, Btrfs filesystem

## Network
- **Subnet**: 192.168.1.0/24 | **Gateway**: 192.168.1.1 (TP-Link Archer AX55, WiFi 6)
- **ISP**: 300/~40 Mbps, Argentina, dynamic public IP
- **Modem**: I-CON IC455WDB (bridge mode)
- **Domain**: matiasmassetti.com (Porkbun, DNS via Cloudflare)
- **Remote access**: Cloudflare Tunnel (public services) + Tailscale (private VPN)
- **DNS**: Pi-hole (192.168.1.239:53) → Unbound (172.30.0.2:5335, recursive), DNSSEC on, conditional forwarding to router (192.168.1.1) for hostnames, Unbound running 4 threads (since 2026-08-13)

## Docker — Main Stack (`/opt/docker/docker-compose.yml`)
Config base: `/opt/docker/configs/<service>/`

### ARR Stack (arr_network) — all Hotio images, PUID/PGID=1000, TZ=America/Argentina/Buenos_Aires
| Service | Port | Media Volumes |
|---------|------|---------------|
| jellyfin | 8096 | /mnt/nas/{Peliculas,Series,Music} |
| radarr | 7878 | /mnt/nas/{downloads,Peliculas} |
| sonarr | 8989 | /mnt/nas/{downloads,Series} |
| lidarr | 8686 | /mnt/nas/{downloads,Music} |
| bazarr | 6767 | /mnt/nas/{Peliculas,Series} |
| qbittorrent | 8080/6881 | /mnt/nas/downloads |
| sabnzbd | 8085 | /mnt/nas/downloads (Usenet client, alt. to qBittorrent — added since last audit) |
| prowlarr | 9696 | — |
| flaresolverr | 8191 | — |
| jellyseerr | 5055 | — |
| profilarr | 6868 | — |

**Flow**: Jellyseerr → Radarr/Sonarr (via Prowlarr) → qBittorrent/SABnzbd (download) → NAS → Bazarr (subs) → Jellyfin

**Notifications (added 2026-08-11)**: Radarr and Sonarr both have a Telegram connection ("Telegram - Claudito") firing on Grab/Download/Upgrade/Health Issue/Health Restored/Manual Interaction, sent to the admin chat. Jellyfin has the official **Webhook** plugin installed, with a Generic destination posting directly to the Telegram Bot API (`sendMessage`) on `PlaybackStart` for movies/episodes/songs — a "now playing" ping to the admin chat. Jellyseerr's own notification settings (Settings → Notifications → Telegram, admin-level) cover request pending/approved/declined/available; individual users self-register their personal Telegram chat ID either via their own Profile → Notifications → Telegram, or the admin pastes it in for them under Settings → Users → [user] → Notifications after the user DMs the bot. Bot: `@masa_server_bot`. Tokens/chat IDs intentionally not duplicated here — this repo is pushed to a public-facing GitHub remote (`origin` → `github.com:mmassetti/homelab`); check the respective app's Settings → Connect/Notifications page or ricota-style local `.env`/secrets files instead.

### DNS Stack (dns_network: 172.30.0.0/24)
| Service | Port | IP |
|---------|------|----|
| unbound | 5335 | 172.30.0.2 |
| pihole | 53, 8888(web) | 172.30.0.3 |

### Infrastructure (docker_homelab network)
| Service | Port | Notes |
|---------|------|-------|
| cloudflared | — | Cloudflare Tunnel (runs via `tunnel --token`, no local `config.yml` — ingress/subdomain routing lives in the Cloudflare Zero Trust dashboard, not on disk) |
| homepage | 3000 | Dashboard — **replaced Homarr** (removed; container and its config no longer exist) |
| uptime-kuma | 3001 | Monitoring |
| glances | host | System stats |
| netdata | 19999 | Advanced monitoring |
| cinemateca | 8001 | Custom-built (`/opt/docker/configs/cinemateca`) personal movie catalog/enricher — pulls Letterboxd (`matimassetti`) + Jellyfin + TMDB director data, reads `/mnt/nas/Peliculas` read-only, writes to the `cinemateca` DB on `media_tracker_db` (192.168.1.239:5432) |

### Cloud & Storage (docker_homelab network)
| Service | Port | Notes |
|---------|------|-------|
| opencloud | 9200 | cloud.matiasmassetti.com, data on NAS via /mnt/opencloud |
| image-server | 4010 | Static files from /opt/images |

**Nextcloud has been decommissioned** — `nextcloud` and `nextcloud-db` containers no longer exist (not even stopped); not in `/opt/docker/docker-compose.yml` anymore. If `/opt/images` was shared with Nextcloud specifically, double check nothing still expects it.

## Cloudflare Tunnel URLs
Pulled straight from the tunnel's live ingress config via the Cloudflare API (`GET /accounts/{account}/cfd_tunnel/{tunnel}/configurations`) on 2026-08-11 — this is ground truth, not guesswork. Tunnel is token-based (no local `config.yml`); manage it via API or the Zero Trust dashboard (Networks → Tunnels).

Account ID: `7dfee4d2de02fa195e6b9674de205fa6` · Tunnel ID: `7ddc3a66-cfbf-46b9-8124-2bfef8a27456` (both derivable from the tunnel token in the compose file, not secret in the same way an API token is, but still avoid publishing further).

| Subdomain | Target |
|-----------|--------|
| media.matiasmassetti.com | 192.168.1.239:8096 (Jellyfin) |
| radarr.matiasmassetti.com | 192.168.1.239:7878 |
| sonarr.matiasmassetti.com | 192.168.1.239:8989 |
| bazarr.matiasmassetti.com | 192.168.1.239:6767 |
| lidarr.matiasmassetti.com | 192.168.1.239:8686 |
| prowlarr.matiasmassetti.com | 192.168.1.239:9696 |
| profilarr.matiasmassetti.com | 192.168.1.239:6868 |
| descargas.matiasmassetti.com | 192.168.1.239:8080 (qBittorrent) |
| usenet.matiasmassetti.com | 192.168.1.239:8085 (SABnzbd) |
| pedidos.matiasmassetti.com | 192.168.1.239:5055 (Jellyseerr) |
| home.matiasmassetti.com | 192.168.1.239:3000 (homepage — fixed 2026-08-11, was stale-pointed at Homarr's old :7575) |
| status.matiasmassetti.com | 192.168.1.239:3001 (Uptime Kuma) |
| cloud.matiasmassetti.com | 192.168.1.239:9200 (OpenCloud) |
| cinemateca.matiasmassetti.com | 192.168.1.239:8001 |
| assets.matiasmassetti.com | 192.168.1.239:4010 (image-server) |
| cen-api.matiasmassetti.com | 192.168.1.239:3003 (cen-dashboard) |
| ricota-api.matiasmassetti.com | `ricota-caddy:80` (container hostname — cloudflared and ricota-caddy share `docker_homelab`) |
| coleccion.matiasmassetti.com | 192.168.1.239:3004 (media-tracker-app, added 2026-08-15) |
| *(catch-all)* | `http_status:404` |

**Removed 2026-08-11**: `nas.matiasmassetti.com` → `192.168.1.119:5000` used to point straight at the Synology DSM login page, publicly exposed with no Cloudflare Access policy in front of it as far as this token can see. Matias didn't know it was there; both the tunnel ingress rule and the DNS CNAME record were deleted via API (the token was granted `Zone:DNS:Edit` for this) — the hostname no longer resolves to anything at all. Remote NAS access still works via Tailscale.

**Cloudflare Access (added 2026-08-12, extended 2026-08-15)**: 16 of the 18 hostnames now require Cloudflare Access (email OTP, `matiasmassetti@gmail.com`, 168h session) before even reaching the app — everything except `media.matiasmassetti.com` and `pedidos.matiasmassetti.com`, left open since family/friends use Jellyfin/Jellyseerr directly. `coleccion.matiasmassetti.com` (Access app "Coleccion 4K") got the same policy on creation. Live testing before this change confirmed every ARR app already enforced its own login too (401/403 without auth) — Access is a second layer, not a fix for a hole. One real fix that came out of the same audit: Sonarr had `authenticationRequired: disabledForLocalAddresses` (inconsistent with Radarr/Prowlarr/Lidarr's `enabled`) — corrected via its API, verified 401 now even from localhost. Full list + rationale: `decisions/log.md`.

**API access**: a Cloudflare API token (name "cloudflare tunnel minipc access") is stored at `~/.config/secrets/cloudflare_api_token` (0600). Manages both tunnel ingress (`Account:Cloudflare Tunnel:Edit`) and DNS records (`Zone:DNS:Edit` on `matiasmassetti.com`) programmatically — the DNS grant had silently stopped working at some point after 2026-08-11 ("Authentication error" on reads), got re-applied and verified working again 2026-08-15 (see `decisions/log.md`). No more manual dashboard steps needed for new subdomains.

## OpenClaw — RETIRED (2026-08-12)
Formally retired, not just dormant — it was already fully torn down (zero `openclaw-*` containers, `openclaw_network` gone) as of 2026-08-11, and its last live dependent (the Morning Brief cron) has since been rebuilt to run standalone with no agent dependency. Compose file/workspace still on disk at `/opt/docker/configs/openclaw/` if ever worth reviving, but nothing currently depends on it. Full history in `decisions/log.md`; a short pointer (not the old full writeup) is in `services/services.md` § OpenClaw.

## Morning Brief — standalone (rebuilt 2026-08-12)
Host crontab (`0 11 * * *` UTC = 8:00 AM ART) runs `~/homelab/scripts/morning-brief.sh`, posting straight to the Telegram Bot API (`@masa_server_bot`) — no OpenClaw dependency anymore. Sections: weather, Google Calendar agenda (weekdays), dollar (Blue/Oficial/MEP), Bahía Blanca + Argentina news, Tech/AI via WWWhat's New RSS (Spanish, weekdays), Olé sports news, Twitter/X trends (scraped from `trends24.in`), today's TV-broadcast football matches (scraped from `promiedos.com.ar`'s embedded `__NEXT_DATA__` JSON — no official API for either scrape), infra (`docker ps`), disk, Jellyseerr pending requests, and Radarr/Sonarr downloads from the last 24h. Secrets in `~/.config/secrets/homelab_bots.env` (not committed, shared with Viernes de Novedades below). Full source list and a timezone gotcha (host is UTC, not Argentina — must pass an explicit ART-computed date into anything doing "today" logic) documented in `services/services.md` § Morning Brief.

## Viernes de Novedades — weekly digest (added 2026-08-12)
Host crontab (`0 19 * * 5` UTC = 4:00 PM ART, Fridays) runs `~/homelab/scripts/weekly-digest.sh`. Same standalone pattern as Morning Brief, but broadcasts to every Jellyseerr user with Telegram linked (auto-discovered via Jellyseerr's user API, not hardcoded) instead of just the admin. Sends the top suggestion's TMDB poster as a photo, then text: national cinema releases + the real current Bahía Blanca listing (scraped from Cinemacenter's own weekly schedule PDF via `pdftotext`, not a guess), what got added to the server in the last 7 days, most-played this week (Jellyfin Playback Reporting SQL), trending suggestions not yet in the library with direct `pedidos.matiasmassetti.com` request links, a "Pick de la semana" randomly drawn from a manually curated list (`scripts/rescate-catalogo.txt`, one title per line, validated live against the library), and NAS free space with a tiered message (>100GB "hay espacio 😌", ≤30GB "cuidado ⚠️"). Skips sending entirely if there's nothing to report that week. Test with `DRY_RUN=1` (prints, sends nothing) or `TEST_CHAT_ID=<id>` (real send to one chat only) — never run it live unfiltered while testing. Full detail in `services/services.md` § Viernes de Novedades.

## Project Containers (separate compose files)
| Project | Port | Compose | Running 2026-08-11? |
|---------|------|---------|----------------------|
| cen-dashboard | 3003 | ~/Code/cen-dashboard/docker-compose.yml | ✅ |
| media_tracker_db | 5432 | ~/Code/media-tracker-db/docker-compose.yml | ✅ (postgres only; its `pgadmin` service is defined but not up) |
| media-tracker-app | 3004→3002 | ~/Code/media-tracker-api/docker-compose.yml | ✅ added 2026-08-15 — self-hosted frontend+API for `coleccion.matiasmassetti.com`, replaces the old Vercel deploy. See § 4K Collection Tracker below |
| ricota-db | 80 (via ricota-caddy) | ~/homelab/ricota-db/docker-compose.yml | ✅ Postgres 17 + PostgREST + Caddy, `git status` shows this dir is **untracked** — new, not yet committed |
| usa-2026 | 3000 | ~/Code/usa-2026/docker-compose.yml | ❌ not running (would conflict with `homepage` on :3000 if started) |
| scraper-autoentrada | — | ~/Code/scraper-autoentrada/docker-compose.yml | ❌ not running |
| reporteminoritario | — | ~/Code/reporteminoritario-transcript-fetcher/docker-compose.yml | ❌ not running |

## 4K Collection Tracker — self-hosted (2026-08-15)
`coleccion.matiasmassetti.com` — tracks Matias's physical 4K/Blu-ray/DVD collection
(`media_tracker` DB, table `media_items`; box sets go in `collections`/`collection_movies`).
Previously deployed frontend-only to Vercel (`4k-tracking.vercel.app`, repo
`github.com/mmassetti/4k-tracking` = `~/Code/media-tracker-api`), broken ("Failed to fetch
collections") — turned out to have **no Supabase dependency at all** (a red herring guess);
the real cause was a `media-tracker-api.service` systemd unit installed with the wrong path
(`/home/matias/media-tracker-api` instead of the actual `~/Code/media-tracker-api/backend`),
crash-looping (`226/NAMESPACE`) since whenever it was set up, plus the backend port was never
added to the Cloudflare Tunnel anyway.
**Rebuilt self-hosted**: `express.static` + SPA fallback added to `backend/src/server.ts` so
one container serves both the built frontend and the `/api/*` routes (same-origin, no CORS
needed). Multi-stage `Dockerfile` at repo root. `docker-compose.yml` joins the *existing*
`media-tracker-db_media_tracker_network` (external) so it reaches Postgres by container name
(`DB_HOST=media_tracker_db`) instead of the host LAN IP. Host port **3004** (3002 was already
Jellystat's). `VITE_TMDB_API_KEY` build arg reuses the same key as `cinemateca`. Tunnel
ingress + Access app ("Coleccion 4K", same email-OTP policy as the rest) added via API; the
DNS CNAME had to be added manually in the dashboard (this token still can't touch DNS — see
Cloudflare Tunnel URLs section). Old systemd unit needs manual removal (needs an interactive
sudo password, couldn't be done non-interactively) — see `TODO.md`.
**Data quality — fixed same day**: compared the DB (82 `media_items`) against a just-updated
Google Sheet inventory (85 rows) and resolved everything found: 12 duplicated titles removed
(kept the more complete/watched copy where the pair actually differed — Akira's purchase
price, The Exorcist's watched flag), John Wick: Chapter 4 corrected to Blu-ray, 16 owned titles
backfilled with full TMDB enrichment. Godzilla Minus One confirmed correctly owned (the Sheet,
not the DB, was wrong). DB now at 86 items. Full detail in `decisions/log.md`.
**"Add a movie" workflow — resolved, no Sheets sync needed**: dropped the two-way Sheet↔DB
sync idea. The app already had a working `/add` page (verified via a live API smoke test);
added `GET /api/media/export.csv` (button in Settings) so the Sheet is now a disposable,
always-current export instead of something to keep manually in sync. Three ways to add a
movie: the web form, telling Claude here, or bulk JSON import.
**Post-launch fixes/features (2026-08-15, same day)**: CSP from `helmet()` was blocking
`image.tmdb.org` posters and the frontend's direct `api.themoviedb.org` calls — allowlisted
both. `pg` was returning NUMERIC columns (`voteAverage`, `purchasePrice`) as strings, crashing
`ItemDetail` on `.toFixed()` — fixed globally via a `pg` type parser instead of patching each
call site. Added a `seenBefore` column/feature distinguishing "watched this physical copy"
from "had seen the movie before, in general" (independent booleans, both toggleable from the
Add/Edit form and the item detail page) — scoped to standalone items, not box sets/collections.
Full history in the repo's own commits (`~/Code/media-tracker-api`, pushed via SSH — the HTTPS
remote has no stored credential from this session).

## Documentation — LeafWiki tried and dropped (2026-08-15, same day)
Trialed as a wiki layer over `~/homelab`'s docs; dropped because its Markdown import is
web-UI-only (no API) and its API keys are read-only — no programmatic way to keep it in sync,
so every doc change would need a manual ZIP re-upload. `docker compose down` already run;
`/opt/docker/configs/leafwiki/` still has the compose file + a small leftover `data/` dir if
ever revisited (a future version with a real write API would change the calculus). Full story
in `services/services.md` § Documentation and `decisions/log.md`.

## System Services (non-Docker)
- CasaOS (6 services: main, gateway, app-mgmt, local-storage, message-bus, user-service)
- Tailscale (tailscaled)
- SSH, cron, Docker

## Key Paths
| Path | Contents |
|------|----------|
| `/opt/docker/docker-compose.yml` | Main homelab compose |
| `/opt/docker/configs/<svc>/` | Per-service Docker configs |
| `/mnt/nas/` | NAS SMB mount (Peliculas, Series, Music, downloads, Libros, Backups) |
| `/mnt/nas-nfs/` | NAS NFS mount (OpenCloud ext4 image file) |
| `/mnt/opencloud/` | Loop mount of OpenCloud ext4 image (container volume) |
| `/mnt/nas/Google Drive 4-10-2024/` | Google Drive backup (278GB, pending migration) |
| `/DATA/Media/` | Seagate 4TB USB (legacy, 99% full) |
| `/opt/images/` | Shared images dir (Nextcloud + image-server) |
| `~/Code/` | All development projects (7 repos) |
| `~/homelab/file-structure.md` | Full file tree documentation |

## Conventions
- Compose files: main stack in `/opt/docker/`, projects in their own dirs
- Config: `/opt/docker/configs/<service>/`
- Decisions: `~/homelab/decisions/log.md`

## IMPORTANT: Keep Docs in Sync
Whenever you make infrastructure changes (add/remove containers, change ports, modify
network config, update mounts, add services, change compose files, etc.), you MUST also:
1. Update the relevant file(s) in this repo (services.md, network.md, hardware/, etc.)
2. Update THIS file (CLAUDE.md) if the change affects the high-level summary
3. Add a decision record to `decisions/log.md` for significant architectural choices
4. Commit the doc changes alongside or immediately after the infrastructure change

## Tailscale Devices
_(verified 2026-08-09 via `tailscale status`)_
- homelab (100.112.136.118) — always on, tags `SSH`+`Subnets`, advertises approved subnet route 192.168.1.0/24. Not currently an exit node.
- MacBook Pro (100.102.177.38)
- Samsung S23 Ultra (100.111.162.37) — intermittent
- MagicDNS domain: `tail076e1b.ts.net` — use `ssh matias@homelab` for remote access, falls back to the IP above. Tailscale SSH requires periodic browser re-auth ("check mode"); see `network/network.md` for details.

## Other Devices (not on this server)
- **Gaming PC**: AMD Ryzen 5 2600, RX 570 8GB, 16GB DDR4, Win 10, DHCP
- **MacBook M4 Pro**: Primary dev machine, SSH to homelab
- **NVIDIA Shield Pro TV**: Jellyfin client, living room
- **BenQ X3000i**: 4K projector, living room
- **Samsung S23 Ultra**: Mobile access to services
