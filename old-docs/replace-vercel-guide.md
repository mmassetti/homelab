# Improved Download Workflow Guide
**Replace:** Manual torrent download on Gaming PC + WinSCP transfer  
**With:** Automated Radarr/Sonarr + qBittorrent on Mini PC

---

## CURRENT WORKFLOW (Inefficient)

```
1. Gaming PC: Find 2160p torrent with subs
2. Gaming PC: Download via torrent client
3. Gaming PC: Wait for download (hours)
4. Gaming PC: Open WinSCP
5. Gaming PC â†’ Mini PC: Manual file transfer
6. Mini PC: Move file to correct folder
7. Jellyfin: Manually scan library
```

**Problems:**
- âŒ Gaming PC must stay on during download
- âŒ Manual file management
- âŒ No automatic quality selection
- âŒ No subtitle automation
- âŒ Multiple steps, prone to error

---

## NEW WORKFLOW (Automated)

```
1. YOU: Add movie/show to Jellyseerr
   OR: Add directly in Radarr/Sonarr
2. RADARR/SONARR: Search for best 2160p release
3. QBITTORRENT: Download on mini PC
4. RADARR/SONARR: Move to correct folder with proper naming
5. BAZARR: Download missing subtitles automatically
6. JELLYFIN: Auto-scan and add to library
```

**Benefits:**
- âœ… Fully automated
- âœ… Mini PC downloads (no gaming PC needed)
- âœ… Automatic quality selection
- âœ… Automatic subtitle download
- âœ… Proper file organization
- âœ… One-click from phone/browser

---

## SETUP GUIDE

### Step 1: Configure qBittorrent

**Access qBittorrent:**
```
URL: http://descargas.matiasmassetti.com
OR: http://192.168.1.239:8080

Default login:
- Username: admin
- Password: adminadmin (change this!)
```

**Settings to Configure:**

1. **Change Default Password:**
   - Tools â†’ Options â†’ Web UI
   - Change password to something secure

2. **Set Download Location:**
   - Tools â†’ Options â†’ Downloads
   - Default Save Path: `/downloads`
   - Keep incomplete torrents in: `/downloads/incomplete`
   - Copy .torrent files to: `/downloads/torrents`
   - âœ“ Automatically add torrents from: `/downloads/watch`

3. **Connection Settings:**
   - Tools â†’ Options â†’ Connection
   - Listening Port: 6881
   - âœ“ Use UPnP/NAT-PMP port forwarding (if available)

4. **BitTorrent Settings:**
   - Tools â†’ Options â†’ BitTorrent
   - Privacy: âœ“ Enable anonymous mode
   - Torrent Queueing: âœ“
   - Maximum active torrents: 5
   - Maximum active downloads: 3

---

### Step 2: Configure Radarr (Movies)

**Access Radarr:**
```
URL: http://radarr.matiasmassetti.com
OR: http://192.168.1.239:7878
```

**Initial Setup:**

1. **Add Download Client (qBittorrent):**
   - Settings â†’ Download Clients â†’ Add (+)
   - Select: qBittorrent
   - Name: qBittorrent
   - Host: localhost
   - Port: 8080
   - Username: admin
   - Password: [your qBittorrent password]
   - Category: radarr-movies
   - âœ“ Test â†’ Save

2. **Configure Media Management:**
   - Settings â†’ Media Management
   - Movie Naming:
     - âœ“ Rename Movies
     - Standard Movie Format: 
       `{Movie Title} ({Release Year}) [imdbid-{ImdbId}] - {Quality Full}`
   - Folders:
     - âœ“ Create empty movie folders
     - âœ“ Delete empty folders
   - Importing:
     - âœ“ Skip Free Space Check (NAS has tons of space)
   - File Management:
     - âœ“ Unmonitor Deleted Movies
     - âœ“ Use Hardlinks instead of Copy (saves space)
   - Root Folders:
     - Add: `/movies` (this is /mnt/nas/Peliculas in container)

