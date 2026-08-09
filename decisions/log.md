# Architecture Decision Records

## 2026-08 — Bazarr: ignore embedded PGS subtitles when checking for missing subs

**Context**: Downloaded "The Hunger Games: The Ballad of Songbirds & Snakes" (BluRay REMUX). Jellyfin's subtitle picker showed several identically-labeled "Spanish" tracks; picking some of them showed no subtitles at all when playing from the Mac. Manually downloading an external `.srt` worked immediately. Investigation via `ffprobe` on the mkv showed the release embeds **both** `hdmv_pgs_subtitle` (image-based) and `subrip` (text) tracks for the same language, indistinguishable in the Jellyfin UI. Bazarr's `missing_subtitles` was already empty for this movie because `use_embedded_subs: true` let the embedded PGS tracks count as satisfying the language profile — even though PGS requires server-side burn-in transcode to render and doesn't display on direct play.
**Decision**: Set `general.ignore_pgs_subs: true` in Bazarr (`/opt/docker/configs/bazarr/config/config.yaml`), restarted the container.
**Alternatives considered**: Manually downloading external subs per-release (what fixed this one instance, not scalable), disabling `use_embedded_subs` entirely (too broad — plenty of releases have good embedded SubRip tracks that are fine to keep using).
**Rationale**: Only PGS tracks are the problem (bitmap, no direct-play rendering); text-based embedded SubRip tracks remain valid and are still respected. Now Bazarr treats PGS-only releases as "missing subtitles" and fetches a proper external `.srt` automatically via OpenSubtitles/SubDL/etc., instead of assuming an unusable PGS track already satisfies the profile.

## 2026-02 — Add Google Calendar to Morning Brief via OAuth2

**Context**: Wanted to include today's calendar events in the morning brief. Matias's work calendar is on Google Workspace (`matias@honeydewcare.com`), which doesn't expose a secret iCal URL (admin-restricted).
**Decision**: Used Google Calendar API with OAuth2 (Desktop app flow). One-time browser auth to get a refresh token, stored in `~/.config/secrets/gcal_oauth.json` (perms 600). Helper script `gcal-today.py` uses only Python stdlib (no external deps). Scope: `calendar.events.readonly`. Calendar section only appears when there are events.
**Alternatives considered**: (1) Secret iCal URL — not available on Workspace accounts with restricted sharing. (2) Service account — requires sharing calendar with service account email, more complex setup.
**Rationale**: OAuth2 with refresh token is the only option for Workspace accounts without admin cooperation. Minimal scope (`events.readonly`), credentials stored securely, no external Python dependencies.

## 2026-02 — Morning Brief daily Telegram summary

**Context**: Matias wanted a daily morning brief at 8:00 AM via Telegram with weather, local/national/tech news, and infra status.
**Decision**: Implemented as a host crontab bash script (`~/homelab/scripts/morning-brief.sh`) that gathers data from APIs/RSS feeds and sends the compiled message via OpenClaw gateway's `message send` CLI. Added `/usr/bin/docker:ro` bind mount to the gateway container for sandbox Docker access.
**Alternatives considered**: (1) OpenClaw cron with isolated agent session — failed because the sandbox container has `network: none`, no `node`/`curl` binaries, and `web_search` tool is not available in sandbox context. (2) Disabling sandbox for cron sessions — rejected for security reasons.
**Rationale**: A bash script is more reliable and deterministic than an AI agent for this task. RSS feeds provide structured headlines without needing AI summarization. The script runs on the host (has network, docker access) and sends via the gateway's Telegram integration. Sources: wttr.in (weather), La Brújula 24 RSS (local), La Nación RSS (national), TechCrunch RSS (tech), docker-quick.js (infra).

## 2026-02 — Install ClaWHub skills and Mission Control dashboard for OpenClaw

