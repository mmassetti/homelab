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
- **DNS**: Pi-hole (192.168.1.239:53) → Unbound (172.30.0.2:5335, recursive), DNSSEC on

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
_Routing lives entirely in the Cloudflare Zero Trust dashboard (token-based tunnel, no local ingress file), so this table can't be verified from disk — only from what actually answered over the public internet during the 2026-08-11 session, or prior session notes. Re-check the dashboard, don't trust this blindly._

| Subdomain | Target | Last verified |
|-----------|--------|----------------|
| media.matiasmassetti.com | :8096 (Jellyfin) | prior session (unverified 2026-08-11) |
| radarr.matiasmassetti.com | :7878 | ✅ 2026-08-11 (HTTP 302, reachable) |
| sonarr.matiasmassetti.com | :8989 | ✅ 2026-08-11 (HTTP 302, reachable) |
| descargas.matiasmassetti.com | :8080 (qBittorrent) | prior session (unverified 2026-08-11) |
| pedidos.matiasmassetti.com | :5055 (Jellyseerr) | ✅ 2026-08-11, actively used this session |
| home.matiasmassetti.com | :7575 (Homarr) | ⚠️ **stale** — Homarr is gone, dashboard is now `homepage` on :3000. If the tunnel still points at :7575 this URL is broken. Fix in Cloudflare dashboard. |
| status.matiasmassetti.com | :3001 (Uptime Kuma) | prior session (unverified 2026-08-11) |
| cloud.matiasmassetti.com | :9200 (OpenCloud) | prior session (unverified 2026-08-11) |

## OpenClaw — currently NOT running (as of 2026-08-11)
Compose file still exists at `/opt/docker/configs/openclaw/docker-compose.yml`, but `docker ps -a` shows **zero** `openclaw-*` containers (not even stopped ones) and the `openclaw_network` (172.31.0.0/24) no longer exists — it was fully torn down at some point, not just paused. The Telegram bot "Claudito" (`@clauditomassetti_bot`), the Morning Brief cron, and the Mission Control dashboard should all be assumed **inactive** until re-verified. Do not assume any of the operational rules below still apply without checking first.

Historical config (kept for reference if reviving it): dedicated `openclaw_network`, gateway bound to 127.0.0.1 only (18789/18790/3333), hardened (`read_only`, `cap_drop: ALL`, `no-new-privileges`), Docker socket mounted for sandbox spawning, Telegram polling outbound-only with user ID allowlist, NOT exposed via Cloudflare Tunnel. Full details in `services/services.md` § OpenClaw (not rewritten — historical, matches what's on disk in the compose file, not what's currently deployed).

## Project Containers (separate compose files)
| Project | Port | Compose | Running 2026-08-11? |
|---------|------|---------|----------------------|
| cen-dashboard | 3003 | ~/Code/cen-dashboard/docker-compose.yml | ✅ |
| media_tracker_db | 5432 | ~/Code/media-tracker-db/docker-compose.yml | ✅ (postgres only; its `pgadmin` service is defined but not up) |
| ricota-db | 80 (via ricota-caddy) | ~/homelab/ricota-db/docker-compose.yml | ✅ Postgres 17 + PostgREST + Caddy, `git status` shows this dir is **untracked** — new, not yet committed |
| usa-2026 | 3000 | ~/Code/usa-2026/docker-compose.yml | ❌ not running (would conflict with `homepage` on :3000 if started) |
| scraper-autoentrada | — | ~/Code/scraper-autoentrada/docker-compose.yml | ❌ not running |
| reporteminoritario | — | ~/Code/reporteminoritario-transcript-fetcher/docker-compose.yml | ❌ not running |

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