3. **Configure Quality Profiles:**
   - Settings â†’ Profiles
   - Edit "Any" profile:
     - Upgrades Allowed: âœ“
     - Upgrade Until: 2160p (4K)
     - Language: Spanish + English
   - Or create "4K Only" profile:
     - Only allow: 2160p
     - Cutoff: 2160p

4. **Add Indexers (Torrent Sites):**
   - Settings â†’ Indexers â†’ Add (+)
   
   **Option A: Use Jackett (Your Current Setup):**
   ```
   You already have Jackett running at:
   http://192.168.1.239:9117
   
   In Jackett:
   1. Add your favorite torrent sites
   2. Copy API key
   
   In Radarr:
   1. Add â†’ Torznab â†’ Custom
   2. Name: [Tracker Name via Jackett]
   3. URL: http://localhost:9117/api/v2.0/indexers/[indexer-id]/results/torznab/
   4. API Key: [Jackett API key]
   5. Test â†’ Save
   
   Repeat for each indexer in Jackett
   ```
   
   **Option B: Use Prowlarr (Better Alternative):**
   ```
   Consider replacing Jackett with Prowlarr
   - More modern
   - Better integration with Radarr/Sonarr
   - Automatic sync of indexers
   
   I can help set this up later if you want!
   ```

5. **General Settings:**
   - Settings â†’ General
   - Security:
     - Authentication: None (you're using Cloudflare tunnel)
   - Updates:
     - Branch: master
     - âœ“ Automatic

---

### Step 3: Configure Sonarr (TV Shows)

**Access Sonarr:**
```
URL: http://sonarr.matiasmassetti.com
OR: http://192.168.1.239:8989
```

**Setup (Same as Radarr):**

1. **Add Download Client:**
   - Settings â†’ Download Clients â†’ Add (+)
   - qBittorrent
   - Category: sonarr-tv

2. **Media Management:**
   - Standard Episode Format:
     `{Series Title} - S{season:00}E{episode:00} - {Episode Title} [{Quality Full}]`
   - Season Folder Format:
     `Season {season:00}`
   - Root Folder: `/tv` (this is /mnt/nas/Series)

3. **Quality Profile:**
   - Create "4K Profile"
   - Upgrade until: 2160p

4. **Add Indexers:**
   - Same as Radarr (use Jackett)

---

### Step 4: Configure Bazarr (Subtitles)

**Access Bazarr:**
```
URL: http://bazarr.matiasmassetti.com
OR: http://192.168.1.239:6767
```

**Setup:**

1. **Connect to Radarr:**
   - Settings â†’ Radarr
   - âœ“ Enabled
   - Address: http://radarr:7878
   - API Key: [get from Radarr Settings â†’ General]
   - Test â†’ Save

2. **Connect to Sonarr:**
   - Settings â†’ Sonarr
   - Same as above, port 8989

3. **Add Subtitle Providers:**
   - Settings â†’ Providers
   - Add popular ones:
     - OpenSubtitles
     - Subscene
     - Addic7ed
   
4. **Languages:**
   - Settings â†’ Languages
   - Languages Filter: Spanish, English
   - Default Enabled: Spanish, English

5. **Subtitle Settings:**
   - Settings â†’ Subtitles
   - âœ“ Single Language
   - Subtitle Folder: same as media (default)

---

### Step 5: Configure Jellyseerr (Optional but AMAZING)

**You already have this running!**

```
URL: http://pedidos.matiasmassetti.com
OR: http://192.168.1.239:5055
```

**Setup:**

1. **Sign in with Jellyfin:**
   - Use your Jellyfin credentials
   - http://192.168.1.239:8096

2. **Connect Radarr:**
   - Settings â†’ Radarr
   - Server Name: Radarr
   - Hostname/IP: radarr
   - Port: 7878
   - API Key: [from Radarr]
   - Default Quality Profile: 4K
   - Default Root Folder: /movies
   - âœ“ Enable Scan
   - Test â†’ Save

3. **Connect Sonarr:**
   - Settings â†’ Sonarr
   - Same process, port 8989

4. **Configure:**
   - Settings â†’ General
   - âœ“ Enable New Jellyfin Season Requests
   - Request Limits: Set per your preference

---

## USAGE - NEW WORKFLOW

### Method 1: Using Jellyseerr (EASIEST)

**From any device:**

```
1. Go to: http://pedidos.matiasmassetti.com

2. Search for movie/show

3. Click "Request"

4. Select quality (4K/1080p)

5. Click "Request"

6. DONE! Wait for download

7. Get notification when ready

8. Watch in Jellyfin!
```

**This works from:**
- Your phone (anywhere)
- Browser
- Even share with family/friends!

---

### Method 2: Using Radarr Directly

```
1. Go to: http://radarr.matiasmassetti.com

2. Click "Add Movies"

3. Search for movie

4. Select quality profile: 4K

5. Click "Add Movie"

6. Radarr automatically:
   - Searches indexers
   - Picks best release
   - Sends to qBittorrent
   - Waits for download
   - Renames and moves file
   - Tells Jellyfin to scan

7. DONE!
```

---

### Method 3: Using Sonarr for TV Shows

```
Same as Radarr but for series!

Bonus: Sonarr monitors for new episodes
- Automatically downloads new episodes when released
- Set monitoring: Future episodes only
```

---

## ADVANCED: QUALITY PROFILES

### Creating Custom "4K with Embedded Subs" Profile

**In Radarr:**

```
Settings â†’ Profiles â†’ Add Profile

Name: "4K Embedded Subs Preferred"

Allowed:
- 2160p WEB-DL
- 2160p BluRay
- 2160p Remux

Preferred Words (Settings â†’ Custom Formats):
Create custom formats with these keywords:
- "subs" +10
- "embedded" +10
- "spa" +5
- "latino" +5
- "dual" +10

This makes Radarr prefer releases with embedded subs!
```

---

## MONITORING & NOTIFICATIONS

### Setup Notifications in Radarr/Sonarr

**Telegram Bot (Recommended):**

```
1. Create Telegram bot: @BotFather
2. Get bot token
3. Get your chat ID

4. In Radarr/Sonarr:
   - Settings â†’ Connect â†’ Add â†’ Telegram
   - Bot Token: [your token]
   - Chat ID: [your chat ID]
   - âœ“ On Grab
   - âœ“ On Import
   - âœ“ On Health Issue
```

**Now you get notifications:**
- "Breaking Bad S05E16 grabbed!"
- "The Matrix (1999) downloaded!"
- "Download failed: XYZ"

---

## MIGRATION FROM OLD WORKFLOW

### What About Your Existing Files?

**They're fine!** Radarr/Sonarr can:

1. **Import Existing Library:**
   ```
   Radarr â†’ Library Import
   - Path: /movies
   - âœ“ Add movies already in path
   - This catalogs what you already have
   ```

2. **Rename Existing Files (Optional):**
   ```
   Movie â†’ Edit â†’ Organize
   - Radarr will rename to proper format
   - Before: "Matrix.2160p.mkv"
   - After: "The Matrix (1999) [imdbid-tt0133093] - 2160p.mkv"
   ```

3. **Monitor for Upgrades:**
   ```
   If you have 1080p, Radarr can:
   - Automatically search for 4K version
   - Download and replace
   - Delete old 1080p file
   ```

---

## TROUBLESHOOTING

### Radarr Can't Connect to qBittorrent

**Check:**
```bash
# Is qBittorrent running?
docker ps | grep qbittorrent

# Can Radarr reach it?
docker exec radarr curl http://qbittorrent:8080

# Check docker network
docker network inspect homelab
# Both containers should be in same network
```

### Downloads Start but Don't Import

**Common issues:**
1. **Permissions:**
   ```bash
   # Check /mnt/nas permissions
   ls -la /mnt/nas/Peliculas
   
   # Should be owned by user 1000
   sudo chown -R 1000:1000 /mnt/nas/Peliculas
   ```

2. **Paths:**
   - Radarr sees: `/movies`
   - Docker maps: `/movies` â†’ `/mnt/nas/Peliculas`
   - Files must end up in `/mnt/nas/Peliculas`

3. **Download Client Settings:**
   - Category must match
   - Remove completed: No (let Radarr handle it)

### No Search Results

**Check Indexers:**
```
Radarr â†’ System â†’ Tasks â†’ Refresh Indexers

Check each indexer:
- Settings â†’ Indexers â†’ Test
- If fails, reconfigure or remove

Add more indexers via Jackett
```

---

## COMPARISON: OLD vs NEW

### Downloading "Dune: Part Two (2024)"

**OLD METHOD:**
```
1. Search for "Dune Part Two 2160p" on torrent site - 5 min
2. Find one with Spanish subs - 10 min
3. Download on gaming PC - 3 hours
4. Gaming PC must stay on - 3 hours
5. Open WinSCP - 2 min
6. Transfer file (180GB) - 30 min
7. Move to correct folder - 2 min
8. Scan Jellyfin library - 1 min
9. Search for subtitles if missing - 10 min

TOTAL TIME: ~4 hours active work
GAMING PC: Must be on 3+ hours
```

**NEW METHOD:**
```
1. Jellyseerr: Search "Dune Part Two" - 30 sec
2. Click "Request 4K" - 10 sec
3. Go do something else - 0 min

[Background - no user intervention]
- Radarr searches indexers - automatic
- qBittorrent downloads - automatic (3 hours)
- Radarr imports and renames - automatic
- Bazarr downloads subs - automatic
- Jellyfin scans - automatic

4. Get Telegram notification "Ready!" - 0 min
5. Watch movie - 0 min

TOTAL TIME: 40 seconds active work
GAMING PC: Not needed at all
```

---

## FINAL SETUP CHECKLIST

After setting everything up, verify:

```
â˜ qBittorrent accessible and configured
â˜ Radarr connected to qBittorrent
â˜ Radarr has at least 3 indexers working
â˜ Radarr can import test movie
â˜ Sonarr connected to qBittorrent  
â˜ Sonarr has indexers working
â˜ Sonarr can import test show
â˜ Bazarr connected to Radarr & Sonarr
â˜ Bazarr downloads test subtitle
â˜ Jellyseerr connected to all services
â˜ Test full workflow: Request â†’ Download â†’ Watch
â˜ Telegram notifications working (optional)
```

---

## BONUS: CASAOS ALTERNATIVES

**You asked about CasaOS - here are alternatives:**

### Keep CasaOS If:
- âœ… You like the UI
- âœ… It works for you
- âœ… Not causing issues

### Consider Replacing With:

**1. No Dashboard (Minimalist)**
```
Just use:
- Homarr (you already have this!)
- Access services via Cloudflare tunnels
- Remove CasaOS overhead
```

**2. Portainer Only**
```
You already have Portainer!
- Lightweight
- Great Docker management
- No extra overhead
- Keep Homarr for pretty dashboard
```

**3. Cockpit (Ubuntu Server UI)**
```
sudo apt install cockpit
- Lightweight
- Built for Ubuntu Server
- System monitoring
- Docker plugin available
```

**My recommendation:** 
- Keep CasaOS if you like it
- Add Homarr as main dashboard (you have it!)
- Access everything via Cloudflare tunnels

---

## NEXT STEPS

**Priority Order:**

1. âœ… Setup NAS (from main guide)
2. âœ… Migrate data to NAS
3. âœ… Configure Radarr + qBittorrent
4. âœ… Test with 1-2 movies
5. âœ… Configure Sonarr
6. âœ… Setup Bazarr for subs
7. âœ… Configure Jellyseerr
8. âœ… Setup Telegram notifications
9. âœ… Import existing library
10. âœ… Enjoy automated downloads!

---

**You'll never use WinSCP again!**