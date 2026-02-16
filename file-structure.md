# File Structure — Mini PC (homelab)

> Last updated: 2026-02-14

## `/home/matias/` — Home Directory

```
~/
├── Code/                          # All development projects
│   ├── cen-dashboard/             #   CEN dashboard (port 3003)
│   ├── get-images-cloudinary/     #   Cloudinary image tool
│   ├── media-tracker-api/         #   Media tracker backend
│   ├── media-tracker-db/          #   Media tracker DB (PostgreSQL, port 5432)
│   ├── reporteminoritario-transcript-fetcher/  # Podcast transcript AI
│   ├── scraper-autoentrada/       #   Ticket scraper bot
│   └── usa-2026/                  #   FIFA World Cup trip planner (port 3000)
├── homelab/                       # This repo — homelab documentation
├── Desktop/                       # Ubuntu defaults (unused, headless server)
├── Documents/
├── Downloads/
├── Games/
├── Music/
├── Pictures/
├── Public/
├── Templates/
└── Videos/
```

## `/opt/docker/` — Docker Infrastructure

```
/opt/docker/
├── docker-compose.yml             # Main homelab compose (25+ services)
├── docker-compose.yml.backup      # Backup from 2026-02-01
├── docker-compose.yml.old-backup  # Older backup
├── docker-compose-backup20jun25.yml  # Backup from 2025-06-20
├── ARR-MIGRATION-LOG.md           # Migration notes (LinuxServer → Hotio)
├── configs/                       # Per-service config directories
│   ├── bazarr/
│   ├── filebrowser/
│   ├── homarr/
│   ├── jackett/                   #   Legacy (replaced by Prowlarr)
│   ├── jellyfin/
│   ├── jellyseerr/
│   ├── lidarr/
│   ├── openclaw/                  #   OpenClaw AI agent (separate compose)
│   │   ├── docker-compose.yml     #     Hardened compose (localhost-only, read_only, cap_drop ALL)
│   │   ├── .env                   #     Gateway token (600 perms)
│   │   ├── data/                  #     OpenClaw persistent data (UID 1000)
│   │   ├── workspace/             #     Sandboxed workspace (UID 1000)
│   │   └── source/                #     Git clone of openclaw/openclaw
│   ├── opencloud/
│   ├── pihole/
│   ├── profilarr/
│   ├── prowlarr/
│   ├── qbittorrent/
│   ├── radarr/
│   ├── sonarr/
│   ├── unbound/
│   └── uptime-kuma/
├── data/                          # Service data (OpenCloud data moved to /mnt/opencloud)
├── backups/                       # Docker config backups
├── downloads/                     # Legacy download dir
└── filebrowser/                   # File Browser app data
```

## `/mnt/nas/` — NAS SMB Mount (Synology DS423 at 192.168.1.119)

```
/mnt/nas/
├── Peliculas/                     # Movies — Radarr root (4.3TB, ~1148 movies)
├── Series/                        # TV Shows — Sonarr root
├── Music/                         # Music — Lidarr root
├── downloads/                     # qBittorrent download directory
├── Libros/                        # Books
├── images/                        # Image storage
├── Google Drive 4-10-2024/        # Google Drive backup (278GB) — pending migration to OpenCloud
│   ├── Google Photos 20 octubre 2024/
│   ├── Samsung S23 Ultra/
│   ├── Photos/
│   ├── Viajes/
│   ├── USA 2024/
│   ├── Ocio/
│   ├── reporteminoritario.com/
│   └── ...
├── Backups/                       # Old device backups
│   ├── Backup logs before re processing september 18/  (5.7MB)
│   ├── Backup notebok vieja/      (183MB)
│   └── Backup notebook vieja teladoc 17 oct 2024/
└── #recycle/                      # Synology recycle bin
```

## `/mnt/nas-nfs/` — NAS NFS Mount (192.168.1.119:/volume1/Media)

```
/mnt/nas-nfs/
└── opencloud-data/
    └── opencloud.img              # ext4 image file for OpenCloud data
```

## `/mnt/opencloud/` — OpenCloud Data (loop mount)

```
/mnt/opencloud/                    # Loop mount of /mnt/nas-nfs/opencloud-data/opencloud.img (ext4)
└── (OpenCloud application data)   # Mapped to /var/lib/opencloud in container
```

## `/DATA/` — Seagate 4TB USB (Legacy)

```
/DATA/
├── Media/                         # Actual mount point (/dev/sda2, exFAT, 3.6TB/3.7TB = 99% full)
│   ├── Peliculas/                 #   Movies (legacy copy, ~2.9TB)
│   ├── Series/                    #   TV Shows (legacy copy, ~418GB)
│   ├── Music/
│   ├── Libros/
│   ├── Google Drive 4-10-2024/    #   Google Drive backup (282GB)
│   └── ...                        #   Various old backups and files
├── AppData/                       # Empty (4KB)
├── Documents/                     # Small files (35MB)
├── Downloads/                     # Small files (6MB)
└── Gallery/                       # Empty (16KB)
```

## `/opt/` — Other System Directories

```
/opt/
├── docker/         # See above
├── containerd/     # Container runtime
├── filebrowser/    # File Browser app
└── images/         # Shared image dir (Nextcloud + image-server container)
```
