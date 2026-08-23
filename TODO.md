# Server TODO

General punch list for the homelab. Not a decision record (see `decisions/log.md` for those) —
just things that need doing. Check items off / remove them as they're resolved, add new ones
as they come up.

## Open

- [x] **Stop Making Sense (1984) — upgraded to 2160p** (2026-08-20). Library already had a
      throwaway 1.33GB HDTV-1080p x264/AAC rip (tmdbId 24128, movieId 2090) — bumped its
      quality profile to "2160p Quality" (id 12, allows Bluray-2160p) and manually grabbed the
      specific release Matias wanted: `Stop.Making.Sense.1984.DV.HDR.2160p.UHD.BluRay.x265.
      HEVC.TrueHD.ATMOS-SARTRE` (24GB, 1337x) rather than trusting Radarr's own pick — old file
      auto-deleted on grab. Part of a broader "reference-quality concert films" research pass
      (any artist, not just current library ones) — see the rest below.
- [ ] **Reference-quality concert films wishlist** (researched 2026-08-20, not current-library
      artists — general "demo disc" quality concerts). Sizes are largest-clean-result found via
      Prowlarr that day; re-check before grabbing, availability shifts. NAS had ~195GB free
      after this session's other grabs — nowhere near enough for all of these at once, pick
      selectively:
      - [ ] **Pink Floyd — At Pompeii MCMLXXII (1972/2025 restoration)** — 95.8GB full Blu-ray
        (RuTracker) down to 18-27GB for UHD remux/1080p BDRip TrueHD Atmos 7.1 options.
      - [ ] **Pink Floyd — Delicate Sound of Thunder (1988/2020 restoration)** — 37GB remux,
        23GB 1080p BDRip DTS-HD MA 5.1, or a 2160p UHDTV HDR option at 17GB.
      - [ ] **Queen — Rock Montreal & Live Aid** — 192.8GB full 2-disc (2160p+1080p) set down
        to 40-58GB for UHD Remux alone (TrueHD Atmos 7.1) — the biggest title on this list.
      - [ ] **Rolling Stones — Havana Moon (2016)** — 39.6GB BluRay 1080i down to ~10-13GB for
        1080p BDRip/BluRay options.
      - [ ] **Rolling Stones — Some Girls: Live in Texas '78 (2011)** — 25.8GB BluRay 1080i
        down to 5.8GB (1080p, DTS-HD MA).
      - [ ] **Metallica — Through the Never (2013)** — 47.7GB Blu-ray (includes 3D cut); 2D-only
        version likely smaller if findable separately.
      - [ ] **Peter Gabriel — New Blood: Live in London (2011)** — 47GB BD3D 1080p down to
        8.3GB for the DVD9 (non-3D).
      - [ ] **David Gilmour — Remember That Night (2007)** — two discs, ~46GB each (~92.5GB for
        both) down to 14GB for a 1080p MBluRay x264 single-file option.
      - [ ] **INXS — Live at Wembley Stadium '91** — no video release found on any indexer as
        of 2026-08-20, only an audio FLAC rip (0.7GB). Re-check later, don't expect it soon.
- [ ] **Rolling Stones — Let's Spend the Night Together (1981), 4K UHD Remux** — deliberately
      deferred until the 3rd NAS drive lands (~Feb 2027, see the item below). The Kino Lorber
      2026 restoration remux runs 71-84GB (`2160p.UHD.BluRay.REMUX.DTS`, confirmed available
      on NZBgeek via Prowlarr 2026-08-20) — real lossless DTS-HD MA 5.1/2.0 audio, not just a
      resolution bump. A 1080p BluRay release also exists (~6GB) but is very likely just the
      lossy DTS core, possibly from an older (pre-restoration) transfer — not worth grabbing
      as a stopgap. Search again once free space allows; `Rock and Roll Circus` (1080p,
      grabbed 2026-08-20) and `Cerati — Fuerza Natural Tour` don't have this constraint, much
      smaller.
