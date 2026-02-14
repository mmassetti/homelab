# Matias's Complete Homelab Knowledge Base - ULTIMATE EDITION
**Created:** December 26, 2025  
**Updated:** December 26, 2025 11:45 PM ART (Post-Discovery & Cleanup)  
**Status:** Ready for NAS Setup (January 2026)  
**Purpose:** Complete master reference for personal LLM training

---

## EXECUTIVE SUMMARY

### Current Status (Dec 26, 2025)
```
Disk Space:    59GB free (was 40GB) âœ…
Cleanup Done:  19GB freed from corrupted show
Services:      17 containers running + 4 dev projects discovered
Network:       Stable, Cloudflare tunnel active
Ready for:     January 2026 NAS deployment
Days Until:    16 days to USA trip (Jan 11, 2026)
```

### Critical Updates from Discovery
- âœ… Found actual file structure (/DATA/Media with symlinks)
- âœ… Discovered 4 development projects (including Ollama!)
- âœ… Verified network configuration
- âœ… Cleaned up 19GB (deleted corrupted TV show)
- âœ… Found 282GB Google Drive backup
- âœ… Confirmed no Tailscale (using Cloudflare only)
- âœ… CasaOS actively running

---

## QUICK REFERENCE - KEY INFORMATION

### Network
- **Public IP:** 190.97.55.99 (dynamic)
- **Local Network:** 192.168.1.0/24
- **Router IP:** 192.168.1.1
- **Router MAC:** EC-75-0C-04-16-24
- **WiFi SSID:** Matias (2.4GHz + 5GHz)
- **Internet Speed:** 300 Mbps down / ~30-50 Mbps up (estimated)
- **ISP:** Unknown provider (Argentina)

### Main Devices
- **Mini PC (Homelab Server):** 192.168.1.239 - Beelink SER8
- **Gaming PC:** Dynamic DHCP - AMD Ryzen 5 2600
- **NAS (Future - Jan 2026):** 192.168.1.240 (planned) - Synology DS423
- **Router:** 192.168.1.1 - TP-Link Archer AX55
- **ISP Modem:** I-CON IC455WDB (bridge mode)

### Personal Devices
- **Phone:** Samsung Galaxy S23 Ultra
- **Laptop:** MacBook M4 Pro
- **Gaming Console:** Xbox Series S
- **Media Devices:** NVIDIA Shield Pro TV, Chromecast
- **Display:** BenQ X3000i 4K Projector + Regular TV
- **Audio:** Samsung HW-Q605C Soundbar

### Domain & DNS
- **Domain:** matiasmassetti.com
- **Registrar:** Porkbun
- **DNS:** Cloudflare
- **Services:** Cloudflare Tunnels for external access
- **VPN:** None (clarified - no Tailscale, just Cloudflare)

---

## SECTION 1: COMPLETE HARDWARE INVENTORY

### 1.1 Mini PC (Homelab Server) - "homelab"

**Model:** Beelink SER8 (8845HS variant)

**Specifications:**
- **CPU:** AMD Ryzen 7 8745HS
  - 8 cores, 16 threads
  - Base: 3.8 GHz, Boost: 5.1 GHz
  - 16MB L3 cache
  - TDP: 45W (configurable 35-54W)
- **RAM:** 32GB DDR5 5600MHz
  - Dual channel (2x 16GB)
  - Upgradeable to 64GB max
- **GPU:** AMD Radeon 780M (integrated)
  - 12 compute units
  - RDNA 3 architecture
  - Good for light AI workloads (Ollama!)
  - Hardware video encoding/decoding
- **Storage:**
  - Internal NVMe: 913GB usable (~931GB total)
  - External: Seagate 4TB USB 3.0
- **Networking:**
  - 2x 2.5 Gigabit Ethernet (using 1, other available)
  - WiFi 6E (not in use, ethernet preferred)
  - Bluetooth 5.2
- **OS:** Ubuntu Server 24.04 LTS
- **Kernel:** Linux 6.x
- **Hostname:** homelab
- **IP Address:** 192.168.1.239 (static)
- **MAC Address:** 70:70:fc:08:0a:b3
- **Location:** Office
- **Power:** ~30-50W typical, ~70W max
- **Uptime:** 24/7

**Current Storage Usage (Verified Dec 26):**
```
Internal NVMe (913GB):
- OS & system: ~50GB
- Docker configs: ~20GB (/opt/docker/configs)
- Docker images: ~8GB
- Downloads: ~4KB (empty, cleaned)
- Projects: Unknown size
- Free space: ~660GB

External Drive (3.7TB total):
- Mount: /DATA/Media
- Used: 3.6TB (99%)
- Free: 59GB (after cleanup)
- Movies: 2.9TB (/DATA/Media/Peliculas)
- TV Shows: 418GB (/DATA/Media/Series)
- Google Drive Backup: 282GB
- Other: ~150GB (books, backups, etc.)
```

**Connections:**
- Ethernet (enp1s0) â†’ Office â†’ Router
- USB 3.0 â†’ Seagate 4TB external drive (/dev/sda2)
- Power â†’ Argentina outlet (220V, 50Hz)
- No monitor (headless server)

**Performance:**
- Can handle 3-4 simultaneous 4K transcodes (Jellyfin)
- Excellent for Docker (runs 17+ containers easily)
- Good for AI (Ollama running)
- Fast NVMe storage (good for databases)

---

### 1.2 Gaming PC

**Custom Built:** 2018 (almost 7 years old)

**Specifications:**
- **CPU:** AMD Ryzen 5 2600
  - 6 cores, 12 threads
  - 3.4 GHz base, 3.9 GHz boost
  - 16MB L3 cache
  - AM4 socket (Zen+ architecture)
- **GPU:** Sapphire RX 570 Nitro+ 8GB
  - Polaris architecture (2017)
  - 8GB GDDR5
  - Good for 1080p gaming
  - 2048 stream processors
- **RAM:** 16GB (2x 8GB) DDR4 2400MHz
  - Kingston HyperX Fury
  - Dual channel
