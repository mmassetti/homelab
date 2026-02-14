# Matias's Homelab — Claude Code Context

> Auto-loaded when working in `~/homelab/`. Dense summary of entire setup.
> Last updated: 2026-02-14. See individual files for full details.

## Hardware

### Mini PC — Beelink SER8
- **CPU**: AMD Ryzen 7 8745HS (8c/16t, 3.8/5.1 GHz) | **RAM**: 32GB DDR5 | **GPU**: Radeon 780M (RDNA 3)
- **Storage**: 931.5GB NVMe (LVM, ext4, `/`) + Seagate 4TB USB at `/DATA/Media` (exFAT, 99% full, legacy)
- **OS**: Ubuntu Server 24.04.2 LTS, kernel 6.8.0-94-generic
- **IP**: 192.168.1.239 | **Tailscale**: 100.118.87.121 | **Hostname**: `homelab`
- Runs 24/7, ~30-50W, headless, 2x 2.5GbE (using enp1s0)

### NAS — Synology DS423
- **IP**: 192.168.1.119 | **OS**: DSM 7.x | 4-bay, currently 1x WD Red Pro 14TB
- **Mount**: `//192.168.1.119/Media` → `/mnt/nas` via SMB/CIFS (fstab, `_netdev`)
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
| prowlarr | 9696 | — |
| flaresolverr | 8191 | — |
| jellyseerr | 5055 | — |
| profilarr | 6868 | — |

**Flow**: Jellyseerr → Radarr/Sonarr (via Prowlarr) → qBittorrent → NAS → Bazarr (subs) → Jellyfin

### DNS Stack (dns_network: 172.30.0.0/24)
| Service | Port | IP |
|---------|------|----|
| unbound | 5335 | 172.30.0.2 |
| pihole | 53, 8888(web) | 172.30.0.3 |

### Infrastructure (docker_homelab network)
| Service | Port | Notes |
|---------|------|-------|
| cloudflared | — | Cloudflare Tunnel |
| homarr | 7575 | Dashboard |
| uptime-kuma | 3001 | Monitoring |
| glances | host | System stats |
| netdata | 19999 | Advanced monitoring |

### Cloud & Storage (docker_homelab network)
| Service | Port | Notes |
|---------|------|-------|
| opencloud | 9200 | cloud.matiasmassetti.com |
| nextcloud | 8090 | Personal cloud, mounts /mnt/nas |
| nextcloud-db | 3306 | MariaDB 10.11 |
| image-server | 4010 | Static files from /opt/images |

### Named volumes: nextcloud-db, nextcloud-app

## Cloudflare Tunnel URLs
| Subdomain | Target |
|-----------|--------|
| media.matiasmassetti.com | :8096 (Jellyfin) |
| radarr.matiasmassetti.com | :7878 |
| sonarr.matiasmassetti.com | :8989 |
| descargas.matiasmassetti.com | :8080 (qBittorrent) |
| pedidos.matiasmassetti.com | :5055 (Jellyseerr) |
| home.matiasmassetti.com | :7575 (Homarr) |
| status.matiasmassetti.com | :3001 (Uptime Kuma) |
| cloud.matiasmassetti.com | :9200 (OpenCloud) |

## Project Containers (separate compose files)
| Project | Port | Compose |
|---------|------|---------|
| usa-2026 | 3000 | ~/Code/usa-2026/docker-compose.yml |
| cen-dashboard | 3003 | ~/Code/cen-dashboard/docker-compose.yml |
| media_tracker_db | 5432 | ~/media-tracker-db/docker-compose.yml |
| scraper-autoentrada | — | ~/Code/scraper-autoentrada/docker-compose.yml |
| reporteminoritario | — | ~/Code/reporteminoritario-transcript-fetcher/docker-compose.yml |

## System Services (non-Docker)
- CasaOS (6 services: main, gateway, app-mgmt, local-storage, message-bus, user-service)
- Tailscale (tailscaled)
- SSH, cron, Docker

## Key Paths
| Path | Contents |
|------|----------|
| `/opt/docker/docker-compose.yml` | Main homelab compose |
| `/opt/docker/configs/<svc>/` | Per-service Docker configs |
| `/opt/docker/downloads/` | Legacy download dir |
| `/mnt/nas/` | NAS mount (Peliculas, Series, Music, downloads) |
| `/DATA/Media/` | Seagate 4TB USB (legacy, 99% full) |
| `/opt/images/` | Shared images dir (Nextcloud + image-server) |
| `~/Code/` | Development projects |

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
- homelab (100.118.87.121) — always on, exit node
- MacBook Pro (100.64.172.116)
- NVIDIA Shield (100.77.190.51)
- Samsung S23 Ultra (100.121.189.40)

## Other Devices (not on this server)
- **Gaming PC**: AMD Ryzen 5 2600, RX 570 8GB, 16GB DDR4, Win 10, DHCP
- **MacBook M4 Pro**: Primary dev machine, SSH to homelab
- **NVIDIA Shield Pro TV**: Jellyfin client, living room
- **BenQ X3000i**: 4K projector, living room
- **Samsung S23 Ultra**: Mobile access to services
