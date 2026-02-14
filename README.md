# Matias's Homelab

Personal homelab documentation — single source of truth for hardware, services, and network configuration.

## Setup

- **Beelink SER8** (Ryzen 7 8745HS, 32GB DDR5) — runs all Docker services, Ubuntu 24.04
- **Synology DS423** — NAS with 1x WD Red Pro 14TB, mounted at `/mnt/nas`
- **25+ Docker containers** — media automation (ARR stack), DNS (Pi-hole + Unbound), cloud storage, monitoring, dev projects
- **matiasmassetti.com** — Cloudflare DNS + Tunnel for remote access
- **Tailscale** — private VPN across devices

## Structure

- `CLAUDE.md` — Dense summary auto-loaded by Claude Code
- `hardware/` — Mini PC and NAS specs, storage layout
- `services/` — Running services, Docker Compose details, ports
- `network/` — Topology, IPs, DNS, Cloudflare, Tailscale
- `decisions/` — Architecture Decision Records (ADRs)
- `import/` — Raw docs imported from Claude.ai project (reference only)

## Quick Reference

| Service | URL | Port |
|---------|-----|------|
| Jellyfin | media.matiasmassetti.com | 8096 |
| Radarr | radarr.matiasmassetti.com | 7878 |
| Sonarr | sonarr.matiasmassetti.com | 8989 |
| qBittorrent | descargas.matiasmassetti.com | 8080 |
| Jellyseerr | pedidos.matiasmassetti.com | 5055 |
| Homarr | home.matiasmassetti.com | 7575 |
| Uptime Kuma | status.matiasmassetti.com | 3001 |
| OpenCloud | cloud.matiasmassetti.com | 9200 |
| Pi-hole | — | 8888 |
| Netdata | — | 19999 |

## Updating

When making infrastructure changes:
1. Update the relevant file(s) in this repo
2. Update `CLAUDE.md` if the change affects the high-level summary
3. Add a decision record to `decisions/log.md` if it's a significant choice
4. Commit with a descriptive message