- **Storage:**
  - **SSD:** 240GB WD Green SATA III (C: drive)
    - OS: Windows 10
    - Programs
    - Used: ~217GB
    - Free: ~20GB (LOW! Needs cleanup)
  - **HDD:** 1TB Western Digital SATA III
    - 7200 RPM
    - 64MB cache
    - Used: ~847GB
    - Free: ~84GB
  - **External:** Sony HD-E1 1TB USB
    - Used: ~1.81TB (wait, this doesn't match 1TB?)
    - Connected for media storage
- **OS:** Windows 10
- **IP Address:** Dynamic DHCP (192.168.1.x range)
- **Location:** Office
- **Monitors:** 2 monitors (models unknown)

**Current Usage:**
- Gaming: Counter-Strike: Global Offensive, Call of Duty Warzone (not much lately)
- Development: Some coding (before MacBook)
- Downloads: Torrent client (manual workflow)
- Media: Connected to 1TB Sony external drive

**Network:**
- Connection: Ethernet or WiFi (unknown)
- IP: Dynamic DHCP

**Notes:**
- Aging hardware (7 years old)
- C: drive almost full (needs cleanup!)
- Could be repurposed for:
  - Dedicated gaming server
  - Secondary compute node
  - Backup server
  - Folding@Home / distributed computing
  - Parts donor for future upgrades

**Future Considerations:**
- GPU upgrade would breathe new life
- Add SSD for games
- More RAM if returning to heavy gaming
- Or keep as is for light gaming

---

### 1.3 Future NAS - Synology DS423 (Purchase Jan 2026)

**Planned Purchase:** January 11, 2026 (USA trip)

**Model:** Synology DS423 (4-bay, diskless)
- **Price:** $379.99 (Amazon.com)

**Specifications:**
- **CPU:** Realtek RTD1619B
  - Quad-core ARM 1.7 GHz
  - 64-bit processor
  - Not powerful, but perfect for NAS duties
- **RAM:** 2GB DDR4 (non-ECC)
  - Expandable to 6GB via SO-DIMM slot
  - Sufficient for file serving + light apps
- **Drive Bays:** 4x 3.5" or 2.5" SATA
  - Hot-swappable
  - Tool-less design
  - Support up to 18TB per drive (72TB total)
- **Network:** 2x Gigabit Ethernet (1GbE)
  - Bondable for 2Gbps throughput
  - Link aggregation support
- **USB Ports:** 3x USB 3.2 Gen 1
  - For external backup drives
  - For UPS
  - For expansion
- **eSATA:** 2x ports
  - For expansion units
- **Max Internal Capacity:** 72TB (4x 18TB drives)
- **Hot-swappable:** Yes
- **OS:** DSM 7.x (Synology DiskStation Manager)
- **No Drive Lock-in:** Can use any SATA drives âœ…

**Planned Drive Configuration:**

**Phase 1 (January 2026):**
- **Drives:** 4x WD Red Pro 14TB
- **Model:** WD142KFGX (SAVE THIS MODEL NUMBER!)
- **Price:** $289.99 each Ã— 4 = $1,159.96
- **Speed:** 7200 RPM (faster than WD Red 5400 RPM)
- **Cache:** 512MB
- **Warranty:** 5 years
- **Technology:** CMR (not SMR - better for NAS)
- **Workload:** 300TB/year rated
- **Configuration:** SHR (Synology Hybrid RAID)
- **Usable Capacity:** 38TB (with 1-disk redundancy)
- **Protection:** 1 drive can fail safely

**Why WD Red Pro 14TB:**
- Better price per TB than 12TB ($20.71/TB vs $25/TB)
- 7200 RPM = faster performance
- CMR technology = better for RAID
- 5-year warranty vs 3-year
- Higher workload rating
- Same physical size

**Alternative Considered (Rejected):**
- 2 drives now, 2 later: Same total cost, no redundancy initially
- 12TB drives: More expensive per TB
- WD Red Plus: Slower (5400 RPM)

**Network Configuration:**
- **IP Address:** 192.168.1.240 (static, planned)
- **Hostname:** homelab-nas or matias-nas
- **Gateway:** 192.168.1.1
- **DNS:** 1.1.1.1, 1.0.0.1 (Cloudflare)
- **Protocol:** NFS primary (faster), SMB secondary (compatibility)
- **Mount on Mini PC:** /mnt/nas
- **Access:** DSM web interface (https://192.168.1.240:5001)

**Planned Folder Structure:**
```
/volume1/
  â”œâ”€â”€ Media/
  â”‚   â”œâ”€â”€ Peliculas/      (Movies - 4K/1080p)
  â”‚   â”œâ”€â”€ Series/         (TV Shows)
  â”‚   â”œâ”€â”€ Audiobooks/     (Future)
  â”‚   â”œâ”€â”€ Podcasts/       (Future)
  â”‚   â””â”€â”€ Music/          (Future)
  â”œâ”€â”€ Documents/          (Paperless-ngx)
  â”œâ”€â”€ Photos/             (Photoprism/Immich)
  â”œâ”€â”€ Backups/
  â”‚   â”œâ”€â”€ MiniPC/         (Docker configs, system)
  â”‚   â”œâ”€â”€ Gaming PC/      (important files)
  â”‚   â””â”€â”€ MacBook/        (Time Machine or rsync)
  â””â”€â”€ Projects/           (Development code)
```

**Location:** Office (next to mini PC)
**Power:** ~20W idle, ~30W under load (very efficient!)
**Noise:** Quiet (good for office environment)

**Backup Strategy:**
- **Level 1:** Btrfs snapshots (automatic, hourly/daily)
- **Level 2:** SHR redundancy (1 disk can fail)
- **Level 3:** External USB drive via Hyper Backup (weekly)
- **3-2-1 Rule:** 3 copies, 2 media types, 1 offsite (future)

**Accessories to Buy:**
- TP-Link TL-SG105 switch: $12.99
- Cat6 cables 5-pack (3ft): $12.49
- Argentina power adapter 2-pack: $6.99

**Total Investment:** $1,587.42

---

### 1.4 Xbox Series S

**Model:** Xbox Series S 1TB SSD edition

**Specifications:**
- **CPU:** Custom AMD Zen 2
  - 8 cores @ 3.6GHz (3.4GHz with SMT)
  - 7nm process
- **GPU:** Custom AMD RDNA 2
  - 4 TFLOPS
  - 20 compute units @ 1.565 GHz
  - DirectX 12 Ultimate support
- **RAM:** 10GB GDDR6
  - 8GB @ 224 GB/s (GPU)
  - 2GB @ 56 GB/s (CPU, I/O)
- **Storage:** 1TB NVMe SSD (internal)
  - ~802GB usable
  - Expandable via Seagate expansion card
- **Max Resolution:** 1440p native
  - Upscaled to 4K
  - Up to 120 FPS support
- **HDR:** Yes (HDR10)
- **Ray Tracing:** Yes (limited compared to Series X)
- **Optical Drive:** None (digital only)

**Network:**
- **Connection:** WiFi (Matias 5GHz network preferred)
- **IP:** Dynamic DHCP
- **Wired Option:** Ethernet available

**Connections:**
- **Video:** HDMI 2.1 â†’ BenQ X3000i projector
- **Audio:** HDMI ARC â†’ Samsung HW-Q605C soundbar
  - Or direct to soundbar
  - Dolby Atmos support
- **Power:** AC adapter (external brick)

**Location:** Living room

**Usage:**
- Gaming console (Game Pass library)
- Media apps (Netflix, YouTube, Disney+, HBO Max)
- Streaming (via apps)
- Game Pass cloud gaming

**Game Library:**
- Subscription: Xbox Game Pass Ultimate
- Storage: Manage via Xbox app
- Downloads: Pause during peak Jellyfin usage

**Notes:**
- All-digital (no disc drive)
- Compact and quiet
- Good for 1080p/1440p gaming
- Perfect for casual gaming
- Shares projector with Shield Pro TV

---

### 1.5 NVIDIA Shield Pro TV

**Model:** NVIDIA Shield Pro (2019 or newer)

**Specifications:**
- **CPU:** Tegra X1+ (ARM-based)
  - 256-core NVIDIA Maxwell GPU
  - 3GB RAM
- **Storage:** 16GB internal
  - Expandable via USB or microSD
- **OS:** Android TV (updates to Google TV)
- **AI Upscaling:** Yes (4K upscaling)
  - AI-enhanced upscaling of HD content
  - Looks better than native 4K on some content
- **Dolby Vision:** Yes
- **Dolby Atmos:** Yes
- **HDR10:** Yes

**Network:**
- **Connection:** Ethernet (preferred) OR WiFi
- **IP:** Dynamic DHCP
- **Speed:** Gigabit ethernet or WiFi 6

**Apps & Usage (Primary Media Center):**
- **Jellyfin:** Native app (preferred)
  - Direct play 4K HDR content
  - Excellent client performance
  - Hardware transcoding support
- **Woolphin:** Alternative media player
- **Netflix:** 4K, Dolby Vision, Atmos
- **YouTube:** 4K HDR
- **Flow:** Local Argentine TV streaming
- **MagisTV:** IPTV service
- **Kick:** Streaming platform
- **Steam Link:** Game streaming (experimental, tested once)
  - Can stream from Gaming PC
  - Low latency on local network

**Connections:**
- **Video:** HDMI 2.0b â†’ Projector or TV
- **Audio:** HDMI ARC â†’ Samsung soundbar
- **Network:** Ethernet (recommended for 4K)
- **Power:** USB-C power adapter

**Location:** Living room (near projector/TV)

**Why It's Great:**
- Best Android TV device available
- Handles 4K HDR + Atmos perfectly
- AI upscaling improves quality
- Fast interface (no lag)
- Regular updates from NVIDIA
- Plex/Jellyfin native apps work great

**Jellyfin Performance:**
- Direct Play: 4K HEVC, HDR10, Atmos âœ…
- Transcoding: Rarely needed
- Subtitle support: Excellent
- Remote control: Works perfectly

**Notes:**
- Primary device for media consumption
- Used almost daily
- Connected to projector for best experience
- Also works with regular TV as backup

---

### 1.6 Chromecast

**Model:** Chromecast with Google TV (assumed - not confirmed)

**Specifications (if 4K model):**
- **CPU:** ARM-based (Amlogic S905X3)
- **RAM:** 2GB
- **Storage:** 8GB internal
- **OS:** Google TV (Android TV based)
- **Max Resolution:** 4K (if 4K model) or 1080p

**Network:**
- **Connection:** WiFi only (no ethernet)
- **IP:** Dynamic DHCP
- **Band:** 2.4GHz + 5GHz

**Usage:**
- **Primary Use:** Daytime viewing
  - Projector can't be used in daylight
  - Regular TV instead
- **Apps:** Same as Shield but lighter usage
  - Jellyfin (works, not as smooth as Shield)
  - YouTube
  - Flow (Argentine local TV)
  - MagisTV

**Connections:**
- **Video:** HDMI â†’ Regular TV
- **Power:** USB (from TV or wall adapter)
- **Audio:** Through TV speakers or soundbar

**Location:** Living room (regular TV)

**Notes:**
- Secondary to Shield Pro
- Used when projector unavailable
- Less intensive usage pattern
- More casual viewing
- Smaller, simpler device

**Limitations vs Shield:**
- WiFi only (no ethernet option)
- Less powerful processor
- Smaller storage
- No AI upscaling
- But good enough for HD content!

---

### 1.7 BenQ X3000i Projector

**Model:** BenQ X3000i (4K Gaming Projector)

**Specifications:**
- **Resolution:** 4K UHD (3840Ã—2160)
  - Native 4K DLP chip
  - True 4K, not pixel-shifted
- **Brightness:** 3000 ANSI lumens
  - Good for dark rooms
  - Minimal ambient light tolerance
- **Technology:** DLP (Digital Light Processing)
  - Single-chip DLP
  - Texas Instruments chipset
- **Contrast:** 500,000:1 (dynamic)
- **Throw Ratio:** 1.13-1.47
  - Short throw (good for small rooms)
  - 100" screen from ~8.2-10.7 feet
- **Lamp Life:** Up to 20,000 hours (economy mode)
- **Refresh Rate:**
  - Up to 240Hz @ 1080p
  - 60Hz @ 4K
  - 120Hz @ 1440p
- **HDR:** HDR10, HLG
- **Game Mode:** 4ms response time @ 1080p 240Hz
  - 16ms @ 4K 60Hz
  - Excellent for gaming
- **Audio:** Built-in speakers (2x 5W)
  - But using external soundbar

**Connections:**
- **HDMI 1:** Xbox Series S (gaming + media)
- **HDMI 2:** NVIDIA Shield Pro TV (media)
- **Audio Out:** Optical to Samsung soundbar
- **USB:** For firmware updates
- **Power:** 220V AC

**Picture Modes:**
- Cinema (for movies)
- Gaming (low latency)
- Sport
- User (custom calibrated)

**Location:** Living room (ceiling mounted or on stand)

**Usage:**
- Primary display for gaming (Xbox)
- Primary display for media (Shield Pro)
- Evening/night use only (requires darkness)
- Movies, TV shows, sports
- Gaming sessions

**Screen Size:** ~100-120" diagonal (estimated)

**Why It's Great:**
- True 4K resolution
- Excellent for gaming (low latency)
- HDR support
- Large screen experience
- Good brightness for projector
- Quiet operation

**Limitations:**
- Requires dark room
- Can't use during daytime
- Lamp replacement eventually needed
- More complex than TV

**Notes:**
- Significantly better experience than TV for media
- Gaming on 100"+ screen is incredible
- Shares inputs with Shield and Xbox
- Input switching via remote

---

### 1.8 Samsung HW-Q605C Soundbar

**Model:** Samsung HW-Q605C

**Specifications:**
- **Type:** 3.1.2 channel soundbar with wireless subwoofer
- **Dolby Atmos:** Yes
  - Height channels for overhead sound
  - Immersive 3D audio
- **DTS:X:** Yes
  - Alternative 3D audio format
- **Total Power:** ~360W (estimated)
- **Channels:**
  - 3 front channels (L, C, R)
  - 2 height channels (up-firing)
  - 1 subwoofer (wireless)

**Wireless Subwoofer:**
- Included
- Wireless connection to soundbar
- Bass extension

**Connections:**
- **HDMI ARC/eARC:** From TV/Projector
  - Single cable for audio + control
  - Supports Atmos passthrough
- **Optical:** Alternative connection
- **Bluetooth:** For music streaming from phone
- **WiFi:** For Samsung app control (if supported)

**Location:** Living room (under projector screen or TV)

**Usage:**
- Movies with Dolby Atmos (Jellyfin content)
- Gaming audio from Xbox
- Music streaming via Bluetooth
- TV shows and YouTube

**Audio Formats Supported:**
- Dolby Atmos âœ…
- Dolby Digital Plus âœ…
- DTS:X âœ…
- PCM âœ…
- AAC âœ…

**Sources:**
- Xbox Series S â†’ HDMI â†’ Soundbar
- Shield Pro TV â†’ HDMI â†’ Soundbar
- Phone â†’ Bluetooth â†’ Soundbar
- TV â†’ ARC â†’ Soundbar

**Why It's Great:**
- Dolby Atmos for immersive audio
- Much better than TV speakers
- Wireless subwoofer (no cables)
- Height channels (up-firing)
- Compact design

**Notes:**
- Connects to projector via HDMI ARC
- All sources route through projector to soundbar
- Enhances both movies and gaming
- Good value for Atmos-enabled soundbar

---

### 1.9 MacBook M4 Pro

**Model:** MacBook Pro with M4 Pro chip (2024)

**Specifications (Estimated):**
- **Chip:** Apple M4 Pro
  - ARM-based Apple Silicon
  - CPU cores: 12-14 (performance + efficiency)
  - GPU cores: 18-20
  - Neural Engine: 16-core
- **RAM:** 24GB or 36GB unified memory (estimated)
  - Shared between CPU/GPU
  - LPDDR5X
- **Storage:** 512GB - 2TB SSD (estimated)
  - Very fast NVMe
- **Display:** 14" or 16" Liquid Retina XDR
  - Mini-LED with HDR
  - ProMotion (120Hz)
- **Ports:**
  - 3x Thunderbolt 4 / USB-C
  - HDMI
  - SD card slot
  - MagSafe 3 charging
  - Headphone jack
- **OS:** macOS Sequoia (latest)
- **Battery:** All-day battery life

**Network:**
- **WiFi:** WiFi 6E
  - Connects to "Matias" network
  - 5GHz preferred
- **Ethernet:** Via USB-C adapter (when needed)
- **Bluetooth:** 5.3

**Usage (Primary Work Machine):**
- **Development:**
  - Frontend development (React, TypeScript)
  - Backend development (Node.js, Python)
  - Telegram bot development
  - Web scraping projects
  - Full-stack applications
- **Tools:**
  - VS Code (primary IDE)
  - Terminal (iTerm2 or default)
  - Docker Desktop (local testing)
  - Git (version control)
  - SSH to homelab
- **Work:**
  - Healthcare applications
  - Professional projects
  - Code reviews
  - Documentation
- **General:**
  - Web browsing
  - Media consumption
  - Communication (Slack, email)

**Homelab Access:**
- SSH to mini PC: `ssh matias@192.168.1.239`
- Jellyfin web: https://media.matiasmassetti.com
- All services via Cloudflare tunnels
- Local network access when home
- Tailscale VPN when away (future, if installed)

**Development Workflow:**
- Code on MacBook
- Git push to GitHub
- Deploy to homelab via SSH or automation
- Test on mini PC
- Access via browser

**Why It's Great:**
- Extremely fast (M4 Pro chip)
- Long battery life
- Excellent display
- Perfect for development
- macOS ecosystem
- Can run Docker locally

**Notes:**
- Replaced Gaming PC for development
- Much more portable
- Better for work
- Syncs with iPhone via iCloud
- Homebrew for package management

---

### 1.10 Samsung Galaxy S23 Ultra

**Model:** Samsung Galaxy S23 Ultra

**Specifications:**
- **Display:** 6.8" Dynamic AMOLED 2X
  - 3088 x 1440 (QHD+)
  - 120Hz adaptive refresh rate
  - Gorilla Glass Victus 2
- **Processor:** Snapdragon 8 Gen 2 (for Galaxy)
  - 3.36 GHz peak clock
  - 4nm process
  - Custom binned chip (faster than standard)
- **RAM:** 8GB or 12GB (likely 12GB)
- **Storage:** 256GB, 512GB, or 1TB (unknown which)
- **Camera:**
  - Main: 200MP wide
  - Telephoto: 10MP 3x optical
  - Periscope: 10MP 10x optical
  - Ultrawide: 12MP
  - Front: 12MP
- **S Pen:** Yes (built-in, no charging needed)
  - Bluetooth enabled
  - 4096 pressure levels
  - Low latency
- **Battery:** 5000 mAh
  - 45W fast charging
  - 15W wireless
  - Reverse wireless charging
- **5G:** Yes
- **OS:** Android 14 (One UI 6)

**Network:**
- **WiFi:** WiFi 6E
  - Connects to "Matias" 5GHz
- **Mobile:** 4G/5G (Argentine carrier)
- **Bluetooth:** 5.3

**Usage:**
- **Primary phone** for everything
- **Homelab Access:**
  - Jellyseerr app (request movies/shows)
  - Jellyfin app (watch content remotely)
  - SSH via Termux (if needed)
  - All services via browser
  - Cloudflare tunnel access
- **Communication:**
  - Telegram (primary messaging)
  - WhatsApp
  - Email (work + personal)
  - Slack (work)
- **Media:**
  - Photography (excellent cameras)
  - Video recording (4K/8K)
  - Photo editing
  - Content creation
- **Productivity:**
  - Notes (Samsung Notes with S Pen)
  - Tasks/Calendar
  - Document reading
  - PDF annotation with S Pen

**Homelab Integration:**
- Request content via Jellyseerr
- Watch Jellyfin anywhere
- Receive notifications (Uptime Kuma, n8n future)
- Remote control of services
- SSH in emergencies

**Why It's Great:**
- Excellent cameras (200MP main!)
- S Pen for notes/drawing
- Large beautiful display
- Long battery life
- Fast performance
- Seamless homelab access

**Notes:**
- Daily driver phone
- Connects to all homelab services
- Great for photography
- S Pen is unique feature
- 5G for fast mobile access

---

### 1.11 External Storage Devices

**Sony HD-E1 (1TB):**
- **Capacity:** 1TB (actual capacity unclear from discovery)
- **Connection:** USB 3.0
- **Currently:** Connected to Gaming PC
- **Contents:** Movies, TV shows, general data
- **Usage:** Discovery showed ~1.81TB used (this doesn't match 1TB capacity - may be reading error or it's larger)
- **Status:** In use on Gaming PC

**Sony HD-EG5 (500GB):**
- **Capacity:** 500GB
- **Connection:** USB 2.0 or 3.0
- **Currently:** Not connected (stored away)
- **Contents:** Old backups from the past
- **Usage:** Almost full
- **Status:** Archive drive, rarely accessed

**Seagate 4TB (Primary External Drive):**
- **Capacity:** 4TB (3.7TB formatted)
- **Model:** Unknown exact model
- **Connection:** USB 3.0
- **Currently:** Connected to Mini PC 24/7
- **Device:** /dev/sda2
- **UUID:** AC85-7883
- **Filesystem:** exFAT
- **Mount Point:** /DATA/Media
- **Auto-mount:** Yes (via /etc/fstab)
- **Mount Options:** `uid=1000,gid=1000,umask=000,defaults`

**Current Usage (Dec 26, 2025):**
```
Total:                  3.7TB
Used:                   3.6TB (99%)
Free:                   59GB (after cleanup)

Breakdown:
- Movies (Peliculas):   2.9TB
- TV Shows (Series):    418GB (after deleting corrupted show)
- Google Drive Backup:  282GB (Oct 4, 2024 backup)
- Books (Libros):       Unknown
- Music:                Unknown
- Backups:              ~241MB total
  - Backup logs:        56MB
  - Backup notebook:    185MB
- System files:         ~1MB
- Recycle bin:          512KB (emptied)
```

**Future Plans:**
- **After NAS Migration:**
  - Disconnect from mini PC
  - Connect to NAS USB port
  - Use for Hyper Backup (NAS â†’ USB weekly)
  - Implements 3-2-1 backup strategy
  - Keeps all media safe

**Note on Storage Confusion:**
- Discovery showed some conflicting sizes
- Main concern: Seagate 4TB is 99% full
- Sony HD-E1 capacity unclear (1TB listed but shows more used?)
- Should verify exact models and capacities

---

## SECTION 2: NETWORK INFRASTRUCTURE (VERIFIED)

### 2.1 Network Topology

**Current Setup:**
```
Internet (300 Mbps) via ISP
        â”‚
        â†“
I-CON IC455WDB ISP Modem/Router
[Bridge Mode - Routing DISABLED]
        â”‚
        â†“
TP-Link Archer AX55 Main Router
[192.168.1.1 - DHCP Server]
        â”‚
        â”œâ”€â”€â”€ WiFi "Matias" (2.4GHz + 5GHz)
        â”‚     â”œâ”€â”€â”€ Galaxy S23 Ultra (WiFi)
        â”‚     â”œâ”€â”€â”€ MacBook M4 Pro (WiFi)
        â”‚     â”œâ”€â”€â”€ Xbox Series S (WiFi)
        â”‚     â”œâ”€â”€â”€ Chromecast (WiFi)
        â”‚     â””â”€â”€â”€ Shield Pro TV (WiFi or Ethernet?)
        â”‚
        â””â”€â”€â”€ Ethernet cables to Office
              â”‚
              â”œâ”€â”€â”€ Cable 1 â†’ Mini PC (192.168.1.239)
              â””â”€â”€â”€ Cable 2 â†’ Gaming PC (DHCP)

Future Setup (with TP-Link Switch - Jan 2026):
              â”‚
              â””â”€â”€â”€ Ethernet to Office
                   â”‚
                   â†“
              TP-Link TL-SG105 (5-Port Gigabit Switch)
              [Plug-and-play, unmanaged]
                   â”‚
                   â”œâ”€â”€â”€ Port 1 â†’ Router uplink
                   â”œâ”€â”€â”€ Port 2 â†’ Mini PC (192.168.1.239)
                   â”œâ”€â”€â”€ Port 3 â†’ Gaming PC (DHCP)
                   â”œâ”€â”€â”€ Port 4 â†’ NAS (192.168.1.240)
                   â””â”€â”€â”€ Port 5 â†’ Available for future
```

**Benefits of Switch:**
- Solves office ethernet port limitation
- All devices get full Gigabit speed
- No slowdown (non-blocking switch)
- Clean cable management
- Room for expansion

---

### 2.2 ISP Modem - I-CON IC455WDB

**Model:** I-CON IC455WDB

**Configuration:**
- **Mode:** Bridge Mode âœ…
- **Routing:** DISABLED
- **DHCP:** DISABLED
- **WiFi:** DISABLED
- **Function:** Pure modem only
  - Converts ISP signal (fiber/cable) to ethernet
  - Passes connection directly to Archer AX55
  - No configuration needed from user side

**Management:**
- Managed by ISP
- No user interface access (usually)
- ISP handles firmware updates

**Location:** Living room (with main router)

**Connection:**
- WAN port â†’ ISP line (fiber or cable)
- LAN port â†’ Archer AX55 WAN port

**Why Bridge Mode:**
- Archer AX55 handles all routing
- Better performance
- More control over network
- Avoids double NAT issues
- Router gets public IP directly

---

### 2.3 Main Router - TP-Link Archer AX55

**Model:** TP-Link Archer AX55 (AX3000 WiFi 6 Router)

**Specifications:**
- **WiFi Standard:** Wi-Fi 6 (802.11ax)
- **Total Speed:** AX3000
  - 2.4GHz: 574 Mbps (802.11ax)
  - 5GHz: 2402 Mbps (802.11ax)
- **Antennas:** 4 external high-gain antennas
- **Ethernet Ports:**
  - 1x Gigabit WAN (to ISP modem)
  - 4x Gigabit LAN (to devices)
- **CPU:** Triple-core processor
- **MU-MIMO:** Yes (4x4)
- **OFDMA:** Yes (reduces latency)
- **Beamforming:** Yes (improves WiFi coverage)
- **Parental Controls:** Yes (via Tether app)
- **QoS:** Yes (prioritize traffic)

**Network Configuration:**
- **IP Address:** 192.168.1.1
- **MAC Address:** EC-75-0C-04-16-24
- **Subnet Mask:** 255.255.255.0 (/24)
- **DHCP Range:** 192.168.1.100 - 192.168.1.199 (assumed)
- **DNS Servers:** 1.1.1.1, 1.0.0.1 (Cloudflare, recommended)
- **Gateway:** 192.168.1.1 (self)

**WiFi Configuration:**
- **SSID:** Matias
- **Dual Band:** Both 2.4GHz and 5GHz use same SSID
  - Band steering enabled (devices choose best band)
  - Smart Connect
- **Security:** WPA3 or WPA2-PSK (assumed WPA2/WPA3 mixed)
- **Password:** [User knows, not stored here]
- **Channel:** Auto (or manually optimized)

**Management:**
- **Mobile App:** TP-Link Tether (iOS/Android)
  - Remote management
  - Guest network
  - Parental controls
  - Device management
  - Speed test
- **Web Interface:** http://192.168.1.1 or http://tplinkwifi.net
- **Default Login:** admin/admin (hopefully changed!)
- **User knows credentials**

**Location:** Living room (central location for WiFi coverage)

**Wired Connections:**
- LAN 1 â†’ Mini PC (office)
- LAN 2 â†’ Gaming PC (office)
- LAN 3-4 â†’ Available (or one goes to living room devices?)

**Features in Use:**
- Router mode (not AP mode) âœ…
- DHCP server âœ…
- NAT âœ…
- Firewall âœ…
- WiFi 6 for compatible devices âœ…
- QoS (if enabled)
- Guest network (if enabled)

**Performance:**
- Handles 300 Mbps WAN easily
- Multiple simultaneous 4K streams
- Low latency gaming
- Stable 24/7 uptime
- Good WiFi coverage (4 antennas)

**Future Considerations:**
- 2.5GbE or 10GbE router if internet upgraded
- WiFi 6E or WiFi 7 in distant future
- But current router is excellent for now âœ…

---

### 2.4 Future Network Switch - TP-Link TL-SG105

**Model:** TP-Link TL-SG105 (5-Port Gigabit Unmanaged Switch)

**Specifications:**
- **Ports:** 5x 10/100/1000 Mbps Gigabit Ethernet
- **Type:** Unmanaged (plug-and-play)
- **Switching Capacity:** 10 Gbps (non-blocking)
- **Forwarding Rate:** 7.44 Mpps
- **MAC Address Table:** 2K entries
- **Jumbo Frames:** Up to 16KB
- **Features:**
  - Auto MDI/MDIX (no crossover cables needed)
  - Auto-negotiation (speed and duplex)
  - IEEE 802.3x flow control
  - Full-duplex on all ports
  - Store-and-forward switching
- **Power:** External power adapter (included)
- **Fanless:** Yes (completely silent) âœ…
- **Metal Case:** Yes (good for heat dissipation)
- **Desktop:** Yes (compact size)

**Planned Purchase:** January 2026
**Price:** $12.99
**Where:** Amazon.com (USA)

**Purpose:**
- Connect mini PC + gaming PC + NAS in office
- Only 1 ethernet cable from router to office currently
- Switch allows 3+ devices on that single cable
- All devices get full Gigabit speed

**Connection Plan:**
```
Port 1: Uplink to router
Port 2: Mini PC (192.168.1.239)
Port 3: Gaming PC (DHCP)
Port 4: NAS (192.168.1.240)
Port 5: Available (future device or laptop)
```

**Installation:**
1. Receive ethernet cable from router
2. Connect to Port 1
3. Connect devices to Ports 2-5
4. Plug in power
5. Done! No configuration needed âœ…

**Benefits:**
- Plug-and-play (no setup)
- Full Gigabit speed to all devices
- Silent operation
- Reliable (TP-Link quality)
- Cheap ($13!)
- 5 ports (room for expansion)

**Limitations:**
- Unmanaged (no VLANs, QoS, monitoring)
- Gigabit only (not 2.5G or 10G)
- No PoE (not needed anyway)
- No web interface

**But perfect for this use case!** âœ…

---

### 2.5 Internet Connection

**Provider:** Unknown ISP (Argentina)

**Plan Details:**
- **Download Speed:** 300 Mbps (advertised)
- **Upload Speed:** Unknown (likely 30-50 Mbps, typical for Argentina)
- **Type:** Fiber or Cable (unknown)
- **Public IP:** 190.97.55.99 (dynamic)
  - Changes occasionally
  - Not static
  - Cloudflare Tunnel handles this automatically âœ…
- **IPv6:** Unknown if available
- **Latency:** Good (low ping to local servers)

**Real-World Performance:**
- Fast enough for multiple 4K streams
- Good for remote Jellyfin access
- Downloads are fast
- Gaming latency is good
- No buffering issues

**Bandwidth Usage:**
- Jellyfin external access: Depends on upload speed
- Downloads: Can max out 300 Mbps easily
- Multiple users: No slowdown
- 4K streaming: Works well

**Reliability:**
- Generally stable
- Occasional outages (typical for any ISP)
- Cloudflare Tunnel reconnects automatically âœ…

**Considerations:**
- Upload speed unknown (affects remote streaming quality)
- Dynamic IP handled by Cloudflare âœ…
- May want static IP in future (not critical)
- Could upgrade to faster plan if needed

---

### 2.6 IP Address Allocation (VERIFIED)

**Static IP Assignments:**
```
192.168.1.1     Router (Archer AX55)
192.168.1.239   Mini PC (homelab server) - STATIC âœ…
192.168.1.240   NAS (future, planned) - STATIC (reserved)
```

**Dynamic DHCP Range (Estimated):**
```
192.168.1.100 - 192.168.1.199   Client devices (phones, laptops, etc.)

Active DHCP clients:
- Gaming PC
- Galaxy S23 Ultra (when on WiFi)
- MacBook M4 Pro (when on WiFi)
- Xbox Series S
- Shield Pro TV (or static?)
- Chromecast
```

**Recommended Allocation (Best Practice):**
```
192.168.1.1    - 192.168.1.99    Reserved for servers/infrastructure
192.168.1.100  - 192.168.1.199   DHCP pool for clients
192.168.1.200  - 192.168.1.254   Reserved for future expansion
```

**How Mini PC Gets Static IP:**
- Method 1: Configured in Ubuntu netplan (most likely)
- Method 2: DHCP reservation on router
- Verification: `ip addr show enp1s0` shows 192.168.1.239 âœ…

**Configuration File:**
- Location: `/etc/netplan/` (Ubuntu Server)
- File: Likely `01-netcfg.yaml` or similar
- Contains: Static IP, gateway, DNS settings

**Example Netplan Config:**
```yaml
network:
  version: 2
  ethernets:
    enp1s0:
      addresses:
        - 192.168.1.239/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 1.0.0.1
```

---

### 2.7 VPN Configuration

**Tailscale:**
- **Status:** NOT INSTALLED âŒ
  - Initial assumption was incorrect
  - Interface exists (tailscale0) but not configured
  - User confirmed NOT using Tailscale
- **Reason:** Using Cloudflare Tunnel instead
- **Future:** May install if needed for:
  - VPN access without Cloudflare dependency
  - Mesh network between devices
  - Access from restrictive networks

**Cloudflare Tunnel (Primary Remote Access):**
- **Status:** ACTIVE âœ…
- **Method:** cloudflared Docker container
- **Token:** Encrypted in docker-compose.yml
- **Advantages:**
  - No port forwarding needed
  - No VPN client needed
  - Works from anywhere
  - DDoS protection
  - SSL automatic
  - Fast (Cloudflare's edge network)

**Alternative VPN Options (Not in Use):**
- WireGuard: Could setup for direct VPN
- OpenVPN: Older, less efficient
- Router VPN: Archer AX55 may support

**Current Solution:**
- Cloudflare Tunnel for web services âœ…
- Works perfectly for current needs âœ…
- No VPN needed for access âœ…

**Future Consideration:**
- Add Tailscale if want VPN for:
  - SSH access without Cloudflare
  - Direct NAS access
  - File transfers
  - Backup connections

---

### 2.8 External Access - Cloudflare Tunnels (VERIFIED)

**Service:** Cloudflare Tunnel (cloudflared)
**Status:** Active and working âœ…
**Container:** cloudflared (in main docker-compose.yml)

**Configuration:**
- **Domain:** matiasmassetti.com
- **DNS:** Managed by Cloudflare
- **Tunnel Token:** eyJhIjoiN2RmZWU0ZDJkZTAyZmExOTVlNmI5Njc0ZGUyMDVmYTYi... (encrypted)
- **Running:** 24/7 in Docker container

**Public URLs (Verified Active):**
```
https://media.matiasmassetti.com
  â†’ Jellyfin (192.168.1.239:8096)
  â†’ Media server
  â†’ Most used service

https://radarr.matiasmassetti.com
  â†’ Radarr (192.168.1.239:7878)
  â†’ Movie management

https://sonarr.matiasmassetti.com
  â†’ Sonarr (192.168.1.239:8989)
  â†’ TV show management

https://descargas.matiasmassetti.com
  â†’ qBittorrent (192.168.1.239:8080)
  â†’ Download client

https://pedidos.matiasmassetti.com
  â†’ Jellyseerr (192.168.1.239:5055)
  â†’ Media requests

https://home.matiasmassetti.com
  â†’ Homarr (192.168.1.239:7575)
  â†’ Dashboard

https://status.matiasmassetti.com
  â†’ Uptime Kuma (192.168.1.239:3001)
  â†’ Service monitoring
```

**How It Works:**
1. Cloudflared container runs on mini PC
2. Creates secure tunnel to Cloudflare
3. Cloudflare edge receives requests
4. Routes through tunnel to local service
5. Response goes back through tunnel
6. No ports opened on router âœ…

**Benefits:**
- âœ… No port forwarding (secure!)
- âœ… No dynamic IP issues
- âœ… SSL certificates automatic
- âœ… DDoS protection via Cloudflare
- âœ… Fast (Cloudflare's global network)
- âœ… Works from anywhere
- âœ… No VPN client needed
- âœ… Easy subdomain management

**Cloudflare Dashboard:**
- Access: https://dash.cloudflare.com
- Manage: DNS records, tunnel config
- Monitor: Traffic, analytics
- Modify: Add new services easily

**Adding New Services:**
1. Add DNS record in Cloudflare (CNAME)
2. Point to tunnel ID
3. Add route in tunnel config
4. Service accessible immediately!

**Security:**
- Cloudflare firewall
- Can add access policies
- Can require authentication
- Rate limiting available
- DDoS protection included

**Cost:** FREE (Cloudflare Tunnel is free!) âœ…

---

### 2.9 Docker Networks (VERIFIED)

**Main Network - "homelab":**
- **ID:** 90fe0eb7a717
- **Driver:** bridge
- **Subnet:** 172.18.0.1/16
- **Gateway:** 172.18.0.1
- **Containers:** All main homelab services
  - jellyfin, radarr, sonarr, bazarr
  - qbittorrent, jackett
  - jellyseerr, profilarr
  - cloudflared
  - portainer, homarr
  - uptime-kuma, netdata
  - nextcloud, nextcloud-db
  - image-server

**Project Networks (Discovered):**

**media_tracker_network:**
- **ID:** b034ddea622c
- **Subnet:** 172.21.0.1/16
- **Used by:** media-tracker project
- **Services:** PostgreSQL + pgAdmin

**Other Networks:**
- **eb3cfcb8fd17:** 172.19.0.1/16 (another project)
- **68b24eb4cca1:** 172.22.0.1/16 (unused/old)
- **6981ce0d5525:** 172.20.0.1/16 (unused/old)
- **a1ddb309ba3b:** Another project network

**Default Docker Networks:**
- **docker0:** 172.17.0.1/16 (default bridge, unused)
- **host:** Host network mode (glances uses this)

**Network Traffic (From Discovery):**
```
br-90fe0eb7a717 (homelab):
  RX: 497GB received
  TX: 126GB transmitted
  â†’ Heavy usage (Jellyfin streaming)

Individual containers (veth interfaces):
  - Jellyfin: 123GB RX, 122GB TX (most traffic!)
  - qBittorrent: 352GB RX, 3.2GB TX (downloads)
  - Others: Various amounts
```

**Why Multiple Networks:**
- Isolation between projects
- Each docker-compose creates its own network
- Good for security
- Prevents accidental cross-talk
- Can communicate via host if needed

**Cleanup Recommendation:**
- Remove unused networks after NAS setup
- Consolidate projects if possible
- Keep main homelab network
- Document which projects use which networks

---

## SECTION 3: ACTUAL FILE STRUCTURE (DISCOVERED DEC 26)

### 3.1 Real Mount Points

**CRITICAL DISCOVERY:**
```
What I thought:
/DATA/Peliculas = Movies folder (2.9TB)
/DATA/Series = TV Shows folder (418GB)

Reality:
/DATA/Peliculas â†’ SYMLINK to /DATA/Media/Peliculas
/DATA/Series â†’ SYMLINK to /DATA/Media/Series

Actual mount:
/DATA/Media = /dev/sda2 (3.7TB exFAT USB drive)
```

**Why This Matters:**
- Docker containers see `/DATA/Peliculas` and `/DATA/Series`
- These are symlinks pointing to `/DATA/Media/*`
- The REAL data is on `/DATA/Media/` (external USB drive)
- When migrating to NAS, need to understand this structure

---

### 3.2 Complete Directory Tree

```
/DATA/
  â”œâ”€â”€ AppData/                    (4KB - CasaOS system files)
  â”‚
  â”œâ”€â”€ Documents/                  (35MB - your documents)
  â”‚
  â”œâ”€â”€ Downloads/                  (4KB - empty folder)
  â”‚
  â”œâ”€â”€ Gallery/                    (minimal)
  â”‚
  â”œâ”€â”€ Media/                      â† ACTUAL MOUNT POINT! (3.7TB exFAT USB)
  â”‚   â”‚
  â”‚   â”œâ”€â”€ Peliculas/              (2.9TB - REAL movie location)
  â”‚   â”‚   â”œâ”€â”€ Movie1/
  â”‚   â”‚   â”œâ”€â”€ Movie2/
  â”‚   â”‚   â””â”€â”€ ... (~900 movies)
  â”‚   â”‚
  â”‚   â”œâ”€â”€ Series/                 (418GB - REAL TV show location)
  â”‚   â”‚   â”œâ”€â”€ Show1/
  â”‚   â”‚   â”œâ”€â”€ Show2/
  â”‚   â”‚   â””â”€â”€ ... (multiple shows)
  â”‚   â”‚
  â”‚   â”œâ”€â”€ Google Drive 4-10-2024/ (282GB - Oct 2024 backup)
  â”‚   â”‚   â”œâ”€â”€ Alloy/
  â”‚   â”‚   â”œâ”€â”€ Backup Notebook ASU.../
  â”‚   â”‚   â”œâ”€â”€ Brasil-Argentina partido completo/
  â”‚   â”‚   â”œâ”€â”€ Google Photos 20 octubre 2024/
  â”‚   â”‚   â”œâ”€â”€ Ocio/
  â”‚   â”‚   â”œâ”€â”€ Photos/
  â”‚   â”‚   â”œâ”€â”€ Samsung S23 Ultra/
  â”‚   â”‚   â”œâ”€â”€ USA 2024/
  â”‚   â”‚   â”œâ”€â”€ Viajes/
  â”‚   â”‚   â”œâ”€â”€ reporteminoritario.com/
  â”‚   â”‚   â””â”€â”€ VIDEO OSVALDO 202.../
  â”‚   â”‚
  â”‚   â”œâ”€â”€ Backup logs before re processing september 18/ (56MB)
  â”‚   â”œâ”€â”€ Backup notebok vieja/   (185MB)
  â”‚   â”œâ”€â”€ Backup notebok vieja teladoc 17 oct 2024/ (unknown)
  â”‚   â”œâ”€â”€ Libros/                 (Books - unknown size)
  â”‚   â”œâ”€â”€ Media/                  (256K - meta folder)
  â”‚   â”œâ”€â”€ Movies/                 (1.0MB - duplicate/old, deleted)
  â”‚   â”œâ”€â”€ Music/                  (unknown size)
  â”‚   â”œâ”€â”€ TV Shows/               (256KB - duplicate/old, deleted)
  â”‚   â”œâ”€â”€ System Volume Information/ (system files)
  â”‚   â”œâ”€â”€ disk/                   (unknown)
  â”‚   â”œâ”€â”€ images/                 (unknown)
  â”‚   â””â”€â”€ $RECYCLE.BIN/           (512KB - emptied)
  â”‚
  â”œâ”€â”€ Peliculas -> /DATA/Media/Peliculas  (SYMLINK!)
  â”‚
  â””â”€â”€ Series -> /DATA/Media/Series        (SYMLINK!)
```

---

### 3.3 Mount Configuration (FROM /etc/fstab)

**File:** `/etc/fstab`

**Entry:**
```bash
UUID=AC85-7883 /DATA/Media exfat uid=1000,gid=1000,umask=000,defaults 0 0
```

**Breaking it down:**
- **UUID=AC85-7883:** Unique ID of the external drive partition
  - Device: /dev/sda2
  - More reliable than /dev/sdX (which can change)
- **Mount point:** /DATA/Media
- **Filesystem:** exFAT
  - Cross-platform (Windows/Mac/Linux)
  - Supports large files (4K movies >4GB)
  - No permission issues
- **Options:**
  - `uid=1000`: Owner user ID (matias)
  - `gid=1000`: Owner group ID (matias)
  - `umask=000`: Full permissions (rwx for all)
  - `defaults`: Standard mount options
- **Dump:** 0 (no backup via dump)
- **Pass:** 0 (no fsck check on boot)

**Why exFAT:**
- âœ… Works on Windows (Gaming PC)
- âœ… Works on Linux (Mini PC)
- âœ… Works on Mac (if needed)
- âœ… No 4GB file size limit (like FAT32)
- âœ… Simple permissions
- âŒ No journaling (risk of corruption on power loss)
- âŒ Not as robust as ext4 or btrfs

**Auto-mount on Boot:**
- Entry in /etc/fstab = automatic mount
- System mounts /DATA/Media on every boot
- If drive not present, boot may pause (depends on options)

**For NAS Migration:**
- Will add new entry:
```bash
192.168.1.240:/volume1/Media /mnt/nas nfs defaults,_netdev,nofail 0 0
```
- `_netdev`: Wait for network before mounting
- `nofail`: Don't fail boot if mount fails

---

### 3.4 Docker Volume Mounts (FROM docker-compose.yml)

**Current Configuration:**

**Jellyfin:**
```yaml
volumes:
  - /DATA/Peliculas:/data/movies
  - /DATA/Series:/data/shows
```
- Container sees: /data/movies and /data/shows
- Actually reading from: /DATA/Media/Peliculas and /DATA/Media/Series (via symlink)

**Radarr:**
```yaml
volumes:
  - /DATA/Peliculas:/movies
```

**Sonarr:**
```yaml
volumes:
  - /DATA/Series:/tv
```

**Bazarr:**
```yaml
volumes:
  - /DATA/Peliculas:/movies
  - /DATA/Series:/tv
```

**After NAS Migration:**

**Option A: Update Symlinks** (Simpler)
```bash
# Remove old symlinks
rm /DATA/Peliculas
rm /DATA/Series

# Create new symlinks
ln -s /mnt/nas/Peliculas /DATA/Peliculas
ln -s /mnt/nas/Series /DATA/Series

# Docker compose doesn't need changes! âœ…
```

**Option B: Update Docker Compose** (Cleaner)
```yaml
volumes:
  - /mnt/nas/Peliculas:/data/movies
  - /mnt/nas/Series:/data/shows
```
- Remove symlinks
- Direct paths to NAS
- More explicit
- Recommended approach âœ…

---

## SECTION 4: DISCOVERED SERVICES & PROJECTS

### 4.1 Main Homelab Stack (docker-compose.yml)

**Location:** `/opt/docker/docker-compose.yml`

**Media Services:**
1. **jellyfin** - Media server (movies, TV shows)
2. **radarr** - Movie automation
3. **sonarr** - TV show automation
4. **bazarr** - Subtitle management
5. **qbittorrent** - Torrent client
6. **jackett** - Indexer proxy/search
7. **jellyseerr** - Media request system
8. **profilarr** - Profile management for *arr apps

**Infrastructure:**
9. **cloudflared** - Cloudflare tunnel
10. **portainer** - Docker management UI
11. **homarr** - Main dashboard
12. **uptime-kuma** - Service monitoring
13. **glances** - System monitoring
14. **netdata** - Advanced monitoring

**Cloud & Storage:**
15. **nextcloud** - Personal cloud
16. **nextcloud-db** - MariaDB for Nextcloud
17. **image-server** - Static file server

**Total Main Services:** 17 containers

---

### 4.2 Development Projects (DISCOVERED)

**1. reporteminoritario-transcript-fetcher**
- **Status:** Active (based on Ollama integration)
- **Location:** Separate directory with docker-compose
- **Components:**
  - **backend:** Python/Node.js backend
  - **frontend:** React/web frontend
  - **wait_ollama:** Waits for Ollama to be ready
- **Technology:**
  - **Ollama:** AI model for processing transcripts
  - **Environment:** `OLLAMA_HOST=http://host.docker.internal:11434`
  - **Ports:** Backend 8000, Frontend 3000
- **Purpose:** Podcast transcript fetching and analysis
  - Fetches transcripts from podcast episodes
  - Uses AI (Ollama) to analyze/summarize
  - Web interface to view results
- **Network:** Own network (not homelab)

**IMPORTANT:** You already have Ollama running! âœ…
- This makes personal LLM setup much easier
- Ollama is at: http://host.docker.internal:11434
- Just need to add Open WebUI to access it

---

**2. media-tracker (DUPLICATE FOUND!)**
- **Status:** Two instances discovered (consolidate needed!)
- **Location:** Two separate docker-compose files found:
  - `media-tracker-api-docker-compose.yml`
  - `media-tracker-db-docker-compose.yml`
- **Components:**
  - **postgres:** PostgreSQL 16
  - **pgAdmin:** Database management UI
- **Configuration:**
  - Database: media_tracker
  - User: postgres
  - Port: 5432 (PostgreSQL), 5050 (pgAdmin)
- **Purpose:** Track watched movies/shows (assumed)
  - Might be abandoned or old project
  - Two instances suggest migration or testing
- **Network:** media_tracker_network

**Action Needed:**
- Consolidate or remove duplicate
- Check if still in use
- Merge databases if both active
- Clean up after NAS setup

---

**3. scraper-autoentrada**
- **Status:** Unknown (appears configured for auto-restart)
- **Location:** Separate directory
- **Components:**
  - Single container built from Dockerfile
  - Uses .env file for configuration
- **Purpose:** Bot for ticket booking automation (assumed from name)
  - "autoentrada" suggests ticket/entry automation
  - Likely scrapes ticket websites
  - Books automatically when available
- **Technology:**
  - Python or Node.js (unknown)
  - Restart policy: unless-stopped
- **Network:** Own network

**Notes:**
- May be inactive
- Check if still needed
- Document functionality
- Review code to understand purpose

---

**4. usa-2026**
- **Status:** Running on port 3000
- **Location:** Separate directory
- **Components:**
  - Web application
  - Built from Dockerfile
  - Exposed on port 3000
  - Restart: always
- **Purpose:** FIFA World Cup 2026 travel planner (assumed)
  - Relevant for January 2026 USA trip
  - Trip planning tool
  - Likely helps plan travel in USA
- **Technology:**
  - Web app (React/Next.js likely)
  - Container: usa2026
- **Access:** http://192.168.1.239:3000 (local only)

**Notes:**
- Timely for upcoming trip!
- May want to access remotely
- Could add Cloudflare tunnel subdomain
- Document features

---

### 4.3 CasaOS (DISCOVERED ACTIVE)

**Status:** RUNNING âœ…

**Services Found:**
```
casaos.service
casaos-gateway.service
casaos-app-management.service
casaos-local-storage.service
casaos-message-bus.service
casaos-user-service.service
```

**What is CasaOS:**
- Home server management system
- Web-based UI for Docker
- App store for easy installations
- File manager
- User-friendly interface

**Access:**
- URL: http://home.matiasmassetti.com/#/ (shown in browser screenshot)
- Or: http://192.168.1.239:80 (default port)

**Features Likely in Use:**
- Docker container management
- File browsing (/DATA/Media access shown)
- App installation
- System monitoring
- User management

**Pros:**
- âœ… Easy to use
- âœ… Good for beginners
- âœ… Nice UI
- âœ… File manager useful

**Cons:**
- âš ï¸ Overhead (extra services running)
- âš ï¸ Can't see folder sizes easily (you mentioned)
- âš ï¸ Less control than pure Docker
- âš ï¸ Another layer to maintain

**Your Opinion:**
- "One thing I don't like about CasaOS" = can't see folder sizes
- Still using it for now
- Could replace with Portainer + File Browser later

**Future:**
- Keep for now âœ…
- Re-evaluate after NAS setup
- Maybe replace with:
  - Portainer (Docker UI)
  - File Browser (file management)
  - Homarr (dashboard)
- Or keep if you like it!

---

## SECTION 5: CURRENT DISK STATUS (DEC 26, 2025)

### 5.1 Storage Summary

**External Drive (/DATA/Media):**
```
Device:     /dev/sda2
UUID:       AC85-7883
Filesystem: exFAT
Total:      3.7TB
Used:       3.6TB
Free:       59GB (1.6%)
Status:     ðŸŸ¡ Manageable until NAS
```

**Breakdown:**
```
Movies (Peliculas):              2.9TB (80.6%)
TV Shows (Series):               418GB (11.0%)
Google Drive Backup:             282GB (7.4%)
Books + Music + Other:           ~150GB (estimated)
Backups (logs, notebooks):       241MB
Recycle Bin:                     512KB (emptied)
System files:                    Minimal
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
TOTAL USED:                      3.6TB
```

**Internal NVMe (Mini PC):**
```
Total:      913GB
Used:       ~250GB (estimated)
Free:       ~660GB
Usage:      ~27%

Breakdown:
- OS + System:        ~50GB
- Docker configs:     ~20GB
- Docker images:      ~8GB
- Downloads:          ~4KB (empty)
- Projects:           Unknown
- Free space:         ~660GB
```

---

### 5.2 Cleanup Actions Taken (Dec 26, 2025)

**1. Deleted Corrupted TV Show:**
- **What:** "Whose Line Is It Anyway"
- **Size:** 19GB
- **Reason:** Files corrupted, unplayable on all devices
- **Result:** 19GB freed âœ…

**2. Deleted Duplicate Folders:**
- `/DATA/Media/Movies` (1MB - duplicate of Peliculas)
- `/DATA/Media/TV Shows` (256KB - duplicate of Series)
- **Result:** 1.3MB freed (negligible but clean)

**3. Emptied Recycle Bin:**
- `/DATA/Media/$RECYCLE.BIN` (512KB)
- **Result:** 512KB freed

**4. Docker System Cleanup:**
- **Command:** `docker system prune -a -f`
- **Removed:**
  - Unused containers
  - Unused images
  - Unused networks
  - Build cache
- **Result:** ~200MB freed (estimated from "reclaimable")

**Total Freed:** ~19.2GB
**Before:** 40GB free
**After:** 59GB free âœ…

---

### 5.3 Space Analysis

**Why Drive is Full:**
- Not a Docker problem (only 12GB total)
- Not downloads (folder is empty)
- It's ALL media files (3.3TB)
- Plus 282GB Google Drive backup
- This is just a lot of content!

**What's Eating Space:**
```
#1 Movies:           2.9TB (78% of drive)
   ~900 movies
   Mostly 4K (50GB each)
   Some 1080p (5GB each)

#2 Google Drive:     282GB (8% of drive)
   Oct 2024 backup
   Photos, videos, docs
   May have duplicates with current GDrive

#3 TV Shows:         418GB (11% of drive)
   Multiple series
   Various qualities
   After deleting corrupted show

#4 Everything else:  ~150GB (3% of drive)
   Books, music, backups, etc.
```

---

### 5.4 Pre-NAS Strategy (Until Jan 11)

**Current Free Space:** 59GB
**Days Until NAS:** 16 days
**Plan:** NO new downloads

**Why 59GB is Enough:**
```
Typical Usage:
- New movie (4K):     ~50GB
- New TV episode:     ~2-5GB
- System growth:      ~1GB/week
- Buffer needed:      ~10GB minimum

59GB = Safe for 16 days if:
âœ… No new downloads
âœ… No large file operations
âœ… Monitor weekly
```

**Monitoring:**
```bash
# Check weekly:
df -h /DATA/Media

# If space drops below 30GB:
- Delete old movie
- Or postpone download until NAS
```

**Risk Assessment:**
```
ðŸŸ¢ 59GB = Comfortable (>30GB)
ðŸŸ¡ 30GB = Warning (delete something)
ðŸ”´ 10GB = Critical (stop all downloads)
```

**Current Status:** ðŸŸ¢ Green (59GB) âœ…

---

## SECTION 6: PAID SUBSCRIPTIONS

### 6.1 Technical Services

**Vercel Pro:**
- **Cost:** $20/month ($240/year)
- **Features:**
  - Image optimization
  - Multiple projects
  - Team seats
  - 100GB bandwidth/month
  - Serverless functions
  - Custom domains
  - Edge network
- **Current Use:** Hosting frontend projects
- **Status:** âš ï¸ CAN BE REPLACED
- **Savings Potential:** $240/year
- **Replacement:** Self-host with Nginx Proxy Manager
- **Timeline:** February 2026 (after NAS stable)

**Claude Pro:**
- **Cost:** $20/month ($240/year)
- **Features:**
  - Priority access
  - Faster responses
  - Extended conversations
  - Early feature access
- **Current Use:** Work requirement
- **Status:** âœ… KEEP (worth it for work)
- **Not Replaceable:** Required for professional use

---

### 6.2 Cloud Storage

**Google Drive (2TB Plan):**
- **Cost:** $100/year (~$8.33/month)
- **Capacity:** 2TB
- **Used:** 638.38GB (31.9% utilized)
- **Free:** ~1.36TB remaining
- **Contents:**
  - Movies (backups/overflow)
  - Images
  - Documents
  - Books
  - Personal photos
  - Personal videos
  - Project files
- **Backup on External Drive:** 282GB (Oct 4, 2024)
- **Status:** âš ï¸ CAN BE REPLACED
- **Savings Potential:** $100/year
- **Replacement Plan:**
  1. Migrate all to NAS (38TB available!)
  2. Setup Nextcloud for sync
  3. Setup Photoprism/Immich for photos
  4. Verify everything migrated
  5. Keep free 15GB tier for Gmail
  6. Cancel paid subscription
- **Timeline:** March 2026 (after verifying all data safe)

**3-2-1 Backup Strategy (Future):**
```
3 copies:   NAS + External USB + Cloud (B2/Wasabi)
2 media:    NAS (internal) + USB (external)
1 offsite:  Cloud backup (encrypted)
```

---

### 6.3 Media & Entertainment

**Netflix:**
- **Cost:** ~$15/month (~$180/year) (Argentina pricing)
- **Plan:** Standard or Premium (unknown)
- **Usage:** Family sharing
- **Status:** âœ… KEEP
- **Reason:** Family uses it, not worth replacing
- **Alternative:** Not practical (legal content)

**Spotify:**
- **Cost:** ~$10/month (~$120/year) (Argentina pricing)
- **Plan:** Individual or Family
- **Usage:** Music streaming
- **Status:** âš ï¸ COULD REPLACE
- **Savings Potential:** $120/year
- **Replacement:** Navidrome (self-hosted music streaming)
- **Considerations:**
  - Need to own music files
  - Lose discover weekly, etc.
  - But save $120/year
- **Decision:** Evaluate after NAS

**YouTube Premium:**
- **Cost:** ~$12/month (~$144/year) (Argentina pricing)
- **Features:**
  - Ad-free YouTube
  - YouTube Music
  - Background play
  - Downloads
- **Usage:** Regular viewing
- **Status:** âš ï¸ COULD REPLACE
- **Savings Potential:** $144/year (partial)
- **Replacement:**
  - AdGuard Home (blocks ads DNS-level)
  - Navidrome (music replacement)
  - yt-dlp (download videos)
- **Considerations:**
  - Still need to support creators
  - Ads blocked but not perfect
  - Lose some convenience
- **Decision:** Evaluate after AdGuard Home setup

---

### 6.4 Total Cost Analysis

**Current Monthly Costs:**
```
Technical:
- Vercel:           $20
- Claude:           $20

Cloud Storage:
- Google Drive:     $8

Entertainment:
- Netflix:          $15
- Spotify:          $10
- YouTube Premium:  $12
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
TOTAL:              $85/month
ANNUAL:             $1,020/year
```

**Potential Savings (After Homelab):**
```
Replaceable Services:
- Vercel:           $240/year  (self-host with NPM)
- Google Drive:     $100/year  (use NAS + Nextcloud)
- Spotify:          $120/year  (Navidrome + local music)
- YouTube Premium:  $144/year  (AdGuard Home + yt-dlp)
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
TOTAL POTENTIAL:    $604/year! ðŸŽ‰

Services to Keep:
- Claude Pro:       $240/year  (work requirement)
- Netflix:          $180/year  (family, keep)
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
MINIMUM ANNUAL:     $420/year
```

**NAS Investment ROI:**
```
NAS Investment:     $1,587 (one-time)
Annual Savings:     $604/year (if replace all)
Payback Period:     2.6 years

Year 1:  -$1,587 + $604 = -$983
Year 2:  -$983 + $604 = -$379
Year 3:  -$379 + $604 = +$225  â† Break even!
Year 4:  +$225 + $604 = +$829
Year 5:  +$829 + $604 = +$1,433

After 5 years: NET SAVINGS of $1,433
Plus: 38TB storage vs 2TB Google Drive!
Plus: Full privacy and control!
Plus: Learning and skills gained!
```

**Realistic Savings:**
```
Conservative Estimate:
- Vercel:           $240  (will definitely replace)
- Google Drive:     $100  (will definitely replace)
- Spotify:          $60   (maybe keep, maybe replace)
- YouTube:          $0    (probably keep for creators)
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
LIKELY SAVINGS:     $400/year

Payback Period:     4 years (more conservative)
Still worth it!     âœ…
```

---

## SECTION 7: MIGRATION PLAN TO NAS

### 7.1 Pre-Migration Checklist (Now - Jan 10)

**Completed:**
- âœ… Disk cleanup (59GB free)
- âœ… Discovery of actual file structure
- âœ… Verification of services
- âœ… Documentation of current state

**To Do:**
```
â˜ NO new downloads until after NAS
â˜ Monitor disk space weekly
â˜ Verify all Docker containers working
â˜ Review Google Drive backup contents
â˜ Test NAS setup on paper (mental run-through)
â˜ Prepare USA trip logistics
â˜ Save shopping list (with model numbers!)
```

---

### 7.2 Purchase Phase (Jan 11, 2026)

**Shopping List:**
```
â˜ Synology DS423 (4-bay NAS)               $379.99
â˜ WD Red Pro 14TB (WD142KFGX) Ã— 4         $1,159.96
â˜ TP-Link TL-SG105 (5-port switch)         $12.99
â˜ Cable Matters Cat6 cables (5-pack)       $12.49
â˜ Argentina power adapter (2-pack)         $6.99
â˜ Bubble wrap (for packing NAS)            ~$15.00
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
TOTAL:                                     $1,587.42

CRITICAL: Save model number WD142KFGX
All 4 drives must be identical!
```

**Packing for Return Trip:**
```
Carry-On (CRITICAL!):
â˜ 4x WD Red Pro 14TB drives
â˜ Anti-static bags for drives
â˜ Padded case or wrap in soft clothes
â˜ Place UNDER SEAT (not overhead!)
â˜ NEVER install drives for travel!

Checked Luggage:
â˜ DS423 NAS (bubble wrapped)
â˜ Place in MIDDLE of suitcase
â˜ Surround with clothes for cushioning
â˜ TP-Link switch (small, anywhere)
â˜ Cables and adapters

Hand Carry:
â˜ Shopping receipt (~$1,590 for customs)
â˜ Setup guides (this document!)
```

**Customs Story:**
```
"Personal network storage for family photos and videos"
- Total value: ~$1,590 (under $2K usually OK)
- For personal use
- Not for resale
- Keep receipt handy
```

---

### 7.3 Setup Phase (Jan 21-25, 2026)

**Day 1 (Jan 21) - Physical Setup:**
```
Morning:
â˜ Unpack NAS and drives carefully
â˜ Inspect for shipping damage
â˜ Set up workspace on clean table

Installation:
â˜ Install all 4 drives in bays 1-4
  - Handle with care
  - Don't force
  - Secure screws properly
â˜ Connect TP-Link switch to network
  - Port 1: Router uplink
  - Port 2: Mini PC
  - Port 3: Gaming PC
  - Port 4: NAS
â˜ Power on NAS (wait for beep)
â˜ Access DSM installation via browser
  - http://find.synology.com
  - Or scan network for NAS

DSM Installation:
â˜ Install DSM 7.x
â˜ Create admin account
â˜ Set timezone: America/Argentina/Buenos_Aires
â˜ Skip QuickConnect (using Cloudflare)
â˜ Skip Synology account (optional)

Network Configuration:
â˜ Set static IP: 192.168.1.240
â˜ Gateway: 192.168.1.1
â˜ DNS: 1.1.1.1, 1.0.0.1
â˜ Test connectivity: ping google.com

Storage Configuration:
â˜ Create storage pool:
  - Type: SHR (Synology Hybrid RAID)
  - Drives: All 4 Ã— 14TB
  - Data protection: 1-drive redundancy
  - BTRFS filesystem
â˜ Create volume: volume1
â˜ Enable data checksums âœ…
â˜ Set up Btrfs snapshots:
  - Hourly: Keep 24
  - Daily: Keep 7
  - Weekly: Keep 4

Folder Creation:
â˜ Create shared folders:
  - Media
  - Documents
  - Photos
  - Backups
  - Projects
â˜ Set permissions (NFS + SMB)
â˜ Enable NFS for 192.168.1.239 (mini PC)

Subfolder Creation (in Media):
â˜ /volume1/Media/Peliculas
â˜ /volume1/Media/Series
â˜ /volume1/Media/Audiobooks
â˜ /volume1/Media/Podcasts
â˜ /volume1/Media/Music

Testing:
â˜ Verify NFS export: showmount -e 192.168.1.240
â˜ Test write: Create test file via NFS
â˜ Check disk health in DSM
â˜ Verify RAID status (Healthy)

Evening:
â˜ Let RAID parity build complete
  - This takes 8-24 hours!
  - Don't interrupt
  - NAS will beep when done
â˜ Monitor via DSM
```

**Day 2 (Jan 22) - Mini PC NFS Setup:**
```
Morning:
â˜ SSH to mini PC
â˜ Install NFS client:
  sudo apt update
  sudo apt install nfs-common

â˜ Create mount point:
  sudo mkdir -p /mnt/nas

â˜ Test manual mount:
  sudo mount -t nfs 192.168.1.240:/volume1/Media /mnt/nas
  ls /mnt/nas  # Should see Peliculas, Series, etc.

â˜ Create test file:
  touch /mnt/nas/test.txt
  ls /mnt/nas/test.txt

â˜ If successful, unmount:
  sudo umount /mnt/nas

Permanent Mount:
â˜ Edit /etc/fstab:
  sudo nano /etc/fstab

â˜ Add line:
  192.168.1.240:/volume1/Media /mnt/nas nfs defaults,_netdev,nofail 0 0

â˜ Test fstab:
  sudo mount -a
  df -h | grep nas

â˜ Reboot to verify auto-mount:
  sudo reboot
  # Wait, SSH back in
  df -h | grep nas  # Should show mounted

â˜ Create symlinks (if using that method):
  ln -s /mnt/nas/Peliculas /DATA/Peliculas
  ln -s /mnt/nas/Series /DATA/Series

Verification:
â˜ NAS mounted: âœ…
â˜ Can read: âœ…
â˜ Can write: âœ…
â˜ Auto-mounts on boot: âœ…
```

**Day 3 (Jan 23) - Data Migration:**
```
CRITICAL: This is the longest step!

Setup:
â˜ Open terminal to mini PC
â˜ Verify NAS mounted: df -h | grep nas
â˜ Estimate time:
  - 3.3TB total
  - Gigabit network = ~100MB/s
  - Time = ~9-10 hours
â˜ Plan to start in morning
â˜ Let run all day + evening

Migration Command (Movies):
â˜ Run:
  rsync -avh --progress \
    /DATA/Media/Peliculas/ \
    /mnt/nas/Peliculas/

â˜ This will:
  - Copy all movies
  - Preserve permissions
  - Show progress
  - Resume if interrupted
  - Verify checksums

â˜ Monitor progress
â˜ Estimated time: 7-8 hours

Migration Command (TV Shows):
â˜ After movies complete, run:
  rsync -avh --progress \
    /DATA/Media/Series/ \
    /mnt/nas/Series/

â˜ Estimated time: 1-2 hours

Verification (CRITICAL!):
â˜ Check file counts match:
  find /DATA/Media/Peliculas -type f | wc -l
  find /mnt/nas/Peliculas -type f | wc -l
  # Numbers should match!

â˜ Check total sizes match:
  du -sh /DATA/Media/Peliculas
  du -sh /mnt/nas/Peliculas
  # Sizes should match!

â˜ Spot check files:
  - Random movie playback test
  - Check file sizes
  - Verify no corruption

â˜ DO NOT DELETE FROM EXTERNAL DRIVE YET!
  - Keep for 1 week minimum
  - Verify everything works first
  - Safety first!

Optional (Other Folders):
â˜ Migrate Google Drive backup:
  rsync -avh --progress \
    /DATA/Media/Google\ Drive\ 4-10-2024/ \
    /mnt/nas/Backups/GoogleDrive-2024-10-04/

â˜ Migrate Books:
  rsync -avh --progress \
    /DATA/Media/Libros/ \
    /mnt/nas/Documents/Books/
```

**Day 4 (Jan 24) - Docker Reconfiguration:**
```
Preparation:
â˜ Backup current docker-compose.yml:
  cp /opt/docker/docker-compose.yml \
     /opt/docker/docker-compose.yml.backup

â˜ Stop all containers:
  cd /opt/docker
  docker compose down

Update Paths (Method A - Simpler):
â˜ Keep symlinks:
  rm /DATA/Peliculas
  rm /DATA/Series
  ln -s /mnt/nas/Peliculas /DATA/Peliculas
  ln -s /mnt/nas/Series /DATA/Series

â˜ No docker-compose.yml changes needed!

Update Paths (Method B - Recommended):
â˜ Edit docker-compose.yml:
  nano /opt/docker/docker-compose.yml

â˜ Find all instances of:
  - /DATA/Peliculas
  - /DATA/Series

â˜ Replace with:
  - /mnt/nas/Peliculas
  - /mnt/nas/Series

â˜ Services to update:
  - jellyfin
  - radarr
  - sonarr
  - bazarr
  - nextcloud (if mounted)

Restart Services:
â˜ Start all containers:
  docker compose up -d

â˜ Check logs:
  docker compose logs -f

â˜ Verify no errors

Testing (CRITICAL!):
â˜ Test Jellyfin:
  - Login: https://media.matiasmassetti.com
  - Check libraries load
  - Verify movie count correct
  - Play random movie (test playback)
  - Check if subtitles work

â˜ Test Radarr:
  - Access: https://radarr.matiasmassetti.com
  - Check movie folder: /movies
  - Verify all movies visible
  - Check if can scan library

â˜ Test Sonarr:
  - Access: https://sonarr.matiasmassetti.com
  - Check TV folder: /tv
  - Verify shows visible
  - Test library scan

â˜ Test Bazarr:
  - Verify access to both movies and shows
  - Check subtitle folders

End-to-End Test:
â˜ Request new movie via Jellyseerr
â˜ Wait for Radarr to find it
â˜ Wait for download to complete
â˜ Verify it appears in Jellyfin
â˜ Play it! âœ…

If Everything Works:
â˜ Celebrate! ðŸŽ‰
â˜ Monitor for 24 hours
â˜ Check NAS temperature (should be <45Â°C)
â˜ Verify RAID status (should be Healthy)
```

**Day 5 (Jan 25) - Finalization:**
```
Morning Check:
â˜ Verify all services still running
â˜ Check NAS disk health:
  - DSM â†’ Storage Manager
  - Check SMART data
  - All green âœ…

â˜ Verify media playback:
  - Test 4K HDR movie
  - Test TV show episode
  - Test on multiple clients:
    * Shield Pro TV
    * Phone
    * Browser

Backup Setup:
â˜ Connect external 4TB drive to NAS USB port
â˜ Format in DSM (exFAT or ext4)
â˜ Setup Hyper Backup task:
  - Source: /volume1/Media
  - Destination: USB drive
  - Schedule: Weekly (Sunday 3 AM)
  - Retention: Keep last 4 backups
  - Compression: Yes
  - Encryption: Optional

â˜ Run first backup manually
â˜ Verify backup completes

Documentation:
â˜ Take screenshots of DSM
â˜ Document settings
â˜ Update this knowledge base
â˜ Take photos of physical setup

Cleanup:
â˜ External drive still connected to mini PC
â˜ DON'T disconnect yet! (wait 1 week)
â˜ Verify everything stable first
â˜ Keep as emergency backup

Final Checks:
â˜ All Docker services: âœ…
â˜ NAS RAID health: âœ…
â˜ Backup configured: âœ…
â˜ Media playback works: âœ…
â˜ Mobile access works: âœ…
â˜ 38TB available: âœ…

â˜ CELEBRATE! ðŸŽ‰ðŸš€ðŸ¾
```

---

### 7.4 Post-Migration (Week After)

**Week 1 (Jan 26 - Feb 1):**
```
Daily:
â˜ Monitor NAS temperature
â˜ Check RAID status
â˜ Verify services running
â˜ Test media playback

End of Week:
â˜ If everything perfect for 7 days:
  â˜ Disconnect external 4TB drive from mini PC
  â˜ Connect to NAS USB port
  â˜ Use for Hyper Backup
  â˜ Implements 3-2-1 backup strategy

â˜ Update docker-compose.yml backup
â˜ Push configs to GitHub (future)
â˜ Update knowledge base
```

---

## SECTION 8: FUTURE IMPROVEMENTS (POST-NAS)

### 8.1 Priority 1: Security & Essentials (Week 1-2)

**1. Vaultwarden (Password Manager):**
- **Timeline:** Week 1 after NAS
- **Why:** Security is #1 priority
- **Time:** 15-20 minutes setup
- **Features:**
  - Store all passwords securely
  - 2FA/TOTP codes
  - Secure notes
  - Sync across all devices
  - Replace browser password storage
- **Access:** https://vault.matiasmassetti.com
- **Apps:** Mobile (iOS/Android), Browser extensions
- **Benefits:**
  - âœ… Unique password for every service
  - âœ… Much more secure
  - âœ… You control the data
  - âœ… Sync everywhere
  - âœ… Free (vs $36/year for Bitwarden Premium)

**2. AdGuard Home (Network-wide Ad Blocker):**
- **Timeline:** Week 1 after NAS
- **Why:** Improves entire network
- **Time:** 20-30 minutes setup
- **Features:**
  - DNS-level ad blocking
  - Works on ALL devices
  - Blocks trackers
  - Blocks malware domains
  - Custom blacklists/whitelists
- **Configuration:**
  - Point router DNS to mini PC
  - All queries go through AdGuard
  - Blocks at DNS level
- **Benefits:**
  - âœ… Ads blocked on phone (even in apps!)
  - âœ… Ads blocked on Smart TV
  - âœ… Blocks Xbox ads
  - âœ… Faster browsing
  - âœ… More privacy
  - âœ… Can replace YouTube Premium (partially)

**3. Personal LLM (Ollama + Open WebUI):**
- **Timeline:** Week 2 after NAS
- **Why:** You already have Ollama running!
- **Time:** 15-20 minutes
- **Setup:**
  - Add Open WebUI to docker-compose
  - Connect to existing Ollama
  - Upload homelab docs for RAG
- **Models to Try:**
  - Llama 3.1 8B (fast, good quality)
  - DeepSeek Coder 6.7B (for coding help)
  - Mistral 7B (alternative)
- **Features:**
  - Chat interface like ChatGPT
  - Knows YOUR homelab setup
  - Unlimited conversations
  - Works offline
  - 100% private
  - No rate limits
- **Access:** https://ai.matiasmassetti.com
- **Cost:** $0 (vs $20/month ChatGPT)

---

### 8.2 Priority 2: Replace Vercel (Week 3-4)

**1. Nginx Proxy Manager:**
- **Timeline:** Week 3
- **Time:** 1-2 hours
- **Purpose:**
  - Manage all your project subdomains
  - Auto SSL certificates
  - Easy web UI
- **Setup:**
  - Install NPM in Docker
  - Configure proxy hosts
  - Point subdomains to NPM
  - NPM routes to correct container
- **Benefits:**
  - âœ… Easy subdomain management
  - âœ… Visual interface
  - âœ… Free SSL (Let's Encrypt)
  - âœ… Access control
  - âœ… Professional setup

**2. Self-Host First Project:**
- **Timeline:** Week 4
- **Project:** usa-2026 (already have it!)
- **Steps:**
  1. Ensure running in Docker
  2. Add to NPM (usa2026.matiasmassetti.com)
  3. Test access
  4. Migrate others gradually

**3. Automated Deployments:**
- **Timeline:** Month 2
- **Setup:** GitHub Actions
- **Flow:**
  - Push code to GitHub
  - Action builds Docker image
  - SSH to homelab
  - Pull and restart container
- **Result:** Same experience as Vercel!

**Total Savings:** $240/year âœ…

---

### 8.3 Priority 3: Document Management (Month 2)

**Paperless-ngx:**
- **Timeline:** February 2026
- **Time:** 1 hour setup
- **Purpose:**
  - Scan all documents
  - OCR everything
  - Full-text search
  - Auto-organize
  - Never lose a receipt!
- **Workflow:**
  1. Take photo of receipt
  2. Upload to Paperless
  3. Auto-OCR + tag
  4. Searchable forever!
- **Documents to Digitize:**
  - Bills
  - Receipts
  - Contracts
  - Tax documents
  - Manuals
  - Important papers
- **Benefits:**
  - âœ… Find any document in seconds
  - âœ… Never lose important papers
  - âœ… Automatic organization
  - âœ… Share with accountant easily
  - âœ… Backup of everything

---

### 8.4 Priority 4: Photo Management (Month 2-3)

**Replace Google Photos:**

**Option A: Photoprism**
- Advanced AI features
- Face recognition
- Object detection
- Places/maps
- Excellent quality

**Option B: Immich**
- More like Google Photos UI
- Mobile auto-upload
- Fast interface
- Modern design
- Active development

**Migration:**
1. Setup photo service
2. Upload Google Drive photos backup (282GB)
3. Download from Google Photos
4. Upload to Photoprism/Immich
5. Setup mobile auto-upload
6. Test for 1 month
7. Cancel Google Drive subscription

**Savings:** $100/year âœ…

---

### 8.5 Medium Priority Projects (Month 3+)

**1. Audiobookshelf:**
- Audiobooks + podcasts
- Perfect for walks/gym
- Mobile apps
- Sync progress

**2. Navidrome:**
- Personal music streaming
- Replace Spotify
- Subsonic-compatible
- Mobile apps

**3. Consolidate Databases:**
- Single PostgreSQL instance
- Multiple databases within
- Easier to manage
- Less resources

**4. Monitoring & Dashboards:**
- Grafana + Prometheus
- Beautiful visualizations
- Track everything
- Alerts via Telegram

**5. n8n (Automation):**
- Self-hosted Zapier
- Automate workflows
- Connect services
- Endless possibilities

---

## SECTION 9: GITHUB REPOSITORY (FEBRUARY 2026)

### 9.1 When to Create

**Timeline:** February 2026
**Why Wait:**
- NAS will be stable
- Services finalized
- Paths updated
- Best practices established
- Worth sharing with others

---

### 9.2 Repository Structure

```
homelab/
â”œâ”€â”€ README.md
â”‚   - Overview
â”‚   - Quick start
â”‚   - Screenshots
â”‚   - Features
â”‚
â”œâ”€â”€ docs/
â”‚   â”œâ”€â”€ knowledge-base.md
â”‚   â”œâ”€â”€ nas-setup-guide.md
â”‚   â”œâ”€â”€ network-diagram.md
â”‚   â”œâ”€â”€ services/
â”‚   â”‚   â”œâ”€â”€ jellyfin.md
â”‚   â”‚   â”œâ”€â”€ radarr-sonarr.md
â”‚   â”‚   â”œâ”€â”€ vaultwarden.md
â”‚   â”‚   â””â”€â”€ ...
â”‚   â””â”€â”€ troubleshooting.md
â”‚
â”œâ”€â”€ docker/
â”‚   â”œâ”€â”€ homelab/
â”‚   â”‚   â””â”€â”€ docker-compose.yml
â”‚   â”œâ”€â”€ projects/
â”‚   â”‚   â”œâ”€â”€ media-tracker/
â”‚   â”‚   â”œâ”€â”€ podcast-transcriber/
â”‚   â”‚   â””â”€â”€ usa-2026/
â”‚   â””â”€â”€ infrastructure/
â”‚       â””â”€â”€ docker-compose.yml
â”‚
â”œâ”€â”€ scripts/
â”‚   â”œâ”€â”€ backup.sh
â”‚   â”œâ”€â”€ update-containers.sh
â”‚   â”œâ”€â”€ disk-cleanup.sh
â”‚   â””â”€â”€ nas-mount-check.sh
â”‚
â”œâ”€â”€ configs/
â”‚   â”œâ”€â”€ netplan/
â”‚   â”‚   â””â”€â”€ static-ip.yaml
â”‚   â”œâ”€â”€ nginx/
â”‚   â”‚   â””â”€â”€ proxy-hosts/
â”‚   â”œâ”€â”€ fstab.example
â”‚   â””â”€â”€ environment.example
â”‚
â”œâ”€â”€ .github/
â”‚   â””â”€â”€ workflows/
â”‚       â”œâ”€â”€ docker-update.yml
â”‚       â””â”€â”€ backup-check.yml
â”‚
â””â”€â”€ .gitignore
    (exclude secrets, tokens, passwords)
```

---

### 9.3 What to Include

**âœ… Include:**
- All docker-compose files
- Configuration templates
- Setup scripts
- Documentation
- Network diagrams
- Troubleshooting guides
- Lessons learned

**âŒ Exclude (.gitignore):**
```
# Sensitive Data
*.env
**/secrets/
**/tokens/
docker-compose.override.yml

# Passwords
*password*
*secret*
*token*

# Personal Data
/media/
/downloads/
/backups/

# Cloudflare
cloudflare-token*
tunnel-credentials*
```

---

### 9.4 GitHub Actions Ideas

**Auto-Update Containers:**
```yaml
name: Update Docker Containers
on:
  schedule:
    - cron: '0 3 * * 0'  # Weekly, Sunday 3 AM
jobs:
  update:
    runs-on: ubuntu-latest
    steps:
      - name: SSH and update
        run: |
          ssh homelab "cd /opt/docker && docker compose pull && docker compose up -d"
```

**Backup Configs:**
```yaml
name: Backup Configurations
on:
  schedule:
    - cron: '0 2 * * *'  # Daily, 2 AM
jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - name: Pull configs from homelab
      - name: Commit to repo
      - name: Push to GitHub
```

---

## SECTION 10: LESSONS LEARNED

### 10.1 From Discovery Session (Dec 26, 2025)

**Technical Lessons:**
```
âœ… Always verify actual mount points
   - du -sh on symlinks shows 0
   - Check where symlinks point
   - Verify with df -h

âœ… exFAT works well for external drives
   - Cross-platform compatible
   - Handles large files
   - But no journaling (risk if power loss)

âœ… CasaOS adds helpful UI but overhead
   - Consider replacing with Portainer later
   - Or keep if you like it

âœ… Multiple Docker networks is normal
   - Each project creates its own
   - Not a problem
   - Can consolidate later

âœ… Google Drive backups can be HUGE
   - 282GB from one backup!
   - Plan for this in NAS storage

âœ… Corrupted files should be deleted ASAP
   - Don't waste space
   - Can re-download later

âœ… Docker images use ~8GB (not much)
   - Not the space problem
   - Media files are the hog
```

**Best Practices Identified:**
```
âœ… Keep 10-15% free space buffer
âœ… Regular cleanup of downloads folder
âœ… Delete corrupted files immediately
âœ… Verify backups exist before deleting
âœ… Use symlinks for flexibility
âœ… Document everything as you go
âœ… Test before mass migration
âœ… Keep external drive as backup initially
âœ… Monitor disk space weekly
âœ… Plan migrations during off-peak hours
```

**Surprises:**
```
ðŸŽ‰ You already have Ollama running!
   - Makes personal LLM setup easy
   - Just add Open WebUI

ðŸŽ‰ Network configuration is solid
   - Static IP properly configured
   - Cloudflare tunnel working great
   - No VPN confusion (not using Tailscale)

ðŸŽ‰ All services are stable
   - No major issues found
   - Good Docker setup
   - Well organized

âš ï¸ Disk 99% full!
   - But manageable until NAS
   - Just no downloads for 16 days
```

---

## SECTION 11: DECISION LOG

### December 26, 2025

**Decision: Survive with 59GB until NAS**
- **Reason:** Only 16 days until USA trip
- **Risk:** Tight but manageable
- **Action:** NO new downloads
- **Result:** Safe buffer, low risk

**Decision: Keep Google Drive backup (282GB)**
- **Reason:** Unsure if duplicates exist in current GDrive
- **Action:** Migrate to NAS, verify, then decide
- **Benefit:** No data loss risk

**Decision: Delete corrupted TV show**
- **What:** "Whose Line Is It Anyway" (19GB)
- **Reason:** Files unplayable on all devices
- **Action:** `rm -rf` the folder
- **Result:** 19GB freed, can re-download later

**Decision: Buy all 4 drives in January**
- **Reason:** Same total cost, full redundancy from start
- **Alternative Rejected:** 2 now, 2 later
- **Benefit:** 38TB with protection immediately

**Decision: Wait for GitHub until February**
- **Reason:** Document final state, not in-progress
- **Benefit:** Better documentation quality
- **Timeline:** After NAS stable

**Decision: Keep CasaOS for now**
- **Reason:** Still useful, working fine
- **Future:** Re-evaluate after NAS setup
- **Alternative:** Portainer + File Browser

**Decision: Use SHR (not Basic) from start**
- **Reason:** Redundancy is critical for 3.3TB data
- **With 4 drives:** 38TB usable, 1-disk redundancy
- **Protection:** Any 1 drive can fail safely

**Decision: No Tailscale**
- **Clarification:** Using Cloudflare only
- **Reason:** Works perfectly, no VPN needed
- **Future:** Maybe add later if wanted

---

## SECTION 12: NEXT STEPS

### Immediate (Now - Jan 10)

```
â˜ Upload this knowledge base to Claude Project
â˜ Save all files locally (Mac + Google Drive backup)
â˜ Monitor disk space weekly (df -h /DATA/Media)
â˜ NO new downloads
â˜ Review NAS setup guide
â˜ Prepare USA trip
â˜ Save shopping list
```

---

### January 11, 2026 (USA Purchase Day)

```
â˜ Shop for all NAS hardware
â˜ Verify model numbers match
â˜ Buy bubble wrap
â˜ Check all items before leaving store
â˜ Pack for return:
  - Drives in carry-on (NEVER checked!)
  - NAS in checked (bubble wrapped)
```

---

### January 21-25, 2026 (NAS Setup Week)

```
â˜ Follow setup guide step-by-step
â˜ Don't rush!
â˜ Verify each step
â˜ Document any issues
â˜ Take photos
â˜ Test thoroughly
â˜ Celebrate when done! ðŸŽ‰
```

---

### February 2026+ (Optimization)

```
â˜ Install Vaultwarden (Week 1)
â˜ Install AdGuard Home (Week 1)
â˜ Setup personal LLM (Week 2)
â˜ Replace Vercel (Week 3-4)
â˜ Install Paperless-ngx (Month 2)
â˜ Setup photo management (Month 2)
â˜ Push to GitHub (Month 2)
â˜ Blog about journey (Month 3)
â˜ Enjoy 38TB of freedom! ðŸš€
```

---

## APPENDIX

### A. Quick Command Reference

**System Monitoring:**
```bash
# Disk usage
df -h
du -sh /mnt/nas/*

# Memory
free -h

# CPU
htop

# Network
ip a
ss -tulpn
```

**Docker:**
```bash
# View containers
docker ps

# Start all
cd /opt/docker && docker compose up -d

# Restart
docker compose restart <service>

# Logs
docker compose logs -f <service>

# Update
docker compose pull && docker compose up -d

# Cleanup
docker system prune -a
```

**NAS:**
```bash
# Check mount
df -h | grep nas

# Show exports
showmount -e 192.168.1.240

# Manual mount
sudo mount -t nfs 192.168.1.240:/volume1/Media /mnt/nas

# Unmount
sudo umount /mnt/nas
```

---

### B. Service URLs

**External (Cloudflare):**
```
https://media.matiasmassetti.com       (Jellyfin)
https://radarr.matiasmassetti.com      (Radarr)
https://sonarr.matiasmassetti.com      (Sonarr)
https://descargas.matiasmassetti.com   (qBittorrent)
https://pedidos.matiasmassetti.com     (Jellyseerr)
https://home.matiasmassetti.com        (Homarr/CasaOS)
https://status.matiasmassetti.com      (Uptime Kuma)
```

**Internal:**
```
http://192.168.1.1                     (Router)
http://192.168.1.239                   (CasaOS)
http://192.168.1.239:8096              (Jellyfin)
http://192.168.1.239:7878              (Radarr)
http://192.168.1.239:8989              (Sonarr)
http://192.168.1.239:9000              (Portainer)
http://192.168.1.240:5000              (NAS DSM - future)
```

---

### C. Important File Locations

**System:**
```
/etc/netplan/               (Network config)
/etc/fstab                  (Mount points)
~/.ssh/                     (SSH keys)
/var/log/                   (System logs)
```

**Docker:**
```
/opt/docker/docker-compose.yml
/opt/docker/configs/<service>/
/opt/docker/downloads/
```

**Media (Current):**
```
/DATA/Media/Peliculas/      (2.9TB)
/DATA/Media/Series/         (418GB)
```

**Media (Future - NAS):**
```
/mnt/nas/Peliculas/
/mnt/nas/Series/
/mnt/nas/Documents/
/mnt/nas/Photos/
/mnt/nas/Backups/
```

---

### D. Shopping List

**Amazon.com (Jan 11, 2026):**
```
â˜ Synology DS423                    $379.99
â˜ WD Red Pro 14TB (WD142KFGX) Ã—4   $1,159.96
â˜ TP-Link TL-SG105                  $12.99
â˜ Cable Matters Cat6 (5-pack)       $12.49
â˜ Argentina adapter (2-pack)        $6.99
â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
TOTAL:                              $1,572.42
Plus bubble wrap:                   ~$15
GRAND TOTAL:                        ~$1,587
```

**CRITICAL:** Model WD142KFGX - all drives must match!

---

### E. Contact Information

**Support:**
- Synology: support.synology.com
- Western Digital: support.wdc.com
- TP-Link: tp-link.com/support

**Homelab Resources:**
- r/selfhosted (Reddit)
- r/homelab (Reddit)
- TechnoTim (YouTube)
- Awesome-Selfhosted (GitHub)

**Your Setup:**
- Domain: matiasmassetti.com (Porkbun)
- DNS: Cloudflare
- Claude Project: "Homelab Setup & Management 2026"

---

**END OF KNOWLEDGE BASE**

**Last Updated:** December 26, 2025 11:45 PM ART  
**Next Update:** After NAS setup (January 2026)  
**Version:** 2.0 (Ultimate Edition - Complete Merge)

---

**Status:** âœ… Complete and comprehensive  
**Disk Space:** âœ… 59GB free (manageable)  
**Documentation:** âœ… All hardware + all discoveries  
**Ready for:** ðŸš€ January 2026 NAS deployment!