**Context**: OpenClaw had only 3 built-in skills (healthcheck, skill-creator, weather). Wanted to enhance the agent with token optimization (QMD), security (Prompt Guard), and a management dashboard (Mission Control).
**Decision**: Override the "never install ClaWHub skills" rule after careful audit of each skill. Installed 3 ClaWHub skills (qmd, prompt-injection-guard, openclaw-mission-control). Deployed Mission Control as a separate Docker service sharing the gateway's network namespace (`network_mode: service:openclaw-gateway`). Added ClaWHub CLI and QMD binary to a writable workspace volume (`workspace/.npm-global/bin/`), extended container PATH via docker-compose environment.
**Skipped**: SuperMemory (requires paid plan + sends data to external cloud), Don't Hack Me (doesn't exist), Find Skills (flagged by VirusTotal + uses different package manager).
**Alternatives considered**: Keeping strict "no ClaWHub skills" policy (too restrictive for practical use), installing skills on host (breaks container isolation)
**Rationale**: VAN-210 risk is partially mitigated by VirusTotal scanning (now integrated in ClaWHub CLI) and `--ignore-scripts` for npm installs. Each skill was inspected before installation. Skills are just SKILL.md markdown files — no executable code. QMD binary compiled inside container with better-sqlite3. Mission Control uses `network_mode: service` to share localhost with gateway, avoiding hardcoded URL modifications.

## 2026-02 — Personalize OpenClaw bot ("Claudito") and grant Docker socket access

**Context**: OpenClaw was deployed with default template workspace files. Bot had no personality, didn't know the homelab, and couldn't monitor containers (Docker socket mounted but `node` user lacked group permissions).
**Decision**: (1) Rewrote all workspace files (IDENTITY, SOUL, USER, TOOLS, AGENTS, MEMORY, HEARTBEAT) with homelab-specific context, Spanish-first personality, and strict conciseness rules. (2) Added `group_add: "987"` (docker GID) to compose so gateway process can query Docker socket API. (3) Created `workspace/scripts/docker-{status,quick}.js` for container monitoring via socket API (no docker CLI in container). (4) Deleted BOOTSTRAP.md (bootstrap complete).
**Alternatives considered**: Installing docker CLI in container (bloat, security surface), using curl+jq for socket queries (jq not available, curl commands prone to shell escaping issues)
**Rationale**: Node.js scripts are native to the container runtime, avoid shell escaping issues, and are idempotent. `group_add` is the minimal permission change needed — no capability escalation, no filesystem changes. Bot can now self-monitor all 25+ containers.

## 2026-02 — Deploy OpenClaw AI agent in Docker with sandbox hardening

**Context**: Wanted to self-host OpenClaw (AI agent with shell/filesystem access, Telegram integration). No Proxmox/VM isolation available — Docker is our only isolation layer. Mini PC runs 24+ containers with NAS mounts and personal data.
**Decision**: Deploy in a separate Docker Compose file (`/opt/docker/configs/openclaw/docker-compose.yml`) with maximum container hardening: read-only filesystem, all capabilities dropped, no-new-privileges, localhost-only port binding, dedicated isolated network (172.31.0.0/24). Agent commands sandboxed in throwaway containers with `network: none`. Telegram as primary interface with user ID allowlisting. OpenRouter free tier as model provider.
**Alternatives considered**: Proxmox VM (not available on this hardware), main compose file (too risky to couple with other services), Docker socket proxy (deferred — direct mount with hardening sufficient for now)
**Rationale**: Defense in depth: container isolation + read-only fs + capability dropping + network isolation + sandbox containers + Telegram allowlisting. Gateway never exposed to internet (no Cloudflare Tunnel). Separate compose file for independent lifecycle management and risk isolation.

## 2026-02 — Move OpenCloud data from local disk to NAS (ext4 loop mount over NFS)

**Context**: OpenCloud data was stored at `/opt/docker/data/opencloud` on the mini PC's local NVMe. Wanted to move it to the NAS for centralized storage and more space.
**Decision**: Mount the NAS via NFS at `/mnt/nas-nfs`, store an ext4 image file at `/mnt/nas-nfs/opencloud-data/opencloud.img`, and loop-mount it at `/mnt/opencloud`. Docker volume changed to `/mnt/opencloud:/var/lib/opencloud`.
**Alternatives considered**: Direct NFS mount (filesystem compatibility issues with Docker), SMB mount (already in use for media, not ideal for application data)
**Rationale**: ext4 image file over NFS avoids permission/lock issues that Docker apps have with network filesystems directly. NFS chosen over SMB for the backing mount due to better Linux-native performance for this use case. Existing SMB mount at `/mnt/nas` remains for media.

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
