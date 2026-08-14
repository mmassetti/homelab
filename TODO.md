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
- [ ] **58 movies in nested/multi-file folders** — reconstructed and fully triaged 2026-08-14
      (wasn't saved anywhere before). Broke into 7 groups:
      - ✅ **26 safe, done** — correctly identified, just had an extra folder level or shared a
        folder with something else harmless. 22 newly linked into Radarr (`monitored:true`,
        `hasFile:true` confirmed), 2 (`La libertad`, `Prisoners of the Land`) were already
        linked from the same day's earlier batch, 1 (`Curse of the Black Pearl`) was already
        correctly in Radarr from before, and 1 (`The Man from Earth`) turned out to have **no
        audio track at all** (confirmed independently via Jellyfin's own stream probe) — added
        to Radarr but left `monitored:false` since relinking won't fix a broken file; needs a
        fresh download to actually get audio.
      - ✅ **Fixed 2026-08-14: "Happy Together" / "Happiness" cross-tagging bug.** Jellyfin's
        `Happiness (1997)/...` file was wrongly tagged tmdb:18329 (actually *Happy Together*'s
        id), which Radarr had inherited from the 2026-08-12 backfill. Retagged the Jellyfin
        item to *Happiness*'s real id (tmdb:10683, cross-checked against the IMDb id already on
        file), deleted the wrong Radarr entry (`deleteFiles:false`, file confirmed untouched),
        and added fresh correct entries for both *Happiness* and the real *Happy Together*
        (which had been sitting correctly tagged in Jellyfin all along but never linked). Both
        `monitored:true`/`hasFile:true`, zero duplicate tmdbIds in Radarr. See decision log.
      - ✅ **Fixed 2026-08-14: 3 misplaced-file bugs.** `mv`'d each to its own top-level folder
        on the NAS — *A Cure For Wellness (2016)* out of "25th Hour (2002)"'s folder (25th Hour
        itself was never actually in the library — that folder now only holds a stray leftover
        `.parts` file, left alone); *Jeff, Who Lives at Home (2011)* out of "Klute (1971)"'s
        folder; *Pirates of the Caribbean: Dead Man's Chest (2006)* out of "Curse of the Black
        Pearl (2003)"'s folder. Re-scanned in Jellyfin (kept the same correct TMDB ids) and
        linked all 3 into Radarr, `monitored:true`/`hasFile:true`. See decision log.
      - ✅ **Fixed 2026-08-14: 4 wrong-TMDB-tag cases.** *Los Muertos (2004)*'s actual main film
        file was mistagged as "Cómo se hizo 'Los muertos'" (a making-of) — retagged to the real
        film (tmdb:36241) and linked into Radarr for the first time
        (`monitored:true`/`hasFile:true`). The other 3 (`dead set 2`, `dead set 3`, *La
        Libertad*'s deleted scene) aren't real standalone films, so instead of hunting for a
        "correct" id, cleared their wrong TMDB tags entirely to match how `dead set 1`/`4`/`5`
        already look — no Radarr entry for these three. See decision log.
      - **1 ambiguous** — a Kurosawa documentary about "High and Low" sitting inside the
        "Tengoku to jigoku" (High and Low) folder; might be legitimate bonus content, might be
        misfiled. Worth a quick look, not urgent.
      - **La Flor (2018) cluster, 8 files** — Mariano Llinás's ~14h film, released/ripped in
        parts (`1.1`, `1.2`, `2.1`...`3.3`). Jellyfin's scraper matched each fragment
        individually to a wildly unrelated title (an Atlético Madrid documentary, anime films,
        "The House of Hate" (1918) four times, etc). Real TMDB id is **423778**. Clean fix is
        probably Jellyfin's "Merge Versions" feature so the 8 files show as one item with 8
        selectable versions, rather than 8 fake standalone movies.
      - **6 harmless duplicate copies** of already-correctly-tagged movies, no action needed
        unless disk space matters: *El gran dictador* (2 audio tracks, already resolved — only
        the Spanish-audio copy is in Radarr), *Seven Samurai* (2 quality rips, one now in
        Radarr), *Trenque Lauquen* (2 parts sharing one tmdb id — Radarr can't track both under
        the same id, so at most one part can ever get a Radarr entry).
      - **10 already resolved** in the 2026-08-13 TMDB-id session (the `cast1.part1`/`dead set
        1,4,5`/interview/making-of/restoration items already flagged as "not real movies").
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
