# Server TODO

General punch list for the homelab. Not a decision record (see `decisions/log.md` for those) —
just things that need doing. Check items off / remove them as they're resolved, add new ones
as they come up.

## Open

- [ ] **Cloudflare API token DNS scope** — gets "Authentication error" reading DNS records for
      the zone despite having Zone:DNS:Edit; blocked exposing Jellystat publicly. Not urgent
      (Jellystat is Tailscale/LAN-only for now).
- [ ] **105 movies with no TMDB id in Jellyfin** — need manual identification before they can
      be linked to Radarr for subtitle management. See decision log 2026-08-12 backfill entry.
- [ ] **58 movies in nested/multi-file folders** — mostly legitimate extras or multi-part rips,
      but at least one real folder-mismatch bug found ("A Cure For Wellness" living inside
      "25th Hour"'s folder) — worth eyeballing the rest for similar issues.
- [ ] **9 movies Radarr couldn't find after the 2026-08-12 backfill** (likely folder name
      casing) + **2 loose files directly in `Peliculas/` root** ("El Partido", "La cara
      oculta") with no enclosing folder — see decision log for the full list.

## Done (kept for context, remove once stale)

- [x] Radarr/Sonarr Telegram notifications (2026-08-11)
- [x] Jellyfin "now playing" Telegram notification via Webhook plugin (2026-08-11)
- [x] Jellyseerr admin + per-user Telegram notifications (2026-08-11)
- [x] `home.matiasmassetti.com` tunnel target fixed, Homarr → homepage (2026-08-11)
- [x] `nas.matiasmassetti.com` — removed public DSM exposure, ingress rule + DNS record both deleted (2026-08-11)
- [x] `CLAUDE.md` / `services/services.md` / `network/network.md` synced with real running stack (2026-08-11)
- [x] Sonarr auth hardened (`disabledForLocalAddresses` → `enabled`, matches Radarr/Prowlarr/Lidarr) (2026-08-12)
- [x] Cloudflare Access added on 15 admin-only hostnames, email-OTP to matiasmassetti@gmail.com, 168h sessions; `media`/`pedidos` (Jellyfin/Jellyseerr) deliberately left open for family/friends (2026-08-12)
- [x] `ricota-db/` committed to git with real secrets excluded — found and fixed a hardcoded DB password in `init/01-roles.sql` before it ever reached GitHub (2026-08-12)
- [x] OpenClaw formally retired in docs; Morning Brief rebuilt standalone (direct Telegram Bot API, no agent dependency), content revamped (Spanish tech news, Twitter/X trends, TV football matches, Jellyseerr pending, last-24h downloads), cron re-enabled (2026-08-12)
- [x] Fixed Jellyfin VAAPI hardware transcoding passthrough (device was never mounted into the container) (2026-08-12)
- [x] Switched Jellyseerr's default Radarr/Sonarr quality profile from 2160p Remux to 2160p Efficient (NAS was nearly full, 88% of tracked movies were remux) (2026-08-12)
- [x] Added Whisper AI subtitle provider (subgen) to Bazarr for titles with no official subtitle anywhere (2026-08-12)
- [x] Backfilled 2210 legacy movies into Radarr so Bazarr can manage their subtitles (2026-08-12)
- [x] Stats plugin decided — installed Jellystat (container + dedicated Postgres) rather than relying on raw Playback Reporting queries (2026-08-12)
