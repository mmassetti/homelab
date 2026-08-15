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

## DSM API Access (added 2026-08-15)

Dedicated account `claude-agent` in the `administrators` group (DSM has no scoped/read-only
admin role — Control Panel access requires full admin group membership either way).
Shared-folder permissions on Documents/homes/Media are read-only or no-access — irrelevant to
what this account is for, since Control Panel/API access comes from group membership, not
share ACLs. Credentials at `~/.config/secrets/synology_admin.env` on the mini PC (chmod 600,
not in this repo). API reachable at `https://192.168.1.119:5001/webapi/` (also plain HTTP on
`:5000`) — auth via `SYNO.API.Auth` (`auth.cgi`) for a session id, then `entry.cgi` for
everything else. Use `SYNO.API.Info` with `query=all` to discover real API names — many DSM
settings live under names that don't match their Control Panel section (e.g. recycle bin
policy is `SYNO.Core.RecycleBin` + `SYNO.Core.TaskScheduler`, not under `SYNO.Core.Share`).

## Drives

| Bay | Drive | Size | Type | Status |
|-----|-------|------|------|--------|
| 1 | WD Red Pro 14TB (WD142KFGX) | 14TB | 3.5" SATA, CMR, 7200 RPM, 512MB cache | Installed |
| 2 | WD Red Pro 14TB (WD142KFGX) | 14TB | 3.5" SATA, CMR, 7200 RPM, 512MB cache | Installed 2026-07 — **redundancy, not capacity** (see below) |
| 3 | (empty) | — | — | Planned: WD Red Pro 14TB, to be bought Feb 2027 (US trip) — first drive to actually grow usable capacity |
| 4 | (empty) | — | — | Available |

## Storage Pool

- **RAID**: SHR (Synology Hybrid RAID), 2 drives, 1-disk redundancy
- **Filesystem**: Btrfs (snapshots, checksums, data integrity)
- **Usable**: ~12.7TB — unchanged from the single-drive figure, since the 2026-07 disk went to redundancy (mirroring), not pool growth
- **Current usage**: 97% full, ~419GB free as of 2026-08-13 — tight until the 3rd drive lands
- **Future**: 3rd drive (Feb 2027) is the next real capacity increase

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

### Current (confirmed via DSM API, 2026-08-15 — see § DSM API Access)
- **Level 2 done**: SHR 1-disk redundancy (2nd drive added 2026-07) — protects against a single
  disk failure only; the mirror replicates deletions/corruption too, so it's not a substitute
  for the levels below.
- **The mini PC's Postgres DBs** (`ricota-db`, `media_tracker_db`, `jellystat-db` — the only
  genuinely irreplaceable, single-point-of-failure data in the homelab) are dumped daily to
  `/mnt/nas/Backups/postgres/` via `scripts/backup-postgres.sh` (host cron). See `TODO.md`.
- Seagate 4TB USB on mini PC as legacy copy of older media (itself unbacked-up, single disk,
  99% full — not currently usable as a Hyper Backup target without cleanup first)

### Still Pending
- **Level 1 — Btrfs snapshots**: confirmed **not configured** (`SYNO.Core.Share.Snapshot` on
  `Media` returns 0 snapshots) even though the `SnapshotReplication` package is installed.
  Planned policy: hourly keep 24, daily keep 7, weekly keep 4.
- **Level 3 — true offsite**: **Hyper Backup isn't installed at all** (confirmed via DSM
  package list). Would ship the (currently ~2MB) `/mnt/nas/Backups/postgres/` dumps to
  B2/Wasabi. Deliberately deprioritized — the one real single-point-of-failure risk (the
  Postgres DBs) is already covered by the item above, and this is a "do it properly
  eventually" layer on top, not urgent.

Redundancy (mirroring) protects against a single drive failing — it does **not** protect
against accidental deletion, ransomware, or Btrfs pool corruption. Snapshots + an actual
off-pool backup (Level 1/3 above) are the parts that still matter and haven't been verified
as configured.
