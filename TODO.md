# Server TODO

General punch list for the homelab. Not a decision record (see `decisions/log.md` for those) —
just things that need doing. Check items off / remove them as they're resolved, add new ones
as they come up.

## Open

- [ ] **Verify The Handmaiden (2016) Radarr re-grab loop stayed stopped** — RSS Sync kept
      re-grabbing the same REPACK release every 30 min, deleting the good file each time on
      import failure, and re-triggering the "Manual Interaction" Telegram alert. Blocklisted the
      release (`POST /api/v3/history/failed/{id}`) 2026-08-14 ~12:27 to stop it; needs a check
      after a couple more RSS Sync cycles to confirm it didn't just find a *different* release
      of the same movie to loop on. See decision log for the full diagnosis.
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
- [x] **58 movies in nested/multi-file folders** — reconstructed, fully triaged, and fully
      resolved 2026-08-14
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
      - ✅ **Resolved 2026-08-14: the "Kurosawa documentary" wasn't one.** Turned out to be a
        byte-for-byte duplicate rip of the main *High and Low (1963)* film, mistagged with an
        unrelated real documentary's TMDB id. Retagged to the correct id and merged with the
        main file via `MergeVersions`, same treatment as La Flor. The redundant 2.1GB duplicate
        was deleted the same day (verified against Radarr's tracked file path first) to help
        with the NAS space situation.
      - ✅ **Fixed 2026-08-14: La Flor (2018) 8-file cluster.** Retagged all 8 fragments to the
        real film (tmdb:423778) then merged them via Jellyfin's `MergeVersions` API into one
        item with 8 selectable versions instead of 8 fake standalone movies. Deliberately *not*
        linked to Radarr — its one-file-per-movie model doesn't fit 8 different segments of one
        long film, and subtitle need is low anyway (Argentine film, already in Spanish). See
        decision log.
      - ✅ **Reviewed 2026-08-14: the 6 "duplicates".** Only 1 of 3 pairs was actually redundant.
        *El gran dictador* (dubbed vs. subtitled — different versions, kept both) and *Trenque
        Lauquen* (Part 1 + Part 2 — not duplicates, kept both) needed no action. *Seven Samurai*
        was a real duplicate — deleted the unused 3.3GB top-level rip, kept the Radarr/Bazarr-
        tracked nested copy. This was the last open item from the entire 2026-08-12 backfill
        follow-up. See decision log.
      - **10 already resolved** in the 2026-08-13 TMDB-id session (the `cast1.part1`/`dead set
        1,4,5`/interview/making-of/restoration items already flagged as "not real movies").
- [ ] **9 movies Radarr couldn't find, diagnosed 2026-08-14** — turned out not to be a casing
      issue at all (every path already matches Jellyfin exactly). Real causes, confirmed via
      Radarr's manual-import rejections + an independent Jellyfin stream-probe cross-check:
      - **8 have no audio track at all** (broken files, need a fresh download — not fixable via
        metadata/relinking): *The Boat That Rocked*, *Fresno*, *Hotel Monterey*, *La chambre*,
        *Nightwatching*, *Popstar: Never Stop Never Stopping*, *Snowtown*, *Stranger Than
        Fiction*. Plus *The Man from Earth (2007)*, found silent in an earlier session the same
        day — 9 silent files total, ~12GB combined. Redownload wishlist (title — year — size —
        folder, all in `Peliculas/`, all with a correct TMDB id already in Jellyfin so a fresh
        file just needs to land in the same folder):
        - The Boat That Rocked — 2009 — 1.1G — `The boat that rocked (2009)/`
        - Fresno — 2014 — 70M — `Fresno (2014)/`
        - Hotel Monterey — 1972 — 3.6G — `Hotel Monterey (1972)/`
        - La chambre — 1972 — 329M — `La chambre (1972)/`
        - Nightwatching — 2007 — 2.2G — `Nightwatching (2007)/`
        - Popstar: Never Stop Never Stopping — 2016 — 1.3G — `Popstar Never Stop Never Stopping (2016)/`
        - Snowtown — 2011 — 752M — `Snowtown (2011)/`
        - Stranger Than Fiction — 2006 — 1.6G — `Stranger Than Fiction (2006)/`
        - The Man from Earth — 2007 — 601M — `The Man from Earth (2007)/The Man From the Earth (2007)/`
        - ✅ **All 9 deleted 2026-08-14** to reclaim the ~12GB — only the video/subtitle files,
          the empty correctly-named folders above and their Radarr entries (still
          `monitored:false`, correct tmdbId/path) were kept on purpose: drop a real file into
          the same folder later, `RescanMovie`, flip `monitored:true` — no need to redo any
          identification work.
      - **1 is fine but Radarr can't represent it**: *The Mother and the Whore (1973)* is a
        VHS-era CD1/CD2 split of one film — has real audio, plays correctly in Jellyfin as one
        continuous item, but Radarr explicitly rejects multi-part files. Same situation as
        *La Flor* — left deliberately unlinked rather than force-importing just half of it.
      - Left all 9 `monitored:false` as-is, matching their real state. No fix applied, this was
        diagnosis only. See decision log.
      - ✅ **Fixed 2026-08-14: the 2 loose files.** *El Partido (2026)* was a genuine loose file
        — given its own folder and linked to Radarr (Jellyfin had re-identified it under its
        English title "The Match"; renamed back to "El Partido" for consistency with the rest
        of the library). *La cara oculta (2011)* wasn't actually loose — it had a proper mp4
        all along, but a leftover raw DVD-structure folder (`VIDEO_TS`/`AUDIO_TS`, 4.4GB) was
        confusing Jellyfin into indexing that instead (nonsense ~27h runtime). Deleted the
        redundant DVD folder, reclaiming 4.4GB, and linked the now-correctly-indexed mp4 to
        Radarr. Both `monitored:true`/`hasFile:true`. This closes every item from the
        2026-08-12 backfill's original error list. See decision log.
- [x] **Postgres DBs backed up to the NAS** (2026-08-15) — `scripts/backup-postgres.sh`,
      daily via host crontab (`0 8 * * *` UTC = 5:00 AM ART), `pg_dumpall` (all DBs + roles,
      not just the default one — `media_tracker_db` actually holds two: `cinemateca` and
      `media_tracker`) for `ricota-db-db-1`, `media_tracker_db`, `jellystat-db` → gzip →
      `/mnt/nas/Backups/postgres/`, 14-day retention pruned each run. This was the one
      genuinely irreplaceable, single-point-of-failure data (only ever existed in Docker
      volumes on the mini PC's one SSD); everything else under consideration (Drive-synced
      docs, photos) already has an origin copy elsewhere. Confirmed `SnapshotReplication` is
      installed on DSM but the NAS's own Btrfs snapshots were never configured on any share
      (0 snapshots on `Media` as of 2026-08-15) — separate from this, still open below.
- [ ] **NAS backup strategy still missing two layers** — (1) Btrfs snapshots on `Media` (and
      other shares) — protects against accidental deletion/corruption, decoupled from the SHR
      mirror which replicates both good and bad writes instantly. `SnapshotReplication` package
      is already installed, just needs a schedule configured. (2) True offsite copy — Hyper
      Backup isn't installed at all (confirmed via DSM package list 2026-08-15); would ship
      `/mnt/nas/Backups/postgres/` (currently ~2MB) to B2/Wasabi. Both are optional/"do it
      properly eventually" rather than urgent — the one thing that was a real single point of
      failure (the Postgres DBs) is already handled by the item above. See `hardware/nas.md`
      § Backup Strategy and § DSM API Access.
- [x] **NAS was actually 99% full (225GB free), not 419GB** — root cause found and fixed
      2026-08-15: the SMB share's Synology recycle bin (`/mnt/nas/#recycle`) had silently
      accumulated **420GB** from this week's Radarr cleanup work (duplicates, silent/broken
      files, DVD-structure folders, etc. — see the 2026-08-14 entries above), since DSM's
      recycle bin has no default size cap or auto-expiry. Emptied it (`find ... -delete`,
      then a follow-up pass for orphaned empty dirs left by a CIFS rmdir race) — freed space
      climbed 225GB → 425GB as Btrfs finished reclaiming blocks async.
      **Correction (same day, via DSM API)**: there already is a scheduled "Empty Bin" task
      (`SYNO.Core.TaskScheduler` id 4) — runs daily at 00:00, applies to all shares
      (`clean_all: true`), purges anything older than 7 days (`policy: "time", time: 7`), no
      exceptions. It hadn't misfired; the 420GB was just this week's Radarr cleanup (2026-08-11
      to 08-14), still under 7 days old when we found it — DSM would've purged it itself between
      08-18 and 08-21. Nothing to configure here; the policy is already sane. (The earlier note
      that no such task existed was only true from the mini PC's vantage point — no DSM access
      at the time.)