- [ ] **11 movies added to Radarr 2026-08-16, check search results** — Wrong Man (1956), Ghost
      World (2001), Drunken Angel (1948), Boss of It All (2006), Fifth Estate (2013),
      Counterfeiters (2007), Mifune (1999), Wind Rises (2013), All About My Mother (1999),
      Eternity and a Day (1998), Idiots and Angels (2011) — these were empty NAS folders
      (only a leftover subtitle/nfo) that Jellyfin had never scanned. Some are obscure/older
      enough a release may never show up automatically — check `Activity > Queue` / wanted
      list in a few days. See decision log 2026-08-16 for the full "21 unscanned NAS folders"
      investigation.
- [x] **Cinemateca frontend fixed — self-hosted, dropped Vercel** (2026-08-16). Was
      `pelis.matiasmassetti.com` (Vercel) → CORS error hitting the Access-protected
      `cinemateca.matiasmassetti.com` API. Now built + served from the same container
      (`~/Code/tracker-nas/webapp`). See `decisions/log.md` for the full root cause.
- [ ] **Retire the `pelis.matiasmassetti.com` Vercel project** — needs Matias's Vercel
      account, not doable from here. Now fully superseded by `cinemateca.matiasmassetti.com`
      serving the same frontend itself.
- [ ] **`tracker-nas`/Cinemateca known bugs, deliberately deferred 2026-08-16** — see the
      repo's own `PENDIENTES.md` for the full list: watchlist cache doesn't invalidate on
      `/api/sync`, "IMDB Top 250" is actually TMDB's `top_rated` list mislabeled, missing
      mobile back button on `FamousDirectors`, dead code in `sheets.py`/`top250.json`.
- [x] **Old `media-tracker-api.service` systemd unit removed** (2026-08-15, Matias ran it
      manually — needed an interactive sudo password). Verified: `systemctl status` now
      returns "could not be found", unit file gone from `/etc/systemd/system/`, not in
      `systemctl list-units --all` either. Fully superseded by the `media-tracker-app` Docker
      container.
- [x] **DNS CNAME for `coleccion.matiasmassetti.com`** — added via API 2026-08-15 once the
      token's DNS scope got fixed (see below). Verified end-to-end: `https://coleccion.matiasmassetti.com/`
      resolves and returns a 302 to the Cloudflare Access login, confirming DNS + Tunnel +
      Access are all wired correctly.
- [x] **4K Collection Tracker data cleanup** (2026-08-15) — 12 duplicate rows removed (kept
      the more complete/watched copy of each — see decision log for the two cases with real
      differences: Akira's purchase price, The Exorcist's watched flag); John Wick: Chapter 4
      format corrected to Blu-ray; 16 missing titles inserted with full TMDB enrichment
      (director, cast, genres, poster, etc. — same quality as the rest of the collection).
      Godzilla Minus One confirmed correct as-is (Matias does own it — the *Sheet* was the one
      missing it, not the DB; still needs adding to the Sheet, see the sync-workflow item
      below). DB now at 86 items (was 82, -12 dupes +16 new).
- [x] **4K tracker "add a movie" workflow — resolved, no Sheets API needed** (2026-08-15).
      Dropped the two-way Sheet↔DB sync idea (Google Sheets API write access, extending
      `gcal_oauth.json` or a new credential) in favor of something simpler: the app already
      had working `/add` and `/item/:id/edit` pages (`AddItem.tsx`/`EditItem.tsx`, verified via
      a live create+delete smoke test through `/api/media` — works) — so adding a movie from
      the web was already solved, just untested until now. Added
      `GET /api/media/export.csv` (button in Settings, next to the existing JSON backup
      export) so the Sheet becomes a disposable, always-fresh export instead of a second thing
      to keep in sync — no more manual Sheet maintenance at all. Three ways to add a movie
      going forward: the web form, telling Claude here (who does a TMDB lookup + `INSERT`,
      as done for the 16 backfilled titles), or bulk JSON import. Godzilla Minus One (the one
      item missing from the old Sheet) will show up correctly next time the CSV is exported.
- [x] **The Handmaiden (2016) Radarr re-grab loop — confirmed stopped** (verified 2026-08-16,
      ~2 days / many RSS Sync cycles after the 2026-08-14 blocklist fix): no queue entry, file
      still present, no repeat "Manual Interaction" alerts. Closed.
