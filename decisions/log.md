# Architecture Decision Records

## 2026-02 — Replace Jackett with Prowlarr

**Context**: Jackett was the original indexer proxy for the ARR stack
**Decision**: Migrated to Prowlarr (native *arr integration)
**Rationale**: Prowlarr syncs indexers automatically to Radarr/Sonarr/Lidarr, less manual config

## 2026-02 — Add Pi-hole + Unbound DNS stack

**Context**: Wanted network-wide ad blocking and recursive DNS
**Decision**: Deploy Pi-hole (ad blocking) with Unbound (recursive resolver) in dedicated Docker network
**Rationale**: Full DNS control, no reliance on upstream DNS providers, DNSSEC enabled

## 2026-02 — Deploy OpenCloud instead of expanding Nextcloud

**Context**: Needed cloud storage accessible via cloud.matiasmassetti.com
**Decision**: Added OpenCloud (opencloudeu/opencloud-rolling) alongside existing Nextcloud
**Rationale**: Modern alternative, simpler setup for file sharing

## 2026-01 — Buy Synology DS423 with single WD Red Pro 14TB

**Context**: Planned 4x14TB but drives were out of stock
**Decision**: Start with 1 drive, add 1-2 more in June 2026 USA trip
**Alternatives considered**: Wait for all 4 drives, buy different brand
**Rationale**: Get NAS operational now, expand later. SHR allows adding drives without rebuilding

## 2026-01 — Mount NAS via SMB/CIFS (not NFS)

**Context**: Original plan was NFS for Linux-to-Linux performance
**Decision**: Using SMB/CIFS mount (`//192.168.1.119/Media /mnt/nas`)
**Rationale**: Simpler setup, works well for current workload

## 2026-01 — Migrate media from USB drive to NAS

**Context**: Seagate 4TB USB was 99% full, single point of failure
**Decision**: Moved all media to NAS, updated Docker volume mounts from `/DATA/` to `/mnt/nas/`
**Rationale**: Centralized storage, path to redundancy once more drives added

## 2025-12 — Use Hotio images for ARR stack

**Context**: Migrated from LinuxServer.io images to Hotio
**Decision**: All ARR services use ghcr.io/hotio/* images
**Rationale**: 2026 best practices, consistent configuration, common YAML anchor

## 2025-12 — Keep CasaOS

**Context**: Considered replacing with Portainer + File Browser
**Decision**: Keep CasaOS for now
**Rationale**: Working fine for Docker management and file browsing, re-evaluate later

## 2025-12 — Cloudflare Tunnel only (no Tailscale for public access)

**Context**: Needed remote access to services
**Decision**: Cloudflare Tunnel for public-facing services, Tailscale for private device access
**Rationale**: Tunnel = zero port forwarding, auto SSL. Tailscale = secure device-to-device VPN

## 2025-12 — SHR over Basic RAID

**Context**: Choosing RAID type for NAS
**Decision**: SHR (Synology Hybrid RAID) from the start
**Rationale**: Allows mixed drive sizes, easy expansion, 1-disk redundancy when 2+ drives present

---

<!-- Add new decisions above this line, newest first -->
