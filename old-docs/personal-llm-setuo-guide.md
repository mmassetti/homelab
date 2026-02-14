# Personal Homelab LLM Setup Guide
**Run your own ChatGPT-style assistant that knows YOUR homelab!**

---

## Overview

You'll create a personal AI assistant that:
- âœ… Runs 100% locally on your mini PC (free!)
- âœ… Knows all about YOUR homelab setup (RAG = Retrieval Augmented Generation)
- âœ… Answers questions about your services, configs, troubleshooting
- âœ… Never forgets (even when conversations get long)
- âœ… Works offline (no internet needed)
- âœ… Private (your data never leaves your network)

**Cost:** $0 + ~$2-5/month electricity

---

## PART 1: Basic Setup (Ollama + Open WebUI)

### Step 1: Add Services to Docker Compose

**Edit your docker-compose.yml:**

```yaml
# Add these services to /opt/docker/docker-compose.yml

  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    volumes:
      - /opt/docker/configs/ollama:/root/.ollama
    ports:
      - "11434:11434"
    restart: unless-stopped
    networks:
      - homelab

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    ports:
      - "3000:8080"
    volumes:
      - /opt/docker/configs/open-webui:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - WEBUI_AUTH=false
    restart: unless-stopped
    networks:
      - homelab
    depends_on:
      - ollama
```

### Step 2: Start Services

```bash
cd /opt/docker
docker compose up -d ollama open-webui

# Check they're running
docker ps | grep ollama
docker ps | grep open-webui
```

### Step 3: Download Your First Model

```bash
# Enter Ollama container
docker exec -it ollama bash

# Download Llama 3.1 8B (recommended)
ollama pull llama3.1:8b

# This downloads ~4.7GB - takes a few minutes

# Verify
ollama list

# Exit container
exit
```

**Alternative models to try:**
```bash
# Faster, smaller (good for testing)
ollama pull llama3.1:latest  # Same as 8B

# Better quality, slower
ollama pull llama3.1:13b     # Needs 16GB RAM

# Coding specialist
ollama pull deepseek-coder:6.7b

# Spanish language specialist
ollama pull llama3.1:8b-instruct-es  # If available
```

### Step 4: Access Your LLM

**Open browser:**
```
http://192.168.1.239:3000

OR setup Cloudflare tunnel:
https://ai.matiasmassetti.com
```

**First time:**
1. You'll see chat interface (like ChatGPT)
2. Select model: llama3.1:8b
3. Start chatting!

**Test it:**
```
You: Hello! Can you help me with my homelab?
AI: Of course! I'd be happy to help with your homelab...
```

---

## PART 2: RAG Setup (Make it Know YOUR Homelab)

### What is RAG?

**RAG = Retrieval Augmented Generation**

```
Without RAG:
You: "What's my Jellyfin URL?"
AI: "I don't know your specific setup..."

With RAG:
You: "What's my Jellyfin URL?"
AI: "Your Jellyfin is at http://media.matiasmassetti.com 
     and locally at http://192.168.1.239:8096"
```

**How it works:**
1. You upload your homelab docs to Open WebUI
2. AI searches docs when you ask questions
3. AI answers using YOUR specific information

### Step 1: Create Homelab Documentation

**Create a master document with all your info:**

```bash
# On your mini PC
mkdir -p ~/homelab-docs

# Create main documentation file
nano ~/homelab-docs/homelab-knowledge.md
```

**What to include:**

