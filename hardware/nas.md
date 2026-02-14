# NAS — Synology DS423

## Hardware

- **Model**: Synology DS423 (4-bay, purchased Jan 2026)
- **CPU**: Realtek RTD1619B (quad-core ARM 1.7 GHz, 64-bit)
- **RAM**: 2GB DDR4 (expandable to 6GB via SO-DIMM)
- **Drive Bays**: 4x 3.5"/2.5" SATA, hot-swappable, tool-less
- **Network**: 2x Gigabit Ethernet (bondable), 3x USB 3.2 Gen 1, 2x eSATA
- **IP**: 192.168.1.119 (static)
- **OS**: DSM 7.x
- **Power**: ~20W idle, ~30W load
- **Location**: Office (next to mini PC)

## Drives

| Bay | Drive | Size | Type | Status |
|-----|-------|------|------|--------|
| 1 | WD Red Pro 14TB (WD142KFGX) | 14TB | 3.5" SATA, CMR, 7200 RPM, 512MB cache | Installed |
| 2 | (empty) | — | — | Planned: WD Red Pro 14TB (June 2026 USA trip) |
| 3 | (empty) | — | — | Planned: WD Red Pro 14TB (optional) |
| 4 | (empty) | — | — | Available |

## Storage Pool

- **RAID**: SHR (Synology Hybrid RAID) — currently single drive, no redundancy yet
- **Filesystem**: Btrfs (snapshots, checksums, data integrity)
- **Usable**: ~12.7TB (single 14TB drive)
- **Future**: Add 1-2 more drives in June 2026 for SHR redundancy

## Shares & Mounts

The NAS is mounted on the mini PC via two protocols:

### SMB/CIFS Mount (`/mnt/nas/`) — Media

```
# /etc/fstab entry
//192.168.1.119/Media /mnt/nas cifs credentials=/root/.nascreds,uid=1000,gid=1000,_netdev,echo_interval=60,actimeo=30 0 0
```

| Path | Purpose |
|------|---------|
| `/mnt/nas/Peliculas/` | Movies (Radarr → Jellyfin) |
| `/mnt/nas/Series/` | TV Shows (Sonarr → Jellyfin) |
| `/mnt/nas/Music/` | Music (Lidarr → Jellyfin) |
| `/mnt/nas/downloads/` | qBittorrent download directory |

### NFS Mount (`/mnt/nas-nfs/`) — OpenCloud Data

```
# /etc/fstab entries
192.168.1.119:/volume1/Media /mnt/nas-nfs nfs defaults,_netdev 0 0
/mnt/nas-nfs/opencloud-data/opencloud.img /mnt/opencloud ext4 loop,defaults,_netdev 0 0
```

OpenCloud data is stored in a **2TB sparse ext4 image file** (`opencloud.img`) on the NAS, loop-mounted at `/mnt/opencloud`. This avoids filesystem compatibility issues (symlinks, xattr) between Docker and the NAS's native Btrfs/SMB.

To resize the image (e.g. to 3TB):
```bash
docker compose -f /opt/docker/docker-compose.yml stop opencloud
sudo umount /mnt/opencloud
truncate -s 3T /mnt/nas-nfs/opencloud-data/opencloud.img
sudo e2fsck -f /mnt/nas-nfs/opencloud-data/opencloud.img
sudo resize2fs /mnt/nas-nfs/opencloud-data/opencloud.img
sudo mount /mnt/opencloud
docker compose -f /opt/docker/docker-compose.yml start opencloud
```

| Path | Purpose |
|------|---------|
| `/mnt/nas-nfs/` | NFS mount of NAS volume |
| `/mnt/nas-nfs/opencloud-data/opencloud.img` | ext4 image file for OpenCloud |
| `/mnt/opencloud/` | Loop mount of the ext4 image (used by OpenCloud container) |

## Backup Strategy

### Current
- Single drive, no redundancy — **critical to add 2nd drive ASAP**
- Seagate 4TB USB on mini PC as legacy copy of older media

### Planned (After 2nd Drive)
- **Level 1**: Btrfs snapshots (hourly keep 24, daily keep 7, weekly keep 4)
- **Level 2**: SHR 1-disk redundancy
- **Level 3**: External USB drive via Hyper Backup (weekly, Sunday 3 AM)
- **Future**: Offsite cloud backup (B2/Wasabi) for 3-2-1 rule
