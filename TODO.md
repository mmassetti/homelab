# Server TODO

General punch list for the homelab. Not a decision record (see `decisions/log.md` for those) —
just things that need doing. Check items off / remove them as they're resolved, add new ones
as they come up.

## Open

- [ ] **Cloudflare API token DNS scope** — gets "Authentication error" reading DNS records for
      the zone despite having Zone:DNS:Edit; blocked exposing Jellystat publicly. Not urgent
      (Jellystat is Tailscale/LAN-only for now).
- [ ] **89 movies still with no TMDB id in Jellyfin** (was 105/120 — 31 identified, applied to
      Jellyfin, and linked into Radarr 2026-08-13: 25 high-confidence auto-matches + 6 found
      via manual title cleanup, all `monitored:true`/`hasFile:true`, Bazarr will pick up
      subtitles on its next Radarr sync). Matching report: `tmdb_match_results.json` was only
      in the session scratchpad, not saved to the repo — if it's gone, regenerate by re-running
      the same Jellyfin-RemoteSearch-based matching approach (see decision log 2026-08-13 entry
      for the method). Three sub-groups still open, Matias plans to do these by hand later:
      - **13 medium-confidence** (title matches, year is off by more than 1 — usually shooting
        vs. release year, but check before applying): 3030 (2001) → *El 30-30* tmdb:807680;
        Diarios patagónicos 1 (1973) → tmdb:399671; El ausente (1987) → *El diente ausente*
        tmdb:1737730; El profes1on4l (2019) → *The Professional* tmdb:653348; Esteros (2012) →
        tmdb:418718; Héroe corriente (2017) → tmdb:684021; Kill Bill - The Whole Bloody Affair
        (2004) → tmdb:414419; La nueva cigarra (1975) → tmdb:773918; Last And First Men (2017)
        → tmdb:566038; Lectura según Justino (2019) → tmdb:662609; Los decentes (2019) →
        *Nosotros, los decentes* tmdb:322440; Negro Buenos Aires (2009) → *Black Buenos Aires*
        tmdb:109817; **Workshop (1971) → tmdb:650842 — flagged high-risk, generic title + ~50
        year gap, likely the wrong film, double-check carefully before applying.**
      - **9 weak candidates** (no confident algorithmic match, need a manual themoviedb.org
        search): Al centro de la tierra (2018), Anida y el circo flotante (2016), Antes del
        estreno (2010), Cuando dejes de quererme (2019), El hombre del futuro (2020), La mala
        verdad (2010), La playa del amor (1979), La vida por Perón (2004), Los pibes (2019).
      - **11 aren't real standalone movies** — they're extras/episodes sitting inside a
        correctly-identified movie's folder, misindexed by Jellyfin as separate films. Fix is
        a Jellyfin reorg (rename the extra's subfolder to `extras/` so it's associated as
        bonus content), not a TMDB match: `cast1.part1`/`cast2.part1` (2-disc rip halves,
        inside *Castaway on the Moon (2009)*'s own folder), `Interview with Lisandro Alonso`
        (inside *La Libertad (2001)*), `Alternative opening scene` + `Interview with Lisandro
        Alonso on Los Muertos` (inside *Los Muertos (2004)*), `Presentación de Martin
        Scorsese` + `Restauración de Prisioneros de la tierra` (inside *Prisioneros de la
        tierra (1939)*), `Los guantes mágicos (Making of) (2003)` (loose, own folder). Separately,
        `dead set 1`/`4`/`5` are episodes of the 2008 British TV miniseries *Dead Set* filed
        under the movie library — needs a bigger call (delete, move to a TV library, or
        ignore), not just a folder rename.
      - **56 with no match found at all** — mostly very obscure Argentine shorts/documentaries;
        several may genuinely not be catalogued on TMDB, in which case they can't ever get a
        Radarr/Bazarr entry. Full list in the artifact report from 2026-08-13 (not saved to
        the repo — ask to regenerate if the link's gone stale).
- [ ] **58 movies in nested/multi-file folders** — mostly legitimate extras or multi-part rips,
      but at least one real folder-mismatch bug found ("A Cure For Wellness" living inside
      "25th Hour"'s folder) — worth eyeballing the rest for similar issues.
- [ ] **9 movies Radarr couldn't find after the 2026-08-12 backfill** (likely folder name
      casing) + **2 loose files directly in `Peliculas/` root** ("El Partido", "La cara
      oculta") with no enclosing folder — see decision log for the full list.
- [ ] **NAS backup strategy incomplete** — SHR redundancy (2nd drive) is done, but Btrfs
      snapshots and an actual off-pool backup (Hyper Backup to USB, offsite B2/Wasabi) were
      never confirmed as set up. Redundancy alone doesn't cover accidental deletion or pool
      corruption. See `hardware/nas.md` § Backup Strategy.
- [ ] **NAS at 97% full (419GB free)** — 3rd drive not landing until Feb 2027 (US trip). Worth
      keeping an eye on growth rate between now and then; may need to free up space earlier
      (e.g. more aggressive quality profile downgrades, pruning the 99%-full legacy Seagate
      instead of NAS where possible).

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