```markdown
# My Homelab Knowledge Base

## Network Information
- Router IP: 192.168.1.1
- Mini PC IP: 192.168.1.239
- NAS IP: 192.168.1.240
- Network: 192.168.1.0/24

## Hardware
### Mini PC (Beelink SER8)
- CPU: Ryzen 7 8745HS (8C/16T)
- RAM: 32GB DDR5
- Storage: 913GB NVMe + NAS mount
- OS: Ubuntu Server 24.04
- Hostname: homelab

### NAS (Synology DS423)
- Model: DS423
- Drives: 4x WD Red Pro 14TB (WD142KFGX)
- Storage Pool: SHR with 1-disk redundancy
- Usable Space: 38TB
- Mount: /mnt/nas

## Services (Docker)

### Jellyfin (Media Server)
- URL: http://media.matiasmassetti.com
- Local: http://192.168.1.239:8096
- Container: jellyfin
- Config: /opt/docker/configs/jellyfin
- Media: /mnt/nas/Peliculas (movies), /mnt/nas/Series (shows)

### Radarr (Movie Manager)
- URL: http://radarr.matiasmassetti.com
- Local: http://192.168.1.239:7878
- Container: radarr
- Config: /opt/docker/configs/radarr

### Sonarr (TV Manager)
- URL: http://sonarr.matiasmassetti.com
- Local: http://192.168.1.239:8989
- Container: sonarr

### qBittorrent (Downloader)
- URL: http://descargas.matiasmassetti.com
- Local: http://192.168.1.239:8080
- Downloads: /opt/docker/downloads

### Jellyseerr (Request Manager)
- URL: http://pedidos.matiasmassetti.com
- Local: http://192.168.1.239:5055

## Common Tasks

### Restart Jellyfin
```bash
cd /opt/docker
docker compose restart jellyfin
```

### Check NAS Mount
```bash
df -h | grep nas
# Should show: 192.168.1.240:/volume1/Media mounted at /mnt/nas
```

### View Service Logs
```bash
docker compose logs -f [service-name]
# Example: docker compose logs -f jellyfin
```

### Update All Containers
```bash
cd /opt/docker
docker compose pull
docker compose up -d
```

## Troubleshooting

### Jellyfin Not Showing Movies
1. Check NAS mount: `df -h | grep nas`
2. Check permissions: `ls -la /mnt/nas/Peliculas`
3. Restart Jellyfin: `docker compose restart jellyfin`
4. Scan library in Jellyfin web UI

### Radarr Can't Connect to qBittorrent
1. Check both containers running: `docker ps`
2. Check they're on same network: `docker network inspect homelab`
3. Verify qBittorrent settings in Radarr
4. Test connection: `docker exec radarr curl http://qbittorrent:8080`

### NFS Mount Lost After Reboot
1. Check /etc/fstab entry exists
2. Remount: `sudo mount -a`
3. Check NAS is accessible: `ping 192.168.1.240`

## File Locations

### Docker Configs
- Path: /opt/docker/configs/
- Contains: configs for all services

### Docker Compose
- File: /opt/docker/docker-compose.yml
- Backup: /opt/docker/docker-compose.yml.backup-YYYYMMDD

### Media Storage
- Movies: /mnt/nas/Peliculas
- TV Shows: /mnt/nas/Series
- Downloads: /opt/docker/downloads

### NAS Shares
- NFS Mount: /mnt/nas
- NAS Path: /volume1/Media/

## Cloudflare Tunnels

All services accessible via:
- media.matiasmassetti.com â†’ Jellyfin
- radarr.matiasmassetti.com â†’ Radarr
- sonarr.matiasmassetti.com â†’ Sonarr
- descargas.matiasmassetti.com â†’ qBittorrent
- pedidos.matiasmassetti.com â†’ Jellyseerr
- home.matiasmassetti.com â†’ Homarr
- status.matiasmassetti.com â†’ Uptime Kuma

Tunnel configured via cloudflared container.

## Backup Strategy

1. NAS internal: Btrfs snapshots daily
2. NAS to external USB: Weekly via Hyper Backup
3. Docker configs: Manual backups before changes
4. Important: 3.6TB external drive kept as emergency backup

## Power Management

- Mini PC: Runs 24/7 (~30-50W)
- NAS: Runs 24/7 (~20W)
- Total: ~70W continuous
- Monthly cost: ~$5 USD

## Future Plans

- Add UPS for power protection
- Implement Plex alongside Jellyfin (comparison)
- Setup automated backups to cloud
- Explore Proxmox for virtualization
```

**Save and exit:** `Ctrl+O`, `Enter`, `Ctrl+X`

---

### Step 2: Upload Documentation to Open WebUI

**Method 1: Via Web Interface (Easiest)**

```
1. Go to: http://192.168.1.239:3000

2. Click your profile icon (top right)

3. Select "Documents"

4. Click "Upload Document"

5. Select your homelab-knowledge.md file

6. Wait for processing (creates embeddings)

7. Done! Now AI can reference this when answering
```

**Method 2: Multiple Documents**

You can upload:
- âœ… All your markdown guides (NAS setup, download workflow, etc.)
- âœ… Docker compose files
- âœ… Configuration files
- âœ… Troubleshooting logs
- âœ… Network diagrams

---

### Step 3: Test RAG

**Chat with your AI:**

```
You: What's my Jellyfin URL?

AI: Your Jellyfin server is accessible at:
- Public URL: http://media.matiasmassetti.com
- Local IP: http://192.168.1.239:8096

The container is named 'jellyfin' and the config 
is stored at /opt/docker/configs/jellyfin.