- [ ] **3rd NAS drive lands ~Feb 2027 (US trip)** — until then, keep an eye on growth rate
      given the tight margin above. See [[nas_storage_status]] memory.
- [ ] **Complete the `Google Drive Sync/` rclone mirror once the 3rd drive lands (Feb 2027)** —
      full investigation 2026-08-15, see decision log for the whole story. Short version: an
      idle `rclone.service` (running since 2026-02-26, never documented) had done one manual
      snapshot back in Feb 2026 and never synced again; live Drive usage is 666.76GB vs the
      242GB mirror. Ran a selective sync today for the real document folders (~5GB, safe) but
      deliberately excluded the three folders that account for 662GB of the 666GB total — they
      turned out to be media stashes, not documents:
      - `CaliforniaSecreta/` (406GB total, 144GB already on the NAS) — missing 213/408 files:
        **all of Temporada 2 (2025)** (81 files, the biggest single gap) plus most of Capítulos
        5-9 of Temporada 1. Capítulos 1/2/4/10/11/12 are already ~complete (1-3 stray files
        each); Capítulo 3 is fully present.
      - `ReporteMinoritario/` (145GB total, 54GB already on the NAS) — despite the name
        matching the `~/Code/reporteminoritario-transcript-fetcher` project, this Drive folder
        is actually a `Libros/`/`Peliculas/`/`Series/` media stash, unrelated to the code repo.
        Missing 520/750 files, mostly `Libros/` (432 missing — most of the book collection).
        `ProyectoPorrini/` is essentially complete (1 file missing).
      - `Otros/` (111GB) — also media/junk (a full TV show, ROMs, phone video clips, and at
        least one leftover incomplete-torrent `.dat` file) — not planned for backup at all,
        candidate for just deleting the junk directly from Drive rather than mirroring it.
      Completing `CaliforniaSecreta` + `ReporteMinoritario` needs ~353GB (262GB + 91GB), which
      doesn't fit in current free space alongside normal media library growth — do it after the
      3rd drive lands.

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
