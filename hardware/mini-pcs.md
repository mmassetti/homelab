# Mini PC — Beelink SER8

## Specs

- **Model**: Beelink SER8 (8845HS variant)
- **Hostname**: `homelab`
- **CPU**: AMD Ryzen 7 8745HS — 8 cores / 16 threads, 3.8 GHz base / 5.1 GHz boost, 16MB L3, 45W TDP
- **GPU**: AMD Radeon 780M integrated (12 CU, RDNA 3) — used for Jellyfin hardware transcoding and light AI (Ollama)
- **RAM**: 32GB DDR5 5600MHz (2x16GB dual channel, upgradeable to 64GB)
- **Storage**: 931.5GB NVMe (LVM: `ubuntu--vg-ubuntu--lv`, ext4, mounted at `/`)
- **External Storage**: Seagate 4TB USB 3.0 — `/dev/sda2`, exFAT, mounted at `/DATA/Media` (99% full, legacy media storage)
- **Network**: 2x 2.5GbE (using `enp1s0`), WiFi 6E (unused), Bluetooth 5.2
- **IP**: 192.168.1.239 (static via DHCP — default route metric 100)
- **Tailscale IP**: 100.118.87.121
- **OS**: Ubuntu Server 24.04.2 LTS (Noble Numbat), kernel 6.8.0-94-generic
- **Power**: ~30-50W typical, ~70W max, runs 24/7
- **Location**: Office, headless

## Key System Services

- Docker (all containers)
- CasaOS (6 services: main, gateway, app-management, local-storage, message-bus, user-service)
- Tailscale (node agent)
- SSH (OpenBSD Secure Shell)
- cron

## Storage Layout

```
nvme0n1           931.5G
├── nvme0n1p1       1G   /boot/efi  (vfat)
├── nvme0n1p2       2G   /boot      (ext4)
└── nvme0n1p3     928.5G LVM
    └── ubuntu--vg-ubuntu--lv  928.5G  /  (ext4)

sda               3.6T   (Seagate 4TB USB)
├── sda1          200M   (vfat, unused)
└── sda2          3.6T   /DATA/Media (exfat, UUID=AC85-7883)

/mnt/nas-nfs/                    NFS mount (192.168.1.119:/volume1/Media)
└── opencloud-data/
    └── opencloud.img            ext4 image file

/mnt/opencloud/                  Loop mount of opencloud.img (ext4)
```

## Performance Notes

- Capable of 3-4 simultaneous 4K transcodes
- 25+ Docker containers running
- Ollama for local LLM inference (uses iGPU)