Would you like help with anything specific about Jellyfin?
```

**More examples:**

```
You: How do I restart Radarr?

AI: To restart Radarr, run:
```
cd /opt/docker
docker compose restart radarr
```

Then check the logs with:
```
docker compose logs -f radarr
```

Would you like me to help troubleshoot something specific?
```

---

## PART 3: Advanced Features

### Feature 1: Web Search Integration

**Enable internet access for your LLM:**

```
Open WebUI Settings â†’ Admin â†’ Web Search
- Enable: SearXNG or DuckDuckGo
- Now AI can search web AND your docs!
```

**Example:**
```
You: What's the latest version of Jellyfin?
AI: [searches web] The latest stable version is 10.9.x...

You: Should I update my Jellyfin? Check my current version.
AI: [checks your docs] You're running Jellyfin from the 
    latest linuxserver.io image. Let me check if there's 
    an update available...
```

---

### Feature 2: Code Interpreter

**Let AI run Python code:**

```
Open WebUI Settings â†’ Code Interpreter
- Enable: âœ“
```

**Example:**
```
You: Calculate how many 4K movies I can store on my NAS

AI: Let me calculate that:

[runs code]
nas_capacity = 38 * 1000  # 38TB in GB
movie_size = 50  # Average 4K movie in GB
movies = nas_capacity / movie_size
print(f"You can store approximately {movies:.0f} 4K movies")

Result: You can store approximately 760 4K movies!
```

---

### Feature 3: Memory

**Your AI remembers conversations:**

```
Open WebUI Settings â†’ Memory
- Enable: âœ“
- Auto-save important facts
```

**Example:**
```
Day 1:
You: My favorite TV show is Breaking Bad
AI: Got it! I'll remember that.

Day 30:
You: Recommend a show to download
AI: Since you love Breaking Bad, you might enjoy 
     Better Call Saul, Ozark, or The Wire...
```

---

### Feature 4: Tools/Functions

**Let AI execute commands on your server:**

âš ï¸ **ADVANCED - Be careful with this!**

```python
# Create custom tools in Open WebUI
# Example: Restart service tool

def restart_service(service_name):
    """Restart a Docker service"""
    import subprocess
    result = subprocess.run(
        ['docker', 'compose', 'restart', service_name],
        cwd='/opt/docker',
        capture_output=True
    )
    return result.stdout.decode()
```

**Then ask:**
```
You: Restart my Jellyfin service
AI: [uses tool] Restarting Jellyfin...
    Container jellyfin restarted successfully!
```

---

## PART 4: Cloudflare Tunnel Setup

### Make Your AI Accessible from Anywhere

**Add to Cloudflare tunnel config:**

```yaml
# In your cloudflared configuration

ingress:
  - hostname: ai.matiasmassetti.com
    service: http://192.168.1.239:3000
```

**Then access from anywhere:**
```
https://ai.matiasmassetti.com

Ask your homelab questions from:
- Your phone (anywhere)
- Work computer
- Traveling
- Friend's house
```

---

## PART 5: Model Comparison

### Models You Can Run on Your Hardware:

**Llama 3.1 8B** â­ **RECOMMENDED**
```
Size: ~4.7GB
RAM: ~8GB
Speed: Very fast (50-100 tokens/sec)
Quality: Excellent (GPT-3.5 level)
Use for: Everything! General assistant

Download: ollama pull llama3.1:8b
```

**Llama 3.1 13B**
```
Size: ~7.6GB
RAM: ~16GB
Speed: Medium (20-40 tokens/sec)
Quality: Outstanding (GPT-4 level in some tasks)
Use for: Complex questions, better reasoning

Download: ollama pull llama3.1:13b
```

**DeepSeek Coder 6.7B**
```
Size: ~4GB
RAM: ~8GB
Speed: Very fast
Quality: Excellent for code
Use for: Coding help, script generation

Download: ollama pull deepseek-coder:6.7b
```

**Mistral 7B**
```
Size: ~4.1GB
RAM: ~8GB
Speed: Very fast
Quality: Excellent
Use for: Alternative to Llama, sometimes better

Download: ollama pull mistral:7b
```

**Mixtral 8x7B** (Advanced)
```
Size: ~26GB
RAM: 32GB+ (your limit!)
Speed: Slow (5-15 tokens/sec)
Quality: Amazing (GPT-4 competitive)
Use for: Complex tasks when you have time