- [x] **`docker.service` has no dependency on `mnt-opencloud.mount` — fixed 2026-08-23**. Real
      bug found 2026-08-16 during a host reboot: every container came back except `opencloud`,
      which started before its loop-mounted data dir (`/mnt/opencloud`, ext4-on-NFS) was ready
      and crashed on I/O errors. Fixed via a systemd override
      (`/etc/systemd/system/docker.service.d/override.conf`) adding `After=mnt-opencloud.mount`
      + `Requires=mnt-opencloud.mount`, applied with `daemon-reload` (no restart needed, running
      containers untouched — takes effect next reboot). Verified via `systemctl show docker.service
      -p After -p Requires`, both now list `mnt-opencloud.mount`. See decision log 2026-08-23.
- [ ] **`IDM_ADMIN_PASSWORD` in `docker-compose.yml` is stale** — doesn't match OpenCloud's
      actual `admin` account password anymore (reset 2026-08-16, see decision log). Not urgent
      (day-to-day login is the `matias` account, not `admin`), but worth updating next time the
      compose file is touched so it doesn't mislead a future recovery attempt.
- [x] **Cloudflare API token DNS scope — fixed 2026-08-15** — re-applied the token's Zone
      permissions in the dashboard (same token, "cloudflare tunnel minipc access"; the DNS:Edit
      grant had stopped working at some point after 2026-08-11, cause unclear). Verified with a
      real read (`GET .../dns_records`, `cen-api.matiasmassetti.com` came back correctly) and a
      real write (created the `coleccion.matiasmassetti.com` CNAME below via API). Fully
      programmatic DNS management is back — no more manual dashboard steps needed for future
      subdomains. Jellystat could now be exposed publicly if ever wanted (still deliberately
      Tailscale/LAN-only for now, that part hasn't changed).
- [ ] **77 movies still with no TMDB id in Jellyfin** (was 89, then 105/120 — see decision log
      for the full history). Matching report: `tmdb_match_results.json` was only in the session
      scratchpad, not saved to the repo — if it's gone, regenerate by re-running the same
      Jellyfin-RemoteSearch-based matching approach (see decision log 2026-08-13 entry for the
      method). Three sub-groups still open, Matias plans to do these by hand later:
      - [x] **13 medium-confidence — resolved 2026-08-16**, 12 of 13 applied (Jellyfin TMDB id
        + linked into Radarr, `monitored:true`/`hasFile:true`): El 30-30 tmdb:807680, Diarios
        Patagónicos 1 tmdb:399671, El diente ausente tmdb:1737730, The Professional
        tmdb:653348, Esteros tmdb:418718, Héroe Corriente tmdb:684021, Kill Bill: The Whole
        Bloody Affair tmdb:414419, La nueva cigarra tmdb:773918, Last and First Men
        tmdb:566038, Lectura según Justino tmdb:662609, Nosotros los decentes tmdb:322440,
        Black Buenos Aires tmdb:109817. **Workshop (1971) deliberately skipped** — checked
        tmdb:650842 directly and it's a 2020 film, confirming the flagged ~50-year mismatch was
        real; still needs a proper manual TMDB search, not this candidate.
      - [x] **8 of 9 "weak candidates" resolved 2026-08-23** — matched via TMDB search +
        cross-checked against each file's actual runtime (Jellyfin `RunTimeTicks`) before
        applying, all within ~0.6-6 min of the TMDB-listed runtime: Al centro de la tierra
        (2018→tmdb:367727, "To the Centre of the Earth"), Anida y el circo flotante
        (tmdb:632674), Antes del estreno (tmdb:307247, "Before Opening Night"), Cuando dejes de
        quererme (tmdb:502068), El hombre del futuro (tmdb:602008, "The Man of the Future"), La
        mala verdad (tmdb:245734, "Bad Truth"), La playa del amor (tmdb:484880, "The Beach of
        Love"), La vida por Perón (tmdb:174866). Applied via Jellyfin's `RemoteSearch/Movie` +
        `RemoteSearch/Apply` (picked the exact TMDB-id match from the candidates rather than
        just the first result), then added to Radarr (qualityProfileId 17 "2160p Efficient",
        `minimumAvailability: released`, explicit `path` reused so Radarr didn't rename the
        existing folder) and confirmed `hasFile:true` via `RescanMovie`.
        **Los pibes (2019) deliberately left unmatched** — the only TMDB candidate found (a 2015
        film, tmdb:627506) runs 78 min; the actual Jellyfin file is only 13.9 min, a 64-minute
        mismatch far outside any plausible rip/edit variance. Almost certainly a short or a
        misindexed extra, not that feature — moved to the "no confident match" bucket instead.
      - [x] **8 of 11 misindexed-extras fixed 2026-08-23** — confirmed via Jellyfin API each was
        indexed as a standalone `Movie` before touching anything. `Interview with Lisandro
        Alonso` (*La Libertad*), `Alternative opening scene` + `Interview with Lisandro Alonso
        on Los Muertos` (*Los Muertos*), `Presentación de Martin Scorsese` + `Restauración de
        Prisioneros de la tierra` (*Prisioneros de la tierra*), and the loose `Los guantes
        mágicos (Making of) (2003)` folder all moved into an `extras/` subfolder inside their
        real movie's folder (the loose one also relocated into *Los Guantes Mágicos (2003)*'s
        own folder, its now-empty original folder removed). `cast1.part1`/`cast2.part1` (*
        Castaway on the Moon*'s CD1/CD2 halves) got different treatment since they're the main
        film, not extras — renamed to Jellyfin's multi-part convention (`Castaway on the Moon
        (2009) - cd1.avi` / `- cd2.avi`) directly in the movie's folder instead. Ran a full
        `Library/Refresh` after: cd1 auto-identified as the real movie (tmdb:18438), cd2 folded
        in as its second part (no longer a separate item); all 6 extras re-typed from `Movie` to
        `Video`/absorbed as the parent's Extra — verified via the Items API, not just assumed.
      - [x] **`Deleted scene.mkv` (*La Libertad*) fixed 2026-08-23** — same as the 6 above, moved
        into `extras/`. Confirmed `Type: Video` post-refresh.
      - [x] **`dead set 1`-`5` fixed 2026-08-23** — moved out of the movie library entirely,
        into `/mnt/nas/Series/Dead Set (2008)/Season 01/`, renamed to Sonarr/Jellyfin episode
        convention (`Dead Set (2008) - S01E01.mp4` etc. — all 5, not just 1/4/5 as first
        thought; 2/3 already had wrong TMDB tags cleared 2026-08-14 but were never reorganized).
        Also found and deleted a leftover 36MB `sample/sample.mp4` release-sample file in the
        old folder before removing it. Post-refresh, Jellyfin auto-identified it as a proper
        `Series` with full metadata (imdb:tt1285482, tmdb:7831, tvdb:83427) — no longer 5 fake
        standalone movies. This closes every item from the original "11 misindexed extras"
        finding plus the 2 bonus ones found in the same pass (13 total).
      - [x] **Regenerated the "no match" list from scratch 2026-08-23** (the 2026-08-13 report
        was never saved to the repo). Ground truth via Jellyfin API: 59 movies had no `Tmdb`
        provider id (not 56 — some drift since the original count). Ran the same
        `RemoteSearch/Movie` + runtime cross-check as the weak-candidates batch above:
        - [x] **20 confident matches found and applied** — nobody had actually searched these
          with runtime verification before. All within 0-4.5 min of the TMDB runtime: A 40 años
          (tmdb:1546886), Aguas verdes/"Green Waters" (tmdb:377928), Beto Nervio contra el poder
          de las tinieblas (tmdb:613150), Camino del infierno/"Hell Road" (tmdb:342086), Chantal
          Akerman una autobiografía (tmdb:1710231), Como corre Elisa (tmdb:684283), De noche
          también se duerme (tmdb:722059), El cuento de las comadrejas/"The Weasel's Tale"
          (tmdb:574088, folder said 2009 but the real film is 2019 — a folder-name typo, runtime
          matched exactly at 129min so applied anyway), El grito de Celina/"Celina's Scream"
          (tmdb:614543), El invierno llega después del otoño (tmdb:399302), El juego de la
          silla/"Musical Chairs" (tmdb:457761), En ausencia (tmdb:1222723), Escuela trashumante
          (tmdb:459586), Fontana la frontera interior (tmdb:713087), La Caracas (tmdb:452155), La
          utilidad de un revistero (tmdb:525396), Lluvia de jaulas (tmdb:578495), Los hijos del
          viento (tmdb:1017093), Memorias de Cortázar (tmdb:818389), Mengele el ángel de la
          muerte (tmdb:274106). Applied via Jellyfin `RemoteSearch/Apply`, added to Radarr
          (qualityProfileId 17, explicit `path` reused), confirmed `hasFile:true` via
          `RescanMovie` for all 20.
          **Workshop (1971) deliberately excluded again** despite a close-ish runtime match
          (11min file vs 16min candidate, tmdb:650842) — that candidate is a *2020* film, the
          same ~50-year mismatch flagged 2026-08-16. Still needs a real manual search.
        - [x] **All 12 "ambiguous" ones resolved 2026-08-23** — reviewed one by one with Matias.
          6 applied (some needed an IMDb→TMDB lookup via Radarr's `movie/lookup?term=imdb:...`
          since Jellyfin's own TMDB-plugin name search didn't surface them — turned out an OMDB
          plugin is also installed on Jellyfin and was returning IMDb-only candidates with no
          Tmdb id for these; Radarr's lookup resolved the real TMDB id from that IMDb id): Cómo
          llegar a Piedrabuena/"Cómo llegar a Piedra Buena" (tmdb:1091816, 0.5min runtime diff),
          Juan Lamaglia y señora/"Juan Lamaglia y Sra." (tmdb:613375, 1.3min diff), Tres citas con
          el destino (tmdb:444281, 4.8min diff), La sangre brota/"Blood Appears" (tmdb:187165,
          7.4min diff — double-confirmed via both direct TMDB search and IMDb lookup landing on
          the same id), Fiesta Nibiru (tmdb:568316, 7.7min diff, the single available candidate),
          Gustavo Cerati - Fuerza Natural Tour (tmdb:652817, no TMDB runtime data to verify but
          it's today's own concatenated file so the title match alone was enough — already added
          to Radarr earlier the same session). All confirmed `hasFile:true` via `RescanMovie`.
          6 moved to the no-match bucket below: Cautivame, Gustavo Leguizamón creando la Tierra,
          Los pibes, Matar la tierra, and Reflectorista all came back with **zero** Radarr/TMDB
          hits even via IMDb lookup (OMDB knows them, TMDB genuinely doesn't). **Siesta**
          specifically investigated further — Matias identified the real film as Julia
          Solomonoff's 2018 short (FilmAffinity #580547); checked TMDB's two 2018-tagged "Siesta"
          candidates via their full crew credits and neither is her (David Chacón and Azucena
          Losana directed those) — Solomonoff's "Siesta" isn't catalogued on TMDB under this
          title at all.
        - **32 with zero real TMDB match** (up from 26 — the 6 from the ambiguous batch above
          folded in): 4 lonkos Vida muerte y profanación, Cacho pallero el año del surubí,
          Cautivame, El día que nos conocimos, El hombre que amaba los platillos voladores, En el
          país de las últimas cosas, Fantasmas de Buenos Aires, Formoskate, Gustavo Leguizamón
          creando la Tierra, Industria Argentna, Juana a las 12, Kombit, La chica de los lunes, La
          idea del lago, La tumba sin nombre, Las Chicas de Flores, Les louves, Lesbianas en
          Buenos Aires, Los pibes, Matar la tierra, Muñequita porteña, Partida la verdad no le
          teme a nada, Premier mai, Reflectorista, Rosario Bléfari en el CCK, Siesta (2018,
          Solomonoff), Silvia Prieto (documental final), Soldado argentino solo reconocido por
          Dios, Tertulia N° 250, Trece años y medio (documental sobre Rapado), Tres hombres en el
          río, Zulay frente al siglo XXI. Mostly very obscure Argentine shorts/documentaries,
          genuinely uncatalogued on TMDB as far as this search can tell — can't get a
          Radarr/Bazarr entry unless that changes.
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