Download: ollama pull mixtral:8x7b
Warning: Will use almost all your RAM!
```

---

## PART 6: Use Cases for Your Homelab

### Use Case 1: Troubleshooting Assistant

```
You: My Radarr can't download movies. Help me debug.

AI: Let me help you troubleshoot. Based on your setup:

1. Check if Radarr container is running:
   docker ps | grep radarr

2. Check Radarr logs for errors:
   docker compose logs -f radarr

3. Common issues:
   - qBittorrent not accessible (check it's on homelab network)
   - Indexer problems (check Jackett)
   - Disk space (check: df -h)
   - Permissions (check /mnt/nas/Peliculas ownership)

What error do you see in the Radarr logs?
```

---

### Use Case 2: Configuration Generator

```
You: Create a Docker service for Plex to compare with Jellyfin

AI: Here's the Docker Compose service for Plex:

```yaml
  plex:
    image: lscr.io/linuxserver/plex:latest
    container_name: plex
    network_mode: host
    environment:
      - PUID=1000
      - PGID=1000
      - VERSION=docker
      - TZ=America/Argentina/Buenos_Aires
    volumes:
      - /opt/docker/configs/plex:/config
      - /mnt/nas/Peliculas:/movies
      - /mnt/nas/Series:/tv
    restart: unless-stopped
```

Add this to your docker-compose.yml and run:
docker compose up -d plex

Then access Plex at: http://192.168.1.239:32400/web
```

---

### Use Case 3: Learning Assistant

```
You: Explain how NFS works in my setup

AI: In your setup, NFS (Network File System) works like this:

[Draws ASCII diagram]
NAS (192.168.1.240)
  â””â”€â”€ Shares: /volume1/Media
           â”‚
           â”‚ NFS Protocol (over network)
           â†“
Mini PC (192.168.1.239)
  â””â”€â”€ Mounts at: /mnt/nas
           â”‚
           â”‚ Docker bind mounts
           â†“
  Docker Containers
    â”œâ”€â”€ Jellyfin sees: /data/movies â†’ /mnt/nas/Peliculas
    â””â”€â”€ Radarr sees: /movies â†’ /mnt/nas/Peliculas

Benefits:
1. Centralized storage on NAS
2. All containers access same files
3. No data duplication
4. NAS handles RAID/backups

Your /etc/fstab entry:
192.168.1.240:/volume1/Media /mnt/nas nfs defaults,_netdev 0 0

Want me to explain any specific part?
```

---

### Use Case 4: Monitoring & Alerts

```
You: Create a script to check if all my services are healthy

AI: Here's a health check script for your homelab:

```bash
#!/bin/bash
# homelab-health-check.sh

echo "=== Homelab Health Check ==="
echo ""

# Check Docker services
echo "Docker Services:"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "jellyfin|radarr|sonarr|qbittorrent"

echo ""
echo "NAS Mount:"
df -h | grep nas || echo "âš ï¸  NAS not mounted!"

echo ""
echo "Disk Space:"
df -h / | tail -1

echo ""
echo "Memory:"
free -h | grep Mem

echo ""
echo "Service URLs:"
curl -s -o /dev/null -w "Jellyfin: %{http_code}\n" http://localhost:8096
curl -s -o /dev/null -w "Radarr: %{http_code}\n" http://localhost:7878
```

Save this and run daily via cron!
```

---

## PART 7: Tips & Best Practices

### Optimize Performance

```bash
# 1. Use GPU acceleration (if supported)
# Your Radeon 780M can help!

# Check if Ollama detects GPU:
docker exec ollama ollama run llama3.1:8b
# Look for: "GPU detected: AMD Radeon 780M"

# 2. Limit concurrent requests
# In Open WebUI settings:
# Max concurrent requests: 1-2
# (Prevents slowdown when multiple people use it)

# 3. Use quantized models
ollama pull llama3.1:8b-q4_0  # More compressed, faster
```

---

### Keep Models Updated

```bash
# Check for updates monthly
docker exec ollama ollama list

# Update a model
docker exec ollama ollama pull llama3.1:8b

# Remove old unused models
docker exec ollama ollama rm old-model-name
```

---

### Backup Your AI Configuration

```bash
# Backup Open WebUI data (includes uploaded docs!)
tar -czf ~/backups/open-webui-$(date +%Y%m%d).tar.gz \
  /opt/docker/configs/open-webui

# Backup Ollama models (large files!)
tar -czf ~/backups/ollama-models-$(date +%Y%m%d).tar.gz \
  /opt/docker/configs/ollama
```

---

## PART 8: Cost Analysis

### Electricity Cost

```
Power consumption:
- Mini PC baseline: 30-50W
- With LLM idle: +5-10W
- With LLM active: +20-40W

Average: 40W extra (24/7)

Monthly calculation:
40W Ã— 24h Ã— 30 days = 28.8 kWh

Cost (Argentina ~$0.10/kWh): ~$3/month
Cost (USA ~$0.15/kWh): ~$4/month
```

**Compare to cloud:**
- ChatGPT Plus: $20/month
- Claude Pro: $20/month
- Local LLM: $3/month âœ…

**Savings: $200/year!**

---

### Storage Requirements

```
Models stored in: /opt/docker/configs/ollama

Typical usage:
- 1 model (Llama 3.1 8B): ~5GB
- 2 models (8B + 13B): ~12GB
- 3 models (variety): ~20GB

Documents/embeddings: <1GB

Total: ~10-20GB (you have 913GB!)
```

---

## PART 9: Comparison to Claude/ChatGPT

### What Your Local LLM CAN Do:

```
âœ… Answer questions about YOUR homelab
âœ… Remember ALL your conversations (unlimited context)
âœ… Work offline (no internet needed)
âœ… Generate code/scripts
âœ… Explain concepts
âœ… Troubleshoot issues
âœ… 100% private (data never leaves your network)
âœ… FREE (after setup)
âœ… No rate limits
âœ… Customize to your needs
```

### What It CAN'T Do (vs Claude/ChatGPT):

```
âŒ Not as smart (Llama 8B < GPT-4/Claude)
âŒ Slower responses (local CPU vs huge GPU clusters)
âŒ Can't access real-time web (unless you enable search)
âŒ Smaller knowledge cutoff
âŒ Less refined/polished responses
âŒ Can't generate images (DALL-E, etc.)
```

### Best Practice: Use Both!

```
Local LLM for:
- Homelab questions
- Quick commands/scripts
- Private data
- Learning/experimentation
- When offline

Claude/ChatGPT for:
- Complex reasoning
- Latest information
- Better writing quality
- Image generation
- When you need "the best"
```

---

## PART 10: Next Steps & Ideas

### Idea 1: Voice Assistant

```
Add Whisper (speech-to-text):
- Talk to your homelab!
- "Hey assistant, restart Jellyfin"
- "What's my disk usage?"

Possible with:
- Whisper.cpp in Docker
- Integrate with Open WebUI
```

---

### Idea 2: Slack/Telegram Bot

```
Make your AI available via chat apps:

Telegram:
You: @homelabbot what's my Jellyfin URL?
Bot: http://media.matiasmassetti.com

Slack:
You: /homelab check services
Bot: All services healthy! âœ…
```

---

### Idea 3: Auto-Documentation

```
Train AI to:
- Read your Docker logs
- Summarize changes
- Update documentation automatically
- Alert you to issues
```

---

### Idea 4: Multiple Personalities

```
Create different AI assistants:

1. "DevOps Expert" - for troubleshooting
2. "Code Tutor" - for learning
3. "Media Librarian" - for Jellyfin questions
4. "Network Admin" - for network issues

Each with specialized knowledge!
```

---

## Quick Reference

### Essential Commands

```bash
# Start/Stop AI
docker compose up -d ollama open-webui
docker compose stop ollama open-webui

# Download model
docker exec ollama ollama pull llama3.1:8b

# List models
docker exec ollama ollama list

# Remove model
docker exec ollama ollama rm model-name

# View logs
docker compose logs -f open-webui

# Backup data
tar -czf ~/ai-backup.tar.gz /opt/docker/configs/open-webui

# Check GPU usage
docker exec ollama nvidia-smi  # If you had NVIDIA GPU
```

---

### Access URLs

```
Local:
http://192.168.1.239:3000

With Cloudflare:
https://ai.matiasmassetti.com

API:
http://192.168.1.239:11434
```

---

## Conclusion

**You can absolutely run a personal LLM for FREE!**

**What you get:**
- ðŸ¤– AI assistant that knows YOUR homelab
- ðŸ’° $0 setup cost (use existing hardware)
- ðŸ”’ 100% private
- ðŸ“š Unlimited context (never forgets)
- âš¡ Fast responses (local)
- ðŸŒ Access from anywhere (Cloudflare)

**Perfect for:**
- Homelab troubleshooting
- Learning Linux/Docker
- Quick reference
- Command generation
- Configuration help
- Documentation search

**Next:** Set it up and start uploading your homelab docs!

**Your mini PC is PERFECT for this!**