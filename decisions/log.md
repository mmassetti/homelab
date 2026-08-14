# Architecture Decision Records

## 2026-08-12 (last one, really) — Unstuck a dead torrent, confirmed usenet-preference already works

**Context**: Matias asked to unblock a "Jackass 3.5" download stuck since 03:24 that morning
("stalled with no connections"). Checked `GET /api/v3/release?movieId=87`: the healthiest
option by far — a YIFY release with 59 seeders — was being auto-rejected for hitting the
"Banned Groups" custom format (score -819999), and a second decent one (50 seeders) failed
Radarr's title-matching ("Unknown Movie"). Every other candidate had 0-4 seeders, effectively
dead. This led into a broader question: how does Radarr currently choose between usenet and
torrent when both are available, since Matias has noticed usenet performing more reliably for
him and wants it preferred going forward.
**Decision**: For Jackass specifically — removed the dead download
(`removeFromClient=true&blocklist=true&skipRedownload=false`), ran a fresh search (found
nothing better automatically, for the reasons above), then force-grabbed the 59-seeder YIFY
release via `POST /api/v3/release` with its `guid`+`indexerId` — Matias explicitly chose to
override the "Banned Groups" rejection given the alternative was either a dead torrent or
nothing. For the broader usenet-preference question: checked `GET /api/v3/delayprofile` and
found `preferredProtocol: usenet` **already set**, with both `usenetDelay`/`torrentDelay` at 0
(so no artificial waiting — highest-scoring option grabbed immediately, ties broken in favor of
usenet). This was already correct, likely from the original Recyclarr/TRaSH template sync — no
change was needed. The Jackass case didn't hit this preference at all: there was no usenet
candidate for that title, only torrent, so nothing was actually being chosen between.
**Rationale**: Confirmed rather than assumed the delay profile config, since "usenet feels more
reliable" is exactly the kind of preference that's easy to think is enforced when it's actually
just been true by chance so far. Worth remembering the real limiting factor going forward:
usenet coverage is capped by having only one usenet indexer (`NZBgeek`) against three torrent
ones, so for less common titles torrent is often the only option regardless of the (already
correct) protocol preference — adding another usenet indexer would matter far more here than
any Radarr setting change.

## 2026-08-12 (later again) — Fixed Jellystat login (SHA3 hash vs. plaintext mismatch)

**Context**: After installing Jellystat, Matias couldn't log in with the credentials given —
"invalid username or password" — from two completely different devices (phone via Tailscale
and LAN, Mac via Tailscale and LAN), consistently, immediately, in incognito. Ruled out (via
direct `curl` from the mini PC itself, matching his exact IP/port): wrong credentials — DB
inspection (`SELECT * FROM app_config`) showed byte-exact match to the credentials given, no
whitespace;
network/CORS — login succeeded via curl over both LAN and Tailscale IPs, with Origin/Referer
headers set; rate-limiting/lockout — none found in the backend source; hardcoded wrong API URL
in the frontend bundle — none found.
**Decision**: Read `/app/backend/routes/auth.js` directly. `/auth/login` compares
`user.APP_PASSWORD === password` against whatever's stored in `app_config.APP_PASSWORD` — a
**plain equality check, no hashing on the backend**. But `/auth/createuser` and
`/api/updatePassword` also just store whatever `password` value they're sent, verbatim, again
with no hashing. Both of those were called via raw `curl` with the plaintext password, so the
DB held plaintext. The frontend's actual login form, however, hashes the password client-side
with `CryptoJS.SHA3(...)` (512-bit output, seen in the bundle at
`/app/dist/assets/index-*.js`) before ever sending it — confirmed by temporarily patching
`auth.js` to `console.log(req.body)`, restarting the container, and asking Matias to attempt
one real login: the captured request showed `username: "matias"`, `password: "<128-hex-char
SHA3 hash>"`. Computed `SHA3(<the password>)` inside the container and it matched the captured hash
exactly. Fixed by `UPDATE app_config SET "APP_PASSWORD" = '<that hash>'` directly in Postgres —
now the frontend's hashed submission matches the stored value. Verified: login with the SHA3
hash succeeds, login with the raw plaintext now correctly fails (401) — consistent with what
the real login form does. Removed the debug `console.log` and restarted clean.
**Rationale**: This is a real bug in Jellystat (or at least an undocumented contract) — any
password set through its own API endpoints rather than its own frontend form will silently
never work, with no indication of why beyond a generic auth failure. Worth remembering for any
future Jellystat password change: **always go through the web UI's own forms**, or replicate
the SHA3 hashing manually before calling the API directly.

## 2026-08-12 (yet again later) — Backfilled the rest of the movie library into Radarr

**Context**: Following up on the earlier 8-title Radarr backfill (done to unblock subtitle
management for a handful of titles), Matias asked whether it's worth linking the *entire*
unlinked library — 2432 of 2517 Jellyfin movies had no Radarr entry at all. First attempt used
Jellyfin's stored IMDb id per movie for the Radarr lookup and immediately caught two silent
mismatches in just a 5-title test: "...E tu vivrai nel terrore! L'aldilà" (the correct movie,
in a folder literally named "The Beyond (1981)") matched to "Battle Beyond the Stars", and
Fellini's "8½" matched to "Interpol Code 8" — both from Jellyfin already holding a bad IMDb id
for those items independent of anything in this session. Switched to using Jellyfin's own
**TMDB id** instead (also stored per-item, and what Jellyfin's own displayed title/artwork
already reflects) — re-tested the same 5 titles and all matched correctly, including a genuine
oddity ("8ミリ生フィルムのすべて" turned out to correctly be "Everything about 8mm Raw Film",
not a mismatch). Also applied a folder-depth safety filter (skip any movie whose file isn't
directly one level under its own `Title (Year)/` folder) after finding "A Cure For Wellness
(2016)" nested inside the unrelated "25th Hour (2002)" folder — a real, pre-existing library
organization bug, left for manual review rather than auto-imported.
**Decision**: Classified all 2517 Jellyfin movies: 2277 safe to auto-batch (has TMDB id, one
file directly in its own folder, not already tracked), 105 with no TMDB id, 58 in nested/
multi-file folders — the latter two buckets set aside for manual review, not touched. Built a
script with an explicit safety gate before committing to the full run: import + `monitored:
false` + `searchForMovie: false` for a 150-title canary batch first, then **wait for one real
RSS Sync cycle to complete** (Radarr's `2160p Efficient` profile has `upgradeAllowed: true`,
and RSS Sync runs every 30 min — a genuine risk of triggering "upgrade" downloads for perfectly
fine existing files) and check Radarr's queue + grab history for any activity tied to the
canary's movie IDs before proceeding. Canary came back clean (`queue_hits=0 grab_hits=0`), so
the remaining 2077 titles ran in batches of 200 back-to-back. Final result: **2210 linked**,
**60 left needing a rescan retry** (mostly false negatives — see below), **7 errors** (5 were
harmless duplicates from the earlier manual test run, 2 were loose files sitting directly in
the root `Peliculas/` folder with no enclosing subfolder, which the path-parent logic can't
handle — left for manual review), **0 lookup failures**.
Of the 60 "rescan failed" entries, a spot-check on "El secreto de sus ojos" (Radarr title: "The
Secret in Their Eyes") showed `hasFile: True` when re-checked minutes later, despite having
been logged as failed during the run — the script's rescan-poll only waited 3 seconds, too
short under the heavy concurrent NAS load from Jellyfin's library scan + Bazarr's subtitle
search + this import all running at once. Ran a reconciliation pass after the full run
completed: re-checked all 60, flipped `monitored: true` for any now showing `hasFile: true`.
**51 of 60 were exactly this false-negative timing issue**; only **9 have a genuine path
mismatch** (folder name casing, e.g. "The boat that rocked" vs. the folder's actual "The Boat
That Rocked") and remain safely unmonitored, unresolved, for manual review.
Verified no unwanted downloads occurred across the *entire* run, not just the canary: Radarr's
queue at the end still showed only the one pre-existing stalled Jackass 3.5 torrent
(`movieId: 87`, added `03:24:19Z` — hours before this session started, completely unrelated),
identical to before the run began.
**Rationale**: The IMDb→TMDB pivot is the single most important lesson here — trusting a
"foreign key" the source system already got wrong just propagates the error at scale instead
of fixing anything, while trusting the *same* identifier the family already sees in Jellyfin
guarantees Radarr and Jellyfin can never silently disagree about which movie is which. The
canary-then-wait-then-proceed pattern is worth reusing for any future bulk operation against a
profile with `upgradeAllowed: true` — cheap insurance against a slow-burn storage/bandwidth
surprise that wouldn't show up until the next RSS cycle, by which point it'd be too late to
catch before the first batch ran.

**Follow-up items left for manual review** (not urgent, none of it broken/dangerous as-is):
- 105 movies with no TMDB id in Jellyfin at all
- 58 movies in nested or multi-file folders (mix of legitimate extras, multi-part rips, and at
  least one real mismatch — "A Cure For Wellness" living inside "25th Hour"'s folder)
- 9 movies where Radarr still can't find the file after the path it was given (folder name
  casing mismatches, most likely)
- 2 movies whose files sit loose directly in `Peliculas/` root with no enclosing folder ("El
  Partido", "La cara oculta")

## 2026-08-12 (still later) — Installed Jellystat

**Context**: Original TODO item from earlier in the day (Playback Reporting vs. a nicer visual
dashboard) — decided to add Jellystat rather than rely on raw Playback Reporting SQL queries
going forward.
**Decision**: Added `jellystat` (`cyfershepard/jellystat`) + a dedicated `jellystat-db`
(`postgres:18.1`) to `/opt/docker/docker-compose.yml`, on `arr_network`, port 3002. Generated
Postgres password and JWT secret with `openssl rand`. Setup (admin account creation + Jellyfin
connection) done entirely via Jellystat's own API — `POST /auth/createuser` then
`POST /auth/configSetup` — no browser click-through needed. Verified via
`GET /api/getLibraries` that it correctly sees the Películas/Series libraries.
Attempted to expose it via the existing Cloudflare Tunnel + Access (matching every other
admin-only tool) but the API token returned "Authentication error" on the zone's DNS records
endpoint specifically, even though it can list zones and edit the tunnel — an unresolved scope
mismatch, not investigated further. Asked Matias how to proceed; he chose local/Tailscale-only
access for now rather than debug the token, since it's a personal stats dashboard with no
other users.
**Rationale**: Fully API-driven setup keeps this repeatable/scriptable like every other change
this session, rather than a one-off manual browser walkthrough that isn't documented anywhere.
Deferring the public-exposure question was the right call given it's low-stakes (nobody else
needs this tool) and the token issue deserves a dedicated look rather than a rushed workaround.

## 2026-08-12 (yet even later) — Switched default quality profile, backfilled Radarr for legacy
## movies, fixed a metadata mismatch, and added a Whisper AI subtitle provider

**Context**: Reviewing transcoding led to reviewing Radarr/Sonarr quality profiles. Found
Jellyseerr's default profile for new requests was "2160p Remux" (raw Blu-ray/UHD extraction,
no compression) — 68 of 77 Radarr-tracked movies (88%) were remux, almost certainly the main
driver of the NAS being nearly full. Switched Jellyseerr's Radarr *and* Sonarr default profile
to "2160p Efficient" (prefers well-regarded x265 encode groups — HONE/QxR/TAoE — at a fraction
of remux size). Tradeoff made explicit via the profile's own custom-format scores: "Efficient"
scores `Lossless Audio` at -999999 and TrueHD/DTS-HD MA/Atmos/DTS-X at 0 (vs. Remux scoring
those 1200-1600), so future downloads will generally carry Dolby Digital+ instead of lossless/
object-based audio. Video quality is unaffected. Only matters if a home theater with an
Atmos-capable receiver enters the picture later — imperceptible on phone/browser/TV speakers.

Separately, checked subtitle compatibility across the 100 most-recently-added movies via
Jellyfin's MediaStreams: 54 had a text-based track (fine), 11 had *only* image-based (PGS/DVD)
subs — forces a full burn-in transcode on any client that can't render PGS overlay (most
browsers/mobile apps). Cross-checked all 11 against Bazarr by IMDb ID: **none were tracked by
Bazarr** — they were added to the NAS before the Radarr/Jellyseerr pipeline existed, so Bazarr
(which only manages Radarr/Sonarr-known items) had no way to search subtitles for them.

**Decision — Radarr backfill**: Confirmed `renameMovies: false` and `autoRenameFolders: false`
in Radarr's config before touching anything (critical — don't want Radarr moving/renaming
files a live family library already points at). For 8 of the 11 titles (To Catch a Thief,
Interstellar, Hail Caesar!, Fallen Angels, Empire of the Sun, Short Memory, Mercano el
Marciano, Pirates of the Caribbean), looked up each via Radarr's lookup-by-IMDb endpoint, added
via `POST /api/v3/movie` with `monitored: false` and `addOptions.searchForMovie: false` (so it
can never trigger a new download), path pointed at the *existing* NAS folder (translated from
Jellyfin's `/data/movies/...` mount to Radarr's `/movies/...` mount — same NAS folder, two
different container mount points), then triggered `RescanMovie` to link the existing file.
Verified `hasFile: true` on all 8 before flipping `monitored: true`. Test movie (To Catch a
Thief) was done alone first and fully verified before batching the rest. Bazarr's Radarr sync
picked up all 8 immediately after.

**Decision — "The Club" (2015) metadata bug found along the way**: the 3 excluded titles all
lived in one folder, `The Club (2015)/`, which turned out to have a real metadata problem: the
actual movie (Pablo Larraín's *El Club*, TMDB 319995) was misidentified by Jellyfin as **"Winx
Club: The Mystery of the Abyss"** (TMDB 290841 — wrong film entirely), and two bonus
featurettes plus a Berlinale Q&A clip were sitting as loose files in a subfolder named
`The.Club.Extras-Grym` — not a name Jellyfin recognizes as bonus content, so each got indexed
as its own standalone "movie". Fixed via `POST /Items/RemoteSearch/Apply/{itemId}` with the
correct TMDB match for the main film, and renamed the subfolder to `extras` (a name Jellyfin
does recognize) so the 3 clips get associated with the parent movie as bonus features instead
of polluting the movie list. Verified post-fix: search for "Club" only returns "The Club" with
correct synopsis; the 3 extra files no longer appear as separate Movie items.

**Decision — Whisper AI subtitle provider**: researched what's added beyond standard Bazarr
providers for hard-to-find subtitles (WebSearch: Bazarr's official Whisper Provider wiki page,
McCloudS/subgen GitHub). Existing `enabled_providers` already covered Latino/Argentina sources
well (`subdivx`, `subtitulamostv`, `subtis` were already on). Added `subgen` (`mccloud/subgen:
cpu`, no NVIDIA GPU on this host) as a new service on `arr_network`, pointed Bazarr's
pre-existing (but previously unused) `whisperai.endpoint` config at `http://subgen:9000`
(Docker-network hostname — `127.0.0.1` would resolve to Bazarr's own container, not subgen's),
and added `whisperai` to `enabled_providers`. `PROCESS_ADDED_MEDIA`/`PROCESS_MEDIA_ON_PLAY` set
`False` so subgen is purely a Bazarr-triggered provider, not an auto-webhook processor.
Verified live: a manual provider search for "Mercano, el marciano" (Spanish-language Argentine
film) returned a `whisperai` candidate — "transcribe Spanish audio -> Spanish SRT" — confirming
the HTTP integration works end-to-end.
**Important limitation flagged to Matias before implementing**: Whisper's `translate` task only
ever outputs English — there's no way to get it to translate directly into Spanish. So this
provider only helps when the *audio* is already in the target subtitle language (transcribe
mode) or when English audio needs an English subtitle. It does not solve the far more common
case in this library — English-audio movies needing a Spanish subtitle — that still depends on
the existing human-subtitle providers finding a match.

**Rationale**: All four changes came from the transcoding review going wider once the profile
scoring made the storage-vs-quality tradeoff visible in hard numbers, and once the subtitle
compatibility check surfaced two adjacent problems (untracked legacy movies, a genuine metadata
mismatch) that were worth fixing while already in that part of the stack. The Radarr backfill
in particular sets a repeatable pattern for any future case of "great, why doesn't Bazarr know
about this movie" — check `renameMovies` first, always test one title end-to-end before
batching.

## 2026-08-12 (even later) — Fixed VAAPI hardware transcoding passthrough on Jellyfin

**Context**: Matias asked to evaluate the state of transcoding. Investigation found Jellyfin's
own encoding config already had `HardwareAccelerationType: vaapi` and
`VaapiDevice: /dev/dri/renderD128` set, and `ffmpeg` correctly detected the AMD Radeon 780M's
hw encoders (`hevc_vaapi`, `av1_vaapi`, `h264_vaapi`, etc.) — but the `jellyfin` container in
`/opt/docker/docker-compose.yml` never had `/dev/dri` passed through at all
(`docker inspect jellyfin` showed empty `HostConfig.Devices`). Every real hardware transcode was
failing outright: live logs showed a 4K HDR HEVC title (`The Invite (2026)`) hitting
`FFmpeg exited with code 237` (VAAPI init failure) repeatedly. Checked Playback Reporting for
the last 30 days: 67 direct plays vs 61 "transcode" sessions, but most of those were
audio-only remuxes (video copied direct) — only ~13 sessions needed real video re-encoding,
which is where the missing GPU access actually hurt (forced CPU-only software fallback on the
heaviest content: 4K HDR/AV1).
**Decision**: Confirmed no one was actively watching (`GET /Sessions`) before touching the
container. Added `devices: [/dev/dri:/dev/dri]` and `group_add: ["993"]` (host `render` group,
owns `/dev/dri/renderD128`) to the `jellyfin` service in `/opt/docker/docker-compose.yml`,
recreated the container. Verified: `/dev/dri` now visible inside the container with the
`render` GID mapped in as a supplementary group; re-ran the exact 4K HDR file that failed
before through `ffmpeg -hwaccel vaapi` manually inside the container — encoded cleanly at
1.32x realtime speed, zero errors.
**Rationale**: The GPU was already sitting idle and Jellyfin's software config already assumed
it was available — this was a one-line infra gap, not a design decision, and low-risk (device
passthrough only, no data touched, instantly revertible). With multiple family members
streaming concurrently, freeing 4K/HDR transcodes from the CPU meaningfully reduces contention
risk under simultaneous playback.

## 2026-08-12 (later still) — Migrated Jellyseerr → Seerr (2.7.3 → 3.4.1)

**Context**: Matias noticed the running Jellyseerr (`fallenbagel/jellyseerr:latest`, but stuck
at 2.7.3 despite the `latest` tag) was well behind the project's GitHub releases, now under
`seerr-team/seerr`. Research confirmed this isn't just a version bump — Jellyseerr and Overseerr
officially merged into a single project, "Seerr", with development continuing there;
`fallenbagel/jellyseerr` won't see further releases. Official migration guide
(docs.seerr.dev/migration-guide) documents an automatic data migration on first startup — no
manual DB steps — but two breaking changes: the new image runs as a non-root `node` user
(UID 1000) instead of root, so the bind-mounted config directory needs matching ownership; and
the container no longer provides its own init process, so `init: true` is mandatory in compose
(without it, zombie processes / signal handling breaks).
**Decision**: Matias asked for a recommendation rather than deciding blind — advised updating
now rather than waiting, since staying on the dead branch only accumulates more drift while a
backup makes it trivially reversible, and the two breaking changes were already fully
understood before touching anything. Backed up `/opt/docker/configs/jellyseerr` (1.9MB
compressed) to `/opt/docker/backups/jellyseerr-preseerr-<timestamp>.tar.gz` first. Swapped the
image in `/opt/docker/docker-compose.yml` to `ghcr.io/seerr-team/seerr:latest`, added
`init: true`. First start failed with `EACCES` on a log file — turned out most of the config
was already `matias:matias` (his UID is 1000, matching what Seerr expects) but a handful of
`.machinelogs-*.json(.gz)` files had been created `root:root` by the old container, which *did*
run as root. Fixed with a recursive `chown matias:matias` on the whole config dir (no `sudo`
needed since Matias already owned the parent directory), matching the official guide's
recommendation exactly rather than skipping it on the assumption top-level ownership was
sufficient. Second start came up clean: `Starting Seerr version 3.4.1`, settings migrations
0001–0008 auto-applied, server ready. Verified after: Radarr/Sonarr connections intact, all
three users' Telegram notification settings from earlier today (Matias/Bianca/negro, both
admin-level and per-user) survived untouched, and `pedidos.matiasmassetti.com` still resolves
correctly through the tunnel.
**Rationale**: A live, multi-user-facing service (the only one in the stack besides Jellyfin
that non-admin users touch directly) deserved a backup-first, verify-after approach even though
the migration path was well-documented and low-complexity. The permission error on first boot
is exactly the kind of thing the official guide's "fix folder ownership" step exists to prevent
— worth noting for the *next* fallenbagel-style image swap: don't assume top-level directory
ownership implies every file under it matches, check with `find -not -user <expected>`.

## 2026-08-12 (yet later) — Built "Viernes de Novedades" weekly digest

**Context**: Matias wanted a weekly (not per-title) heads-up for Jellyseerr users about new
content, rather than the per-request notifications set up earlier in the day. Built as a
sibling to Morning Brief: same standalone host-cron + direct Telegram Bot API architecture, but
broadcast instead of single-recipient — every Jellyseerr user with Telegram notifications
enabled and a chat ID gets it, discovered live via Jellyseerr's own user API each run (no
hardcoded list, so newly-linked users are picked up automatically with zero script changes).
**Decision, in the order features were added/iterated**:
1. Base digest: what got added to the server in the last 7 days (Radarr/Sonarr history, same
   pattern as Morning Brief's 24h version) + trending suggestions not in the library
   (Jellyseerr's `/discover/trending`, filtered to `mediaInfo.status` None/1). Skips sending
   entirely if both are empty that week — no filler message.
2. Added cinema releases: scraped `carteleraargentina.com.ar`'s "Estrenos de la semana" block.
   First attempt at a "still showing" companion section used poster-upload-date-on-the-national-
   site as a recency heuristic — **replaced** once Matias pointed at Cinemacenter's own Bahía
   Blanca listing, which turned out to publish a real weekly schedule PDF
   (`horariospdf.php?cityId=2`) extractable with `pdftotext -layout`. Swapped the heuristic for
   this authoritative source without hesitation — a real per-cinema listing beats an inference
   from a national site every time it's available. Titles get deduped across the format
   variants the PDF lists separately (2D/3D/Sala Turbo showings of the same film) and
   cross-excluded against the national Estrenos list via accent/case-insensitive matching so a
   film isn't shown in both sections.
3. Added "lo más visto esta semana" via the same Playback Reporting SQL-query API used in
   earlier notification work, and direct `pedidos.matiasmassetti.com/{type}/{id}` links on each
   suggestion so tapping goes straight to a request instead of requiring a manual search.
4. Added a poster image (Telegram `sendPhoto`) for the top suggestion, sent before the text
   digest — visual variety instead of an all-text message.
5. Added a "rescate del catálogo" pick — originally algorithmic (never-played + added 90+ days
   ago, via a Playback Reporting distinct-titles query intersected with Jellyfin's item list).
   Matias asked to replace it with a manually curated list instead — better taste signal than
   an algorithm, and gives him control over what actually gets recommended. Built
   `scripts/rescate-catalogo.txt` (one title per line) and had Claude seed it with ~105 titles:
   not a blind `ORDER BY CommunityRating` (which surfaces obscure films with 2-3 perfect-10
   votes ahead of anything actually well-known — the same trap the pre-existing "Imprescindibles"
   Jellyfin collection had already fallen into, checked and confirmed rather than reused),
   instead a hand-built canon of acclaimed films cross-referenced title-by-title against the
   real Jellyfin library via its API, keeping only confirmed exact matches.
6. Renamed "Rescate del catálogo" → "🎯 Pick de la semana" (Matias: the old name "didn't say
   anything" to him) and enriched it with year, up to 2 genres, and a trimmed synopsis pulled
   from Jellyfin (`Fields=Genres,ProductionYear,Overview`) instead of a bare title.
7. Renamed "Se sumó esta semana" → "Se sumó al server de Masa" to disambiguate from the new
   cinema sections once there were two different kinds of "movie news" in the same message.
8. Added tiered NAS free-space messaging instead of bare numbers: >100GB free → "pedí tranqui,
   hay espacio 😌"; ≤30GB → "se está quedando sin espacio, pedí con cuidado ⚠️"; in between,
   just the numbers. Deliberately keyed off absolute GB free rather than percent-used, since
   this NAS runs around 96% used by design (large array with redundancy headroom) — a
   percent-based threshold would cry wolf every single week.
9. Added `DRY_RUN=1` (prints, sends nothing) and `TEST_CHAT_ID=<id>` (real send, one recipient
   only, bypasses normal discovery) modes from the start, specifically because this script
   broadcasts to real people (not just Matias) — every iteration during this build was tested
   dry or single-recipient, never against the live broadcast list, per explicit instruction.
10. Scheduled `0 19 * * 5` UTC (4:00 PM ART, Fridays) — Matias's first ask was 6 PM, revised to
    4 PM after seeing the built digest.
**Rationale**: Same "verify live, don't assume" discipline as the rest of the day's work — the
Cinemacenter PDF swap and the Imprescindibles-collection check both came from actually looking
rather than trusting a plausible-sounding first approach. The `DRY_RUN`/`TEST_CHAT_ID` modes
exist because this is the first script built today that talks to people other than Matias by
default — a bug here doesn't just clutter his own chat, it reaches Bianca and negro too.
**Follow-ups not done yet**: `rescate-catalogo.txt`'s synopses come back in English (Jellyfin's
stored `Overview` reflects whatever language its metadata agent pulled, not per-request
localization like Jellyseerr's discover endpoint uses) — not raised as an issue yet, but if it
comes up, fixing it would mean a TMDB call for a translated overview rather than trusting
Jellyfin's cached field.

## 2026-08-12 (later still) — Retired OpenClaw, rebuilt Morning Brief standalone

**Context**: OpenClaw had already been fully torn down (see the 2026-08-11 audit entry below)
but was still documented as if it might come back, and its one real remaining artifact — the
Morning Brief cron script — was broken because it shelled out to `docker exec openclaw-gateway
...` for both the infra check and, critically, for actually sending the Telegram message. With
Remote Control now covering the "chat with an agent from my phone" need that OpenClaw used to
serve (see the mobile-access conversation earlier the same day), reviving OpenClaw for that
purpose stopped making sense — it would mean maintaining a second agent stack (Docker socket
exposure, third-party ClaWHub skills with a known supply-chain flag) for no remaining benefit
except the proactive daily push, which doesn't need a whole agent framework to achieve.
**Decision**: Formally retired OpenClaw in the docs (`services/services.md`, `CLAUDE.md`) —
trimmed the long "currently not running" writeups down to short pointers at this entry, rather
than leaving them looking like a paused-but-resumable service. Rebuilt `morning-brief.sh` to
be fully standalone: sends via the Telegram Bot API directly (`@masa_server_bot`) instead of
OpenClaw's CLI, checks infra with a plain `docker ps` instead of `docker exec`ing into a
container that no longer exists. Along the way, revamped the content per Matias's requests:
- **Tech/AI section switched from TechCrunch (English) to WWWhat's New RSS (Spanish)** —
  tried Xataka first (a more prominent Spanish tech outlet) but neither its tag nor category
  `/rss` URLs actually serve RSS/XML (they 200 into an ordinary HTML article page instead,
  despite the URL shape suggesting a feed) and its homepage has no `<link rel="alternate"
  type="application/rss+xml">` either — no accessible feed found. WWWhat's New's `/feed/`
  works cleanly and is AI/tech-focused.
- **Added Twitter/X trending topics (Buenos Aires)** — X's own trends API requires paid
  access now, so this scrapes `trends24.in/argentina/buenos-aires/` directly (plain HTML,
  no JS rendering needed — the current snapshot is the first `<ol class=trend-card__list>`
  block on the page).
- **Added today's TV-broadcast football matches** — no official Promiedos API exists;
  community wrapper projects on GitHub all scrape Promiedos's HTML themselves (via Cheerio),
  so rather than depend on someone else's hosted scraper, fetched `promiedos.com.ar` directly
  and found it embeds full structured match data (teams, times, status, TV network, even
  odds) in a `__NEXT_DATA__` script tag — standard Next.js server-side props, no headless
  browser needed. Filtered to games with a non-empty `tv_networks` list as the "interesting"
  heuristic (broadcasters only air notable games).
- **Added Jellyseerr pending requests and Radarr/Sonarr last-24h downloads** — straightforward
  API calls now that the pattern was established earlier in the day for the Telegram
  notification work; the tricky part for Radarr/Sonarr was discovering the `includeMovie=true`
  / `includeSeries=true&includeEpisode=true` query params, since the history endpoint returns
  only bare IDs (`movieId`/`seriesId`/`episodeId`) by default, not human-readable titles.
- **Title changed to "☀️ Resumen Matutino"** (was "Morning Brief"), **removed the 🦞 emoji**
  from the closing line (that was Claudito/OpenClaw's mascot, no longer relevant).
- Re-enabled the host crontab entry (`0 11 * * *` UTC = 8:00 AM ART) that had been sitting
  commented-out.
**A real bug caught during testing**: the football section came up empty on first run. Root
cause: the mini PC's system timezone is UTC, and the football-matching code used a bare
`datetime.now()` to compute "today's date" for filtering — in the evening in Argentina (UTC-3),
that's already tomorrow in UTC, so it filtered for the wrong day and got zero matches. Fixed by
passing in `TZ="America/Argentina/Buenos_Aires" date +%d-%m-%Y` explicitly instead of trusting
system-local time inside Python. `gcal-today.py` was checked too and turned out to already
handle this correctly (`ZoneInfo("America/Argentina/Buenos_Aires")`), so it wasn't a systemic
bug — but it's exactly the kind of mistake that's easy to reintroduce in future edits to this
script, noted explicitly in `services/services.md` as a gotcha.
**Rationale**: A script that depends on a torn-down agent for its actual delivery mechanism is
worse than useless — it fails silently (cron redirects output to a log nobody's tailing) while
looking configured. Standalone + no agent dependency means it can't break again the same way
OpenClaw broke it. Content changes were straightforward preference (Spanish sources, sports
interest) but each new data source got verified live (actual HTTP requests, actual response
inspection) rather than assumed to exist, which is what caught both the Xataka dead-end and the
timezone bug before they shipped silently broken.

## 2026-08-12 (later same day) — Committed ricota-db to git, caught a hardcoded password first

**Context**: `ricota-db/` (Postgres 17 + PostgREST + Caddy, a Supabase-style REST API stack)
had been sitting inside the homelab repo since 2026-08-11, fully untracked. Matias wanted it in
GitHub, minus secrets.
**Decision**: Added a scoped `ricota-db/.gitignore` covering `.env`, `keys.txt`, and `data/`
(the live Postgres volume) — the repo-root `.gitignore` already caught `*.env` but not the
other two. Before staging, scanned every file that would actually get committed rather than
trusting the `.env`/`keys.txt` split to be the whole story — and found `init/01-roles.sql` had
the real `authenticator` role password **hardcoded in plaintext** (it has to be, since
Postgres's `docker-entrypoint-initdb.d` just runs raw SQL — no built-in env-var substitution),
which would have pushed a live DB credential straight to a public GitHub repo alongside
everything else. Added that file to the `.gitignore` too and replaced it with
`init/01-roles.sql.example` (placeholder password + a comment pointing at `AUTH_PW` in `.env`).
Did the same `.example` treatment for `.env` and `keys.txt`. Verified with a script that
sourced the real `.env`/`keys.txt` and grepped every file about to be staged for each actual
secret value, not just spot-checked — all clean. Committed and pushed.
**Rationale**: "Secrets live in `.env`" is an assumption, not a guarantee — anything that shells
out to raw SQL/config files during setup is a place a credential can leak in without anyone
intending it to. Grepping the *actual bytes* of what's about to be committed, for the *actual*
secret values (not just filenames matching a `secret`-ish pattern), is the only check that
would have caught this one; a purely filename-based `.gitignore` review would have missed it
since `01-roles.sql` looks like an ordinary schema file at a glance.

## 2026-08-12 — Cloudflare Access on admin-only hostnames + Sonarr auth fix

**Context**: Follow-up to the previous day's tunnel audit item "check whether the exposed
ARR-stack subdomains have any protection beyond their own app login." Rather than trust config
files, tested live against the public URLs (`curl` against `/api/.../system/status` etc. on
Radarr/Sonarr/Bazarr/Prowlarr/Lidarr/Profilarr/qBittorrent) — all correctly returned 401/403
without credentials. One inconsistency found: Sonarr's `authenticationRequired` was
`disabledForLocalAddresses` (the rest were `enabled`). In practice this wasn't currently
exploitable — Cloudflare-tunneled requests weren't being treated as "local" by Sonarr, 401
either way — but it was the one config that could silently break if network path, app version,
or proxy header handling ever changed. Fixed via `PUT /api/v3/config/host` (full round-trip:
GET the object, flip one field, PUT it back — the password field comes back pre-hashed and
must be sent back unchanged, same pattern the Sonarr web UI itself uses). Verified 401 now even
from `localhost` with no API key.
**Decision**: Added a Cloudflare Access application + policy (decision: allow, email OTP to
`matiasmassetti@gmail.com`, 168h session so it's not naggy) in front of 15 hostnames — every
admin/internal tool and personal project, but deliberately **not** `media.matiasmassetti.com`
(Jellyfin) or `pedidos.matiasmassetti.com` (Jellyseerr), since those two are used directly by
family/friends and an extra login screen there would be pure friction for people who aren't the
security audience for this change. Full list: Radarr, Sonarr, Bazarr, Prowlarr, Lidarr,
Profilarr, qBittorrent (`descargas`), SABnzbd (`usenet`), Cinemateca, CEN Dashboard (`cen-api`),
Ricota API (`ricota-api`), Image Server (`assets`), OpenCloud (`cloud`), Homepage (`home`),
Uptime Kuma (`status`). Created via the Cloudflare API (`POST .../access/apps` then
`POST .../access/apps/{id}/policies` per hostname) after Matias added `Access: Apps and
Policies: Edit` to the same scoped token used for the tunnel/DNS work. Verified after: all 15
redirect to `mmassetti.cloudflareaccess.com` when hit unauthenticated; `media`/`pedidos` still
redirect to their own app's native login (`/web/`, `/login`) as before, untouched.
**Rationale**: Every app already had its own login, so this isn't closing an open door — it's
adding a second, independent lock in front of the doors nobody but Matias should ever open, so
a leaked/weak/reused app password alone isn't enough to reach it from the internet. Scoping it
to "who actually needs frictionless access" (family/friends → Jellyfin/Jellyseerr only) instead
of applying it uniformly avoids the classic failure mode of security work driving people to
route around it out of annoyance.
**Follow-ups not done yet**: session length (168h) was picked as a reasonable default, not
discussed in depth — revisit if it turns out to be too naggy or too loose. Also still open: the
"OpenClaw revive or retire" and "ricota-db git status" items from the prior day's audit remain
unresolved (see `TODO.md`).

## 2026-08-11 — Cloudflare API token + tunnel cleanup, found NAS exposed to internet

**Context**: Follow-up to the stack audit earlier the same day. `home.matiasmassetti.com` was
confirmed already fixed (pointing at homepage's :3000, not Homarr's old :7575 — turned out
Matias had already fixed it manually before asking about it). Created a scoped Cloudflare API
token (`Account:Cloudflare Tunnel:Edit`, name "cloudflare tunnel minipc access") so tunnel
ingress can be managed via API instead of the dashboard going forward. Stored at
`~/.config/secrets/cloudflare_api_token` (0600), same convention as `gcal_oauth.json`.
**Decision**: Used the token to pull the tunnel's live ingress config (`GET .../cfd_tunnel/
{id}/configurations`) — ground truth, replacing all the "unverified" guesses in `CLAUDE.md`/
`network/network.md` with the real 18-route list. This turned up something nobody had
flagged: `nas.matiasmassetti.com` pointed straight at the Synology DSM login page
(`192.168.1.119:5000`), publicly reachable with no visible Cloudflare Access policy in front
of it. Matias confirmed he didn't know it was configured that way and asked to remove it.
Deleted the ingress rule via `PUT .../configurations` (full ingress array minus that one entry
— the endpoint replaces the whole list, no partial-delete). Verified `https://
nas.matiasmassetti.com` now 404s. Remote NAS access remains available via Tailscale subnet
routing (NAS shares the LAN with the mini PC, which already advertises `192.168.1.0/24`).
**Rationale**: An internet-facing NAS admin login with unknown auth posture (DSM version/2FA
status not checked) is a meaningfully worse risk than a broken dashboard link — worth fixing
immediately rather than just documenting it. Removing via API (not just noting it) was the
right call once explicit confirmation was given, since the fix is trivial to reverse if it
turns out to have been intentional after all (just re-add the ingress rule).
**Update same day**: Matias added `Zone:DNS:Edit` (scoped to `matiasmassetti.com`) to the token
via the dashboard. Used it to look up the zone (`184c571f...`), find the orphaned
`nas.matiasmassetti.com` CNAME record (`d9a9622c...`, → tunnel's `.cfargotunnel.com`, created
2026-02-08), and delete it. The hostname no longer resolves at all now, not even to a 404.
**Follow-ups not done yet**: still unaudited whether any of the *other* exposed subdomains
(Radarr, Sonarr, Bazarr, Prowlarr, Lidarr, Profilarr, etc.) sit behind a Cloudflare Access
policy — this token can't read Access config, so that needs a separate check (either a broader
token or the dashboard) before assuming they're adequately protected.

## 2026-08-11 — Full stack audit + Telegram notifications for ARR/Jellyfin/Jellyseerr

**Context**: Matias wanted notifications so he doesn't have to check Jellyseerr manually to see
new requests, and asked what else could be made "cool" across the stack. While implementing
that, a live audit (`docker ps`, `docker network ls`, reading the real compose files) turned up
significant drift between `~/homelab/CLAUDE.md`/`services.md` and what's actually running —
those docs hadn't been touched since 2026-02-14 despite real changes happening in the meantime.
**Decision**:
1. **Notifications** — created a dedicated Telegram bot (`@masa_server_bot`). Radarr and Sonarr
   got a Telegram connection via their REST APIs directly (`POST /api/v3/notification`, schema
   pulled first from `/api/v3/notification/schema` since Radarr/Sonarr event field names differ
   — `onMovie*` vs `onSeries*`/`onEpisode*`) firing on Grab/Download/Upgrade/Health events to
   the admin chat. Jellyfin got the official Webhook plugin installed via its Packages API
   (required one container restart — checked `GET /Sessions` first to confirm nobody was
   actively streaming), configured with a Generic destination pointed straight at Telegram's
   `sendMessage` endpoint, template rendering `{{NotificationUsername}}`/`{{Name}}` on
   `PlaybackStart`. Jellyseerr's built-in admin + per-user Telegram notifications were
   configured through its own UI (no API needed there).
2. **Stack audit findings** — Homarr was replaced by `homepage` at some point (different port:
   7575 → 3000) without a doc update; Nextcloud + its DB were fully removed; OpenClaw
   ("Claudito") was **completely torn down** — not paused, no containers at all in `docker ps
   -a`, network gone too — despite docs and memory describing it as an active daily service.
   Three new things existed with zero documentation: `sabnzbd` (Usenet client alongside
   qBittorrent), `cinemateca` (custom Letterboxd/Jellyfin/TMDB movie cataloger), and
   `ricota-db` (Postgres+PostgREST+Caddy, ironically living *inside* the homelab repo itself
   at `~/homelab/ricota-db/` but untracked in git).
3. **Docs updated to match reality**: `CLAUDE.md` and `services/services.md` were rewritten
   for accuracy — dead services removed/flagged, new ones added, the Cloudflare Tunnel table
   marked as unverifiable-from-disk (the tunnel is token-based with dashboard-managed ingress,
   no local `config.yml` to check against) with a flagged likely-broken entry for
   `home.matiasmassetti.com` (still documented as pointing at Homarr's old port).
**Rationale**: Docs that silently drift from reality are worse than no docs — they actively
mislead. Since this repo has been fully overhauled once already for accuracy, the same
"Keep Docs in Sync" discipline the repo already asks for (see `CLAUDE.md` checklist) needs to
actually get followed going forward, especially for teardown-type changes (removing a service
entirely is easy to forget to document, since there's no "add this to the compose file" moment
that would naturally prompt it).
**Follow-ups not done yet**: verify/fix the `home.matiasmassetti.com` Cloudflare Tunnel target;
decide whether to revive OpenClaw/Claudito or formally retire it in the docs; `git add` the
`ricota-db/` directory (or `.gitignore` it if it's meant to stay untracked) — right now it's
just sitting there unstaged.

## 2026-08 — Flag-based poster redesign for Cine del Mundo + Sol de Mayo for Cine Argentino

**Context**: The original gradient+text posters for the 7 Cine del Mundo country collections
and the 13 Cine Argentino (parent + 12 decades) collections worked but weren't instantly
recognizable — Matias wanted something that reads at a glance, like each country's flag.
**Decision**: Redesigned all 21 posters with ImageMagick, generated via ~/homelab-adjacent
scratch scripts (not checked into the repo, one-off): each Cine del Mundo country poster now
uses that country's actual flag as the background (vertical/horizontal bands drawn to scale —
France/Italy vertical tricolors, Germany horizontal tricolor, Spain's red-yellow-red, Japan's
Hinomaru red circle on white, a hand-approximated Union Jack for Reino Unido using stroked
diagonal + cross lines). Latinoamérica has no single flag (covers Brazil/Mexico/Uruguay/Chile),
so built a 4-panel mosaic — one simplified flag per country side by side with a small text
label under each, avoiding the earlier attempt's bug where using `+append` on separately-
rendered tile PNGs produced misaligned/bled colors (root cause never fully pinned down;
switched to drawing all 4 flags directly onto one canvas with absolute coordinates, which
fixed it). Cine del Mundo's parent poster stays neutral (a thin gold globe line-art on navy)
since it doesn't represent one country. Cine Argentino's parent + all 12 decade posters now
use the actual Argentine flag (light blue/white/light blue bands) with a hand-drawn Sol de
Mayo (16-ray sun, alternating straight/wavy — built as an SVG via a small Python script using
trig for ray angles, then rasterized) placed in the white stripe, with the decade (or "CINE
ARGENTINO" for the parent) as large text below it.
**Rationale**: Flags are a far stronger at-a-glance identifier than abstract gradients for a
"pick a country to browse" hub. Building precise flags directly in ImageMagick (rectangles/
lines/polygons) instead of sourcing real flag images keeps everything self-generated, avoids
any licensing/attribution question, and stayed consistent with the "no external images"
approach used for every other piece of collection art this session.

## 2026-08 — Library-wide duplicate sweep using TMDB provider IDs (~136GB freed)

**Context**: The 7-country manual review had already turned up 5 duplicate movies just by
spot-checking ~350 titles, suggesting more existed across the full ~2530-movie library.
Grouping by TMDB provider ID (`ProviderIds.Tmdb`, via `/Items?...Fields=ProviderIds`) instead
of fuzzy title matching found 23 groups sharing a TMDB ID — far more reliable than title/year
matching since it survives language and folder-naming differences.
**Decision**: Of the 23 groups, only 19 were genuine duplicate files; 4 were false positives
that must **not** be touched:
- ***La Flor* (2018, Mariano Llinás)** and **Trenque Lauquen (2022, Laura Citarella)** — both
  intentionally multi-part films (4 and 2 parts respectively), sharing one TMDB entry by
  design, not duplicated content.
- **"Civil War Life: Left for Dead"** — `dead set 2.mp4`/`dead set 3.mp4` look like episodes
  of the British zombie miniseries *Dead Set* mis-imported as movies and mis-matched to an
  unrelated TMDB documentary entry. Left alone, flagged for a future metadata-only fix.
- **"Happiness (1997)" vs "Happy Together (1997)"** — these are two **completely different
  films** (Todd Solondz's *Happiness* vs Wong Kar-wai's *Happy Together*) that got matched to
  the *same* TMDB ID by mistake — confirmed by the Criterion extras in the "Happiness" folder
  featuring a Solondz interview. A metadata bug, not a duplicate; neither file was touched.

For the 19 real duplicates, resolved each with the established pattern (ffprobe quality
compare, subtitle rescue when the loser had better/different subs, delete loser, refresh
library), verifying zero active sessions throughout:
- **3 stray copies of *Bring Her Back* (2025)** — one correctly filed, two others nested
  inside unrelated movie folders (*Black Glasses*, *Knock At The Cabin*) — same failure mode
  as the earlier `Trap (2024)` folder mixup, most likely a torrent client writing into
  whatever folder was previously open instead of creating its own.
- **Biggest single win**: *Once Upon a Time... in Hollywood* existed as both a clean 20GB
  1080p BluRay remux (kept) and a **90GB raw unpacked Blu-ray disc folder** (BDMV/CERTIFICATE/
  menus/etc.) — deleted the disc folder entirely.
- Other resolved pairs: Lady Vengeance/Sympathy for Lady Vengeance, El exilio de Gardel
  (2 copies), El gran simulador (2012 vs 2013), El otro hermano (2 files same folder), Falling
  Down/Un día de furia, Godfather Part 2 (mp4) vs Part II (mkv, AV1 — kept the AV1), Gone Baby
  Gone (nested 720p leftover), The Intern (nested inside an unrelated *True Confessions*
  folder), John Wick (nested duplicate inside its own folder), Kundun (two identical-spec
  copies), Las Acacias/Luminum/Picado fino/Sabes nadar (all had a second folder with a wrong
  year in the name), No abras nunca esa puerta (lower-res TDTRip vs a better copy), Wild
  Strawberries/Smultronstallet (near-identical quality, kept the one with clean Spanish subs),
  Misantropo/To Catch a Killer (identical encode under two release titles).
- **Total freed: ~136GB**, ~90GB of which was the single Blu-ray disc folder.
**Rationale**: TMDB ID grouping is a far stronger duplicate signal than filename/title
matching — it caught cross-language pairs (Wild Strawberries/Smultronstallet, El otro hermano)
that a naive text match would miss, while correctly *not* flagging intentionally multi-part
films or genuinely different movies that happened to share a bad metadata match. Worth
re-running this sweep periodically as new downloads land.

## 2026-08 — Curated the TMDb Box Sets native collections into the Sagas hub

**Context**: The pre-existing TMDb Box Sets plugin (auto-scan already disabled, see entry
below) had left 44 native franchise collections sitting at the top level, uncurated and
visually inconsistent with the hand-built collections. Audited all 44 by movie count and
image status before deciding what to do with each.
**Decision**: Deleted 10: 4 were empty (0 movies — stale entries from removed files:
*American Graffiti*, *Once Upon a Time... in Hollywood*, *Spider-Man: Spider-Verse*, *The
Vengeance Trilogy*), 3 had only 1 movie (no browsing value as a "collection": *It Follows*,
*Sinners*, *Waiting for the Hearse*), and 3 duplicated the hand-curated Sagas hub (native
*Harry Potter/Mission: Impossible/Pirates of the Caribbean Collections* — kept our versions,
which already have custom art; note the native Harry Potter list was actually the cleaner one,
8 canon films with no reunion special, but Matias had already said to keep the reunion special
in ours). Of the remaining 34, 29 already had real TMDB poster art + descriptions (Die Hard,
The Godfather, James Bond, John Wick, Joker, Scream, Dune, Avatar, Indiana Jones, Paddington,
etc. — no extra work needed) and only 5 lacked images, all Argentine film series TMDB doesn't
carry art for (*Odio desencadenada* — Lucía Seles' avant-garde tennis-complex comedy franchise,
*Cándida*, *Catita y Goyena*, *Colección: El Auge del Humano*, *La pequeña señora de Pérez*) —
generated posters for those 5 in the established gradient style. Nested all 34 into the
**Sagas** hub (`POST /Collections/{sagasId}/Items`) and added their IDs to the JavaScript
Injector's hide-list (56 IDs total now, up from 22), so they only surface inside Sagas'
detail page, not the flat Collections grid. Sagas hub: 3 → 37 children. Total BoxSet count:
79 → 69 after the 10 deletions.
**Rationale**: No point hand-curating art for 29 that already look good — checking image
status first saved a lot of redundant work. Consolidating everything franchise-shaped under
one Sagas hub (rather than leaving native ones as loose top-level tiles) keeps the "flat
Collections view only shows curated hubs" promise from the JS Injector work intact.

## 2026-08 — Installed JavaScript Injector + Jellyfin Enhanced plugins; restart done, subcollections hidden

**Context**: Last piece of the Jellyfin UI polish effort — hiding the ~22 nested subcollection
tiles (Cine Argentino decades, Sagas franchises, Cine del Mundo countries) from the flat
top-level Collections grid, which required a Jellyfin container restart (deferred until no one
was watching, per the standing safety rule). Verified 0 active sessions via `/Sessions` and no
running transcodes before restarting.
**Decision**: The originally-planned `jellyfin-plugin-custom-javascript` (johnpc) is
unmaintained; used the actively-maintained fork instead — **JavaScript Injector** by n00bcodr
(repo `https://raw.githubusercontent.com/n00bcodr/jellyfin-plugins/main/10.11/manifest.json`,
targets our exact Jellyfin 10.11 ABI). Also installed **Jellyfin Enhanced** from the same repo
(shortcuts, ratings, hidden-content management, Jellyseerr integration) at Matias's request.
Skipped the locally-cataloged **Skin Manager** plugin — last released Nov 2024 targeting ABI
10.7.0.0, judged too stale/risky against a live 10.11 server; the Custom CSS branding change
already covers the visual-polish goal.
**JS Injector script**: `CustomJavaScriptEntry` schema is `{Name, Script, Enabled,
RequiresAuthentication}`, set via `POST /Plugins/{pluginId}/Configuration`. First version keyed
"hide except on the flat Collections list" off `location.hash` containing `type=BoxSet` —
worked for Sagas/Cine del Mundo but **not** for the Cine Argentino decades (root cause
unconfirmed, possibly a route-detection edge case). Rewrote to the inverse, more robust logic:
hide all 22 target IDs everywhere **except** when `location.hash` contains `/details` for one
of the 3 parent hub IDs (Cine Argentino, Sagas, Cine del Mundo) — a whitelist model instead of
a blacklist-on-one-route model. Added a 1.5s `setInterval` fallback alongside the
`MutationObserver` in case of missed DOM mutations. Confirmed working by Matias after a
browser refresh.
**Side discovery**: the pre-existing **TMDb Box Sets** plugin (not installed by us) runs a
`TMDbBoxSetsRefreshLibraryTask` every 24h that auto-creates un-curated native collections
(no custom art/description) for any TMDB franchise with 2+ movies in the library — found ~28
of these (Avatar, Die Hard, Dune, Indiana Jones, James Bond, John Wick, Joker, Paddington,
Scream, Spider-Man, Terminator, X, etc.), 3 of which duplicate our curated Sagas hub (Harry
Potter, Mission: Impossible, Pirates of the Caribbean Collections). Matias chose to just stop
future auto-generation — cleared the task's `Triggers` via `POST /ScheduledTasks/{id}/Triggers`
with an empty array — without deleting the existing native collections or the 3 duplicates.
**Rationale**: Bundling both plugin installs into the single restart avoided a second
restart/interruption window later. The whitelist-based hide script is more robust than the
original route-based blacklist and easier to reason about (parent detail pages are a small,
fixed set; every other route should hide). Left the TMDb Box Sets duplicates alone since
Matias didn't ask for cleanup — worth revisiting if the visual clutter becomes annoying.

## 2026-08 — Latinoamérica collection review: closes out the Cine del Mundo manual pass

**Context**: Last of the 7 Cine del Mundo country reviews. "Latinoamérica" (Brazil/Mexico/
Uruguay/Chile ex-Argentina, 22 titles) had the same two failure modes seen throughout: Uruguay
listed as the primary co-production country for what are culturally Argentine films (mirrors
the España/Latinoamérica overlap from the original country-fix pass), and American
director-driven films with Brazilian financing (RT Features shows up as a producer on several
of these, the same way German tax-shelter and EMI Films financing did for Alemania/Reino
Unido).
**Decision**: Removed 7 titles, down to 15. Argentine misattributions: *Gilda: no me
arrepiento de este amor* (Lorena Muñoz, Argentine director — Uruguay was just a co-production
credit), *Mi amiga del parque* (Ana Katz, Argentine director), *Compañero Fernando*
(documentary by Argentine exiles, directed by an Argentine, shot in Mexico). American
misattributions: *Frances Ha* (Noah Baumbach, NYC), *Silence* (Scorsese), *Armageddon Time*
(James Gray, NYC autobiographical), and *Dreams* (2026, Matias called this one American too).
Kept *Blindness* (2008) despite its heavily international cast/crew and English dialogue,
since Fernando Meirelles (Brazilian) directed it — same "director's cultural identity" tie-
breaker used for *PERFECT DAYS*, *Prisoners of the Ghostland*, etc. in earlier country reviews.
**Status**: This closes the manual review of all 7 Cine del Mundo subcollections (España,
Alemania, Italia, Francia, Reino Unido, Japón, Latinoamérica). Final counts: 37 / 17 / 18 / 56
/ 79 / 34 / 15 = 256 movies, down from 761 after the original "primary country" fix, and far
more curated than the original "any co-production country" version (which had over 900 combined
across just España+Latinoamérica alone due to Argentine co-production overlap). Along the way,
found and fixed 5 duplicate movie files across the library (Wild Tales, Indagine su un
cittadino, Holy Motors, La Nuit américaine, plus the 7-way Trap(2024) folder mixup which
included one broken/incomplete download) and one full deletion (*Battleship*, at Matias's
request).

## 2026-08 — Japón collection review: two false alarms, one real duplicate

**Context**: Continuing the manual per-country pass. "Japón" (37 titles) looked cleaner than
the previous countries but had two titles with garbled/wrong-looking names worth checking
before assuming they were misattributions like the UK/Alemania cases.
**Decision**: Investigated both before touching anything — **not** removed: `8½` turned out to
be a different, genuinely Japanese genre film (about an agent named Jiro Kitami stopping arms
smuggling to the Vietcong) that just happens to share its title with Fellini's `8½`; `Плем'я`
(Cyrillic, "The Tribe") turned out to be Sion Sono's *Tokyo Tribe* mismatched with the TMDB
entry for an unrelated Ukrainian film that also translates to "The Tribe" in English — the
actual content is genuinely Japanese, only the title metadata is wrong (same class of issue as
the 3 mislabeled British titles found in the Reino Unido pass; not fixed, just noted). Removed
2 genuine misattributions: *Battleship* (American blockbuster) and *No Direction Home: Bob
Dylan* (Scorsese documentary) — both list Japan only for minor international financing/
distribution credit. Matias asked to delete *Battleship* from the library entirely rather than
just the collection — not Radarr-managed, so a plain filesystem delete + `RefreshLibrary` was
enough, freed 6.4GB. Kept *Ghost in the Shell: Stand Alone Complex* (genuine anime) and
*Prisoners of the Ghostland* (Sion Sono directed, despite Nicolas Cage/English dialogue —
same "director's cultural identity wins" logic as *PERFECT DAYS* in Alemania). Down to 34.
**Duplicate found**: *Tokyo Story* (1953, Ozu) existed as two separate Jellyfin items — a
720p BRRip and a 1080p BluRay — because they lived in different subfolders and got scanned
as distinct titles (one under the English title, one under the Japanese 東京物語). Both had
Spanish subtitles already. Deleted the 720p copy, ran `RefreshLibrary`.
**Rationale**: This pass reinforces checking the actual `Overview`/content before assuming an
odd-looking title is a metadata mismatch worth removing — two titles that looked exactly like
prior countries' misattribution pattern turned out to be correct on inspection. Latinoamérica
is the last country left to review.

## 2026-08 — Reino Unido collection review; "Trap (2024)" folder had 7 stray duplicate movies, one broken download recovered

**Context**: Continuing the manual per-country pass. "Reino Unido" (120 titles) had the same
financing-credit pattern as Alemania, but from **EMI Films** and other British studios that
bankrolled 1970s-80s Hollywood productions (*Close Encounters*, *The Deer Hunter*, *The Driver*,
etc.) — British money, American films. Also found 3 titles under garbled non-English names
(Persian, German, Italian scripts) that turned out to be real British films with mislabeled
titles: `I due Kennedy` is actually Ken Loach's *Kes*, `فیل در تاریکی` is Alan Clarke's
*Elephant* (about the Troubles), `Schau mir in die Augen, Kleiner` is a British prison drama —
kept all three since the content is genuinely British, title metadata issue is separate/unfixed.
**Decision**: Removed 37 titles (EMI/financing-only American films, plus *Paris, Texas*
(Wenders, German) and *Born and Bred* (Argentine)), down to 83 before dedup, **79 after**.
Matias made the call on the two genuine toss-ups himself: *Closer* and *Interstellar* both
out (culturally American despite British-adjacent connections — Mike Nichols/American cast for
Closer, Nolan's dual nationality doesn't make a NASA story British for Interstellar). Kept
several films where the director's British identity or the story's British cultural core
outweighs a non-British co-financier: Kubrick's whole catalog, all of Hitchcock's British
period (1927-1972), Powell & Pressburger, David Lean, *Blow-Up* (Antonioni's "English film",
a long-established genre-history classification), *Brazil* (Gilliam), *An American Werewolf in
London*, Guy Ritchie's *The Covenant*, *Highlander* (Scottish mythology core), *Hamnet*
(British literary source).
**Duplicates found — much bigger than previous countries**: A folder named `Trap (2024)`
(M. Night Shyamalan's film) turned out to also contain 7 fully separate Hitchcock movies
nested as subfolders — *To Catch a Thief*, *Topaz*, *Torn Curtain*, *Under Capricorn*,
*Vertigo*, *Waltzes from Vienna*, *Young and Innocent* — apparently bundled together in
whatever download brought in `Trap (2024)`. All 7 duplicated a properly-organized top-level
copy elsewhere in `/Peliculas`, **except** `To Catch a Thief`, where the top-level copy turned
out to be a broken, incomplete download (a 40MB `.filepart`, not even a valid video file) —
the real 2.3GB file was only the one buried inside `Trap (2024)`. Recovered it by deleting the
broken top-level folder and moving the good nested copy up to `/Peliculas/To Catch A Thief
(1955)/`. Deleted the other 6 redundant nested copies (byte-identical to their top-level
counterparts) and left `Trap (2024).mkv` itself untouched. Also found and fixed a genuine
quality duplicate: *Barry Lyndon* existed as a 2160p HDR10 Dolby Vision remux (with embedded
Spanish subs already) and a lower-quality 1080p x264 rip — kept the UHD copy, deleted the
1080p one and its external subs (redundant, remux already has embedded Spanish SubRip tracks).
Ran `RefreshLibrary` after all filesystem changes; verified zero active sessions throughout
and confirmed no duplicate names remain in the collection afterward.
**Rationale**: same "financing credit ≠ creative origin" pattern as prior countries, but this
pass also turned up real filesystem hygiene issues (misfiled duplicates, a broken download)
that had nothing to do with country attribution — worth checking for on every remaining
country review, not just metadata. Japón and Latinoamérica still pending.

## 2026-08 — Francia collection review; fourth duplicate found

**Context**: Continuing the manual per-country pass. "Francia" (97 titles) mixed every failure
mode seen so far: Italian auteurs (Fellini, Antonioni, Bertolucci, Sorrentino, Argento) whose
films list France as a co-production/financing country, German titles (Schlöndorff, Petzold),
British titles (Greenaway, Wright, Cornish, Paddington films), a long tail of American
studio/indie films with French financing (Cameron, Scorsese, Lynch, the Coens, Clooney,
Safdie brothers, Schnabel), Spanish (Almodóvar, Sorogoyen, García Ibarra) and Argentine
(Solanas, Mitre) co-productions, one Mexican film (Amat Escalante's *Heli*), and one Polish
film (*Corpus Christi*).
**Decision**: Removed 40 titles, down to 56. Kept several genuine judgment calls in Francia
despite a non-French director, on a "does the film's language/setting/cultural identity read
as French regardless of the director's passport" basis (consistent with keeping Wenders'
*PERFECT DAYS* in Alemania and Argento/Corbucci's westerns in Italia): *Sunset Boulevards*
(Cozarinsky, Argentine-born but Paris-based, French subject matter), *Missing Persons Section*
(1956, no director data, no strong signal either way), *Nouvelle Vague* (2025, Linklater is
American but the film is in French, shot in Paris, about the making of *Breathless*). Removed
on the same consistency basis: *Vérités et Mensonges* (Welles — same call as *Chimes at
Midnight* in España), *Green Card* (Peter Weir, English-language, NYC-set), *The Dreamers*
(Bertolucci — an Italian auteur's film, like *The Last Emperor* which stayed in Italia).
**Fourth duplicate found**: *La Nuit américaine* (1973, Truffaut) existed as two entries — a
704x432 AVI (`Natteffekt.avi`, Scandinavian release naming) and a proper 1792x1072 MP4. Both
already had Spanish subtitles, so no subtitle rescue needed this time (unlike the previous
three dedup cases). Deleted the low-quality folder, ran `RefreshLibrary`, confirmed single
surviving entry.
**Rationale**: same as prior country reviews — `ProductionLocations` reflects financing/
distribution credit, not creative or cultural origin. Reino Unido, Japón and Latinoamérica
still need the same manual pass.

## 2026-08 — Alemania collection: German tax-financing credits ≠ German cinema; third duplicate found

**Context**: Continuing the manual per-country review. "Alemania" (44 titles) turned out to be
the most polluted collection so far, with a different failure mode than España/Italia: a
large share were American blockbusters that list Germany as a `ProductionLocations` entry
purely because of German tax-shelter co-production financing (a very common industry practice
in the 1990s-2000s), not any actual German creative involvement.
**Decision**: Removed 27 titles, down to 17. Three groups: (1) American films with German
financing credit only — *Smoke*, *8MM*, *Fight Club*, *The Score*, *Confessions of a
Dangerous Mind*, *The Life of David Gale*, *The Aviator*, *Inglourious Basterds*, *She's
Funny That Way*, *The Hunger Games: The Ballad of Songbirds & Snakes*; (2) Argentine
co-productions (same overlap pattern as España/Latinoamérica) — *Rolling Family*, *Reimon*,
*The Third Side of the River*, *The Owners*, *Two Shots Fired*, *El Cinco*, *Noh*,
*The Practice*, *Cuarentena (Exil und Rückkehr)*, *Juan: Como si nada hubiera sucedido*,
*Without This World*; (3) other misattributed nationalities — *Backbeat* (British, Beatles
biopic), *Låt den rätte komma in* (Swedish), *Wadjda* (Saudi, first Saudi film, Germany
co-produced for technical/funding reasons), *Holy Motors* (French, Leos Carax — also existed
as a duplicate, see below), *The Pleasure Garden* (Hitchcock's directorial debut, usually
classified as British/early Hitchcock despite the German studio). Kept genuinely German
auteur/production titles even when co-produced abroad (*PERFECT DAYS* — Wenders, shot in
Japan; *Victoria* — Berlin one-take thriller despite listing the US as a co-country).
**Third duplicate found**: *Holy Motors (2012)* existed twice — a 720x384 XviD rip in a
subfolder and a proper 1080p h264 remux at the top level. Deleted the low-quality subfolder,
ran `RefreshLibrary`, confirmed a single 1080p entry survives. No Radarr involvement needed
(same as the Investigation/Indagine duplicate — most of this library predates Radarr).
**Rationale**: same as the España/Italia review — `ProductionLocations` reflects financing/
distribution credits, not cultural or creative origin, and country-level co-production
financing schemes (especially German tax shelters) are common enough in this library to
warrant catching by hand rather than trusting the field alone. Alemania was the worst offender
by far; Francia, Japón, Reino Unido, Latinoamérica still pending the same review.

## 2026-08 — Manual per-country review of Cine del Mundo collections; second duplicate found

**Context**: The "primary country" fix (see below) got the numbers right but not necessarily
the curation — a film can legitimately have a country as its first `ProductionLocations`
entry and still not belong in a national-cinema showcase (e.g. auteur-driven co-productions
where the money/distribution credit doesn't match cultural identity). Went through Cine del
Mundo country by country manually with Matias.
**Decision**: **España** (41→37): removed *Giù la testa* (Sergio Leone spaghetti western —
Italian, not Spanish), *Chimes at Midnight* (Orson Welles, American/international arthouse),
*Vicky Cristina Barcelona* (Woody Allen, American), *The Ninth Gate* (Polanski, considered
American by Matias). **Italia** (24→18): removed *Don't Look Now* (Nicolas Roeg, British),
*Dawn of the Dead* (Romero, American — Argento only did the European cut), *King of New York*
(Ferrara, American), *Fahrenheit 9/11* (Michael Moore, American), *The Merchant of Venice*
(Radford, British Shakespeare adaptation). Kept genuine Italian-director spaghetti westerns
(*Il grande silenzio*, *C'era una volta il West*) since those correctly belong to Italian
cinema despite the "western" trope, unlike the Spain cases. Left *Ностальгия* (Tarkovsky) in
Italia as a judgment call — Soviet auteur, Italian production, ambiguous either way.
**Second duplicate found**: while reviewing Italia, found *Indagine su un cittadino al di
sopra di ogni sospetto* (1970) existed as two separate library entries — a 598MB 720x384 rip
(Spanish-titled folder, had a Spanish `.srt`) and a proper 1080p 2GB BluRay remux
(English-titled folder, no subs). Same resolution as the earlier Wild Tales duplicate: moved
the `.srt` into the HD copy's folder (renamed to match), deleted the low-quality file and its
now-empty folder, ran a full library scan (`RefreshLibrary` task) to reconcile. Verified zero
active playback sessions before touching any files. Neither copy was Radarr-managed (Radarr
only tracks 63 of the ~2543 movies in this library — most predate Radarr or were bulk-imported
outside it), so no Radarr-side rescan was needed, unlike the Wild Tales case.
**Rationale**: `ProductionLocations` order is a strong but imperfect proxy for "cinema of
country X" — it reflects production/financing credits, not always cultural identity. Worth a
manual pass per country given how much curation intent depends on judgment calls an automated
rule can't make. Remaining countries (Alemania, Francia, Japón, Reino Unido, Latinoamérica)
still need the same manual review.

## 2026-08 — Display original Spanish titles instead of English for Spanish-language films

**Context**: Many Spanish-language films (mostly Argentine/Spanish arthouse co-productions)
were showing their English TMDB title instead of their real original title — e.g. "Every
Stewardess Goes to Heaven" instead of "Todas las azafatas van al cielo". Jellyfin already had
the correct title in `OriginalTitle`, just wasn't using it as the display `Name`.
**Decision**: For all movies whose primary (first-listed) `ProductionLocations` country is
Argentina, Spain, Mexico, Uruguay, or Chile, and where `Name != OriginalTitle`: set
`Name = OriginalTitle` via `POST /Items/{id}` (fetch full item via
`/Users/{userId}/Items/{id}` first, mutate, POST back — same pattern as the collection
Overview edits) and lock the field (`LockedFields: ["Name"]`) so it survives future metadata
refreshes. 441 movies updated; excluded 2 (`Mermaid on board` / `The end of the world`) whose
"original" title was actually Norwegian, not Spanish, despite Argentina being a co-production
country — country-of-production is not the same as original language, verified those two by
inspection since neither an audio-track-language check nor a lexical Spanish-word heuristic
were reliable enough to fully automate the distinction (both produced too many false
negatives on legitimately-Spanish titles).
**Bug found along the way**: items that already have Trickplay data generated (see the
trickplay/chapter-image background task entry below) fail this same `POST /Items/{id}`
round-trip with a 500 — Jellyfin's own `TrickplayInfoDto` can't be deserialized back from what
its own GET response produces. Fix: `.pop("Trickplay", None)` from the item dict before
POSTing. Relevant for any future bulk metadata edits done this way while trickplay generation
is still running/expanding.
**Rationale**: Purely a display fix via the metadata editor endpoint — no filesystem changes,
no restart. Country of primary production is a good proxy for original language in this
library except for the rare non-Spanish-speaking co-production (Nordic countries showed up
here); manually reviewing the ~55 candidates that had a plausibly-non-Spanish co-producer
country was cheap and caught both real exceptions.

## 2026-08 — Fix "Cine del Mundo" country collections: use primary country, not "any co-production country"

**Context**: Matias noticed movies that clearly didn't belong — e.g. the Argentine film "Un
oso rojo" showing up in "España", and the Italian/Spanish/German/US co-production "Il buono,
il brutto, il cattivo" also showing in "España". Root cause: the original filter treated a
movie as belonging to a country if that country appeared *anywhere* in TMDB's
`ProductionLocations` list, so any multi-country co-production got bucketed into every
country involved. This library is unusually rich in Argentina-Spain/France/Germany arthouse
co-productions (Ibermedia, ARTE France, Hubert Bals Fund all show up as studios), so the
distortion was large: 63% of "España" and 77% of "Latinoamérica" were actually Argentine
co-productions, not representative Spanish/Latin American cinema.
**Decision**: Rebuilt all 7 Cine del Mundo subcollections using "country is the *first* entry
in `ProductionLocations`" as the membership rule instead of "country appears anywhere in the
list". New sizes: España 133→41, Latinoamérica 97→22, Francia 226→97, Alemania 108→44, Italia
76→24, Japón 49→37, Reino Unido 197→120.
**Alternatives considered**: Excluding only Argentina-overlap movies (simpler, smaller fix,
but leaves other multi-country dilution like the Leone western); using `OriginalLanguage`
instead (rejected — doesn't disambiguate Spain vs. Argentina vs. Mexico, all Spanish-language).
**Rationale**: TMDB lists `production_countries` in an order that reliably reflects the
primary/home country in the vast majority of cases; "first entry" is a much stronger signal
of a film's actual national cinema than "this country was involved at all". Done entirely via
`POST`/`DELETE /Collections/{id}/Items`, no restart. Also found and fixed a bug in the diff
script: `GET /Items?ParentId=X` without a user context returns 0 items on this Jellyfin
version, which silently no-op'd the removal step on the first pass — must use
`GET /Users/{userId}/Items?ParentId=X`.

## 2026-08 — Jellyfin UI polish: custom CSS + curated collections via API

**Context**: Wanted Jellyfin to feel more "pro" (Netflix-style browsing) and better organized
than the default auto-generated library view, without ever risking an interruption to active
playback (a friend is often watching remotely) — so nothing that requires a container restart
was acceptable during active sessions.
**Decision**: Split the work into a restart-free track and a restart-required track.
Restart-free (done): (1) Custom CSS pushed live via `POST /System/Configuration/branding`
(Dashboard → Branding also works, same effect) — card hover/elevation, blurred header, celeste
accent. (2) Built 25 curated collections (Cine Argentino × 12 decades, Sagas × 3 franchises,
Cine del Mundo × 7 countries, plus 10 standalone thematic collections) entirely through the
Jellyfin REST API (`/Collections`, `/Items?...`, `/Items/{id}/Images/Primary`), including
custom poster art generated locally with ImageMagick (gradients + text, no external image
sources needed, avoids any copyright/licensing concern). Verified via `GET /Sessions` before
and after every write that no playback was interrupted. Restart-required (deferred): installing
`jellyfin-plugin-custom-javascript` to hide nested subcollections from the flat top-level
Collections view, and any Skin Manager theme — both parked until `/Sessions` shows no active
streams.
**Alternatives considered**: Doing everything at once including plugin installs (rejected —
plugin installs need a Jellyfin restart, which kills in-progress transcodes/streams). Manually
uploading poster art from the internet (rejected — avoids scraping/copyright issues, and
generated art is easy to keep visually consistent across ~25 collections).
**Rationale**: Nearly all meaningful customization (branding CSS, collections, artwork) is
achievable purely through Jellyfin's REST API and is safe to do live. Only plugin installation
requires downtime, so that work is cleanly isolated and gated on an explicit safety check
rather than mixed in with everything else.

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

## 2026-08-13 — Pi-hole/Unbound health check + tuning

**Context**: Routine audit found 3 things worth fixing: Pi-hole was 1-2 minor versions behind (Core v6.3→6.4.3, Web v6.4→6.6, FTL v6.4.1→6.7); recurring `Connection error ... TCP connection failed` bursts from Pi-hole to Unbound in FTL logs (05-jul, 21-jul, 31-jul, 13-aug), correlated with host load briefly exceeding core count (12.7-16.4 load avg on 16 threads); no conditional forwarding configured, so Top Clients only ever showed bare IPs.
**Decision**: `docker compose pull pihole && up -d pihole` to update; raised Unbound `num-threads` 1→4 (and matching cache slabs 2→4) in `/opt/docker/configs/unbound/unbound.conf`; set `dns.revServers = ["true,192.168.1.0/24,192.168.1.1"]` via `pihole-FTL --config` so Pi-hole forwards local PTR/hostname lookups to the router (192.168.1.1).
**Rationale**: Single-threaded Unbound was a plausible bottleneck for the intermittent TCP errors given the host's periodic load spikes — cheap to fix, no downside on a 16-thread host. Conditional forwarding is the standard fix for IP-only client names. Verified post-change: both containers healthy, DNS resolution and ad-blocking still working (`doubleclick.net` → `0.0.0.0`), `dns.revServers` persisted.

## 2026-08-13 — Identified and applied TMDB ids for 31 of the 120 unmatched movies

**Context**: Following up on the 2026-08-12 backfill's leftover "105 with no TMDB id" bucket
(120 in practice by now — the library grew since the original audit). Built a script that runs
each title through Jellyfin's own TMDB-backed `RemoteSearch` (with year, falling back to a
year-less search), scored candidates by title similarity (difflib) + year proximity, and
sorted into HIGH (title ~exact, year within 1), MEDIUM (exact title, year off by more), LOW
(weak title match), and NONE (nothing usable). Result: 25 HIGH, 13 MEDIUM, 11 LOW, 71 NONE.
Spot-checking NONE turned up two more useful findings: 6 titles failed only because of the
search string (audio-track suffix, romanized Japanese title, French title, director's name
baked into the title) — retried with cleaned titles and got confident matches (e.g. "El gran
dictador (Español)" → *The Great Dictator* tmdb:914, "Schichinin no samurai" → *Seven Samurai*
tmdb:346); and 11 more weren't real standalone movies at all — TV episodes ("dead set 1/4/5",
from the miniseries *Dead Set*), bonus interviews/making-of/restoration featurettes, and a
2-disc rip's two halves each indexed as their own "movie" (`cast1.part1`/`cast2.part1` inside
*Castaway on the Moon (2009)*'s own folder) — these need a Jellyfin library reorg, not a TMDB
match, and were pulled out of the confidence buckets so they don't get miscounted.
Published all of this as a review artifact (grouped by tier, TMDB links for one-click
verification) rather than auto-applying blind, given the 2026-08-12 session's own "Winx Club"
misidentification lesson — Matias reviewed and approved the 25 HIGH + 6 manually-found (31
total) for batch application.
**Decision**: Applied via `POST /Items/RemoteSearch/Apply/{itemId}` (same endpoint used for the
"The Club" metadata fix), one call per movie, `ReplaceAllImages=false`. Canaried on one title
first ("Carroceros") and verified via `GET /Items?Ids=...` that Jellyfin correctly wrote
`ProviderIds.Tmdb` and pulled fresh Overview/CommunityRating/artwork before running the rest.
Ran into `ReadTimeout`s on a few calls (Jellyfin apparently blocks on synchronous image
downloads for some titles) — confirmed via a follow-up GET that the timed-out calls had in fact
applied successfully server-side despite the client timeout, then re-ran the remainder with a
longer timeout. Final verification: bulk `GET /Items?Ids=<all 31>` showed all 31 with
`ProviderIds.Tmdb` set, zero missing.
**Rationale**: Not linked to Radarr yet — that's the next step, same pattern as the existing 8-
and 2210-title backfills (lookup by TMDB id, `monitored:false`+`searchForMovie:false`, rescan
to link the existing file, verify `hasFile:true` before flipping `monitored:true`). Left the
89 remaining titles (13 MEDIUM, 9 LOW, 11 non-movie, 56 NONE) untouched — see `TODO.md`.

## 2026-08-13 (later) — Linked the 31 newly-identified movies into Radarr

**Context**: Follow-up to the same day's TMDB-id backfill — the 31 movies (25 high-confidence +
6 manually-found) had a TMDB id in Jellyfin but weren't tracked by Radarr yet, same gap the
2210-title 2026-08-12 backfill closed for the rest of the library.
**Decision**: Same pattern as before — `GET /api/v3/movie/lookup/tmdb` for the full metadata
template, `POST /api/v3/movie` with `qualityProfileId:17` (2160p Efficient, matches 2284/2361
of the existing library), `monitored:false`, `addOptions:{monitor:"none",searchForMovie:false}`,
`path` set to the existing NAS folder translated from Jellyfin's `/data/movies/...` mount to
Radarr's `/movies/...` mount. Canaried on one title ("Carroceros") first, verified
`hasFile:true` after a `RescanMovie` command and confirmed zero grabs/queue activity before
batching the remaining 30. One of the 31 ("El gran dictador (Subtitulada)") was correctly
rejected by Radarr with "Path already configured for an existing movie" — it's a second
audio-track file sitting in the *same* folder as "El gran dictador (Español)", so it's the same
Radarr movie, not a separate one; both Jellyfin entries already carry the right TMDB id, only
one needed a Radarr entry. The other 29 rescans showed `hasFile:false` transiently (async
processing, matching the "51 of 60 were exactly this false-negative timing issue" note from the
2026-08-12 backfill) — polled every 10s and all 30 (29 + the canary) settled on `hasFile:true`
within the first poll. Verified zero entries in Radarr's queue and zero `grabbed` events across
all 30 movie histories before flipping every one to `monitored:true`. Final check: Radarr's
total movie count went from 2361 → 2391, all 30 new entries `monitored:true` + `hasFile:true`.
**Rationale**: Bazarr's existing Radarr sync will pick these up automatically for subtitle
management on its next cycle — no manual trigger needed, same as the earlier 8-title backfill.

## 2026-08-14 — Triaged the 58 nested/multi-file movie folders, linked 22 to Radarr, found 2 real bugs

**Context**: The "58 movies in nested/multi-file folders" bucket set aside during the
2026-08-12 backfill (safety filter: skip any movie whose file isn't directly one level under
its own folder) had never actually been enumerated anywhere. Reconstructed it by re-running
the same rule against the live Jellyfin library: any movie item that's either (a) more than one
path segment below `/data/movies/`, or (b) sharing its top-level folder with another movie
item. Got exactly 58, matching the original count.
**Decision — safe backfill**: 26 of the 58 turned out to be correctly identified single files,
just sitting one extra folder level deep (release-group subfolder) or coexisting harmlessly in
a shared folder. Checked each for Radarr overlap before touching anything: 2 (`La libertad`,
`Prisoners of the Land`) were already linked from the same week's TMDB-id backfill, 1 (`Curse
of the Black Pearl`) was already correctly linked from the original 2026-08-12 backfill. Of the
remaining 23, canaried on `Klute`, verified `hasFile:true` and zero queue/grab activity, then
batched the other 22 via the same `lookup → add(monitored:false) → RescanMovie` pattern used
all week — this time using the *top-level* folder as Radarr's `path` (not the deeper release-
group subfolder) since Radarr's rescan recurses into subfolders on its own. 21 of 22 resolved
`hasFile:true` within ~50s of polling and got flipped to `monitored:true`. Total Radarr count:
2391 → 2413.
**Finding — `The Man from Earth (2007)` has no audio track.** The 22nd file never resolved
`hasFile:true`; Radarr's manual-import scan showed a permanent rejection, "No audio tracks
detected". Cross-checked independently via Jellyfin's own `PlaybackInfo` stream probe — confirmed
the file genuinely has only a video stream and two Spanish subtitle tracks, no audio at all.
Left this one `monitored:false` in Radarr (relinking metadata can't fix a broken file) rather
than silently forcing it — it needs an actual re-download to get a version with sound.
**Finding — real cross-tagging bug: "Happy Together" ↔ "Happiness".** While checking Radarr
overlap, found the existing Radarr entry for tmdb:18329 ("Happy Together") points at
`/movies/Happiness (1997)/Happiness.1997.Criterion...mkv` — Todd Solondz's *Happiness*, a
completely different film. Root cause is in Jellyfin, not Radarr: that Jellyfin item is
literally named "春光乍洩" (Happy Together's original Chinese title) with `ProviderIds.Tmdb:
18329`, i.e. the *Happiness* file was mistagged with *Happy Together*'s TMDB id at some point
before this week's work, and the 2026-08-12 Radarr backfill (which trusted Jellyfin's TMDB id
as ground truth) faithfully inherited the error. The real, correctly-tagged *Happy Together*
file sits untouched in its own separate, correctly-named folder — never linked to Radarr.
Excluded both from this batch rather than creating a second Radarr entry for the same tmdbId
(which Radarr would have rejected anyway) or silently leaving the mislink in place. Not fixed
yet — needs looking up *Happiness*'s real TMDB id, retagging the Jellyfin item, correcting the
Radarr entry (id 432), and only then adding the real Happy Together file. Left for a dedicated
pass rather than folding into this backfill, since it touches an existing library entry rather
than just adding a new one.
**Decision — everything else left for manual review**: 3 real misplaced-file bugs (need a `mv`
on the NAS: *A Cure For Wellness* inside "25th Hour"'s folder, *Jeff, Who Lives at Home* inside
"Klute"'s folder, *Pirates: Dead Man's Chest* inside "Curse of the Black Pearl"'s folder — in
all three cases the "host" folder's own movie, where it has one, is unaffected and already
correctly linked); 4 more wrong-TMDB-tag cases including — most notably — *Los Muertos (2004)*'s
actual main film file being mistagged as a "making of" title, meaning the real film has no
correct entry in the library at all; 1 ambiguous Kurosawa documentary; the 8-file *La Flor
(2018)* cluster (each fragment individually mismatched to an unrelated title by Jellyfin's
scraper — real tmdb id is 423778, found via manual search; recommended fix is Jellyfin's Merge
Versions feature rather than 8 separate movie entries); and 6 harmless duplicate-copy cases
needing no action. Full breakdown in `TODO.md`.
**Rationale**: The pattern established all week (verify before batch-applying, never auto-fix
an existing/live entry without flagging it) is what surfaced both bugs — a blind "trust
Jellyfin's tmdb id" batch would have either silently duplicated or silently perpetuated the
Happy Together/Happiness swap.

## 2026-08-14 (later) — Fixed the Happy Together / Happiness cross-tagging bug

**Context**: Follow-up to the same day's nested-folder triage, which found the Jellyfin item at
`Happiness (1997)/Happiness.1997.Criterion...mkv` (Todd Solondz's *Happiness*) was tagged with
tmdb:18329, actually *Happy Together* (Wong Kar-wai)'s id — and Radarr's "Happy Together" entry
(id 432) had inherited the error, pointing at the wrong file.
**Decision**: Looked up *Happiness*'s real tmdb id two independent ways — Radarr's term lookup
("Happiness 1998") and cross-checking against the IMDb id the Jellyfin item already had stored
(`tt0147612`, correct for *Happiness*, untouched by whatever process broke the Tmdb field) —
both converged on **tmdb:10683**. Fixed Jellyfin via `RemoteSearch/Apply` with
`ReplaceAllImages=true` (the poster/backdrop were also wrong, inherited from Happy Together);
Jellyfin's background refresh picked up the correct Overview/CriticRating/OfficialRating
automatically but left `Name`/`OriginalTitle` stuck on the old "春光乍洩" — a plain
`RemoteSearch/Apply` doesn't touch those fields, they needed a direct item-DTO edit (`GET
/Users/{userId}/Items/{id}` → edit `Name`/`OriginalTitle` → `POST /Items/{id}`) to actually
update.
On the Radarr side, confirmed `PUT /api/v3/movie/{id}` cannot change an existing movie's
`tmdbId` — it silently no-ops and keeps serving the old linked metadata (verified: response
still showed "Happy Together"/春光乍洩 after the attempt). Deleted movie 432 with
`deleteFiles:false` (verified the actual file survived on the NAS afterward), then added two
fresh entries: *Happiness* (tmdb:10683) at `/movies/Happiness (1997)` — the file that was
already there — and the real *Happy Together* (tmdb:18329) at `/movies/Happy Together (1997)`,
which had been sitting correctly tagged in Jellyfin all along but never linked to Radarr
(excluded from the same day's earlier batch specifically because of this conflict). Both
resolved `hasFile:true` on the first poll, zero queue/grab activity confirmed, both flipped to
`monitored:true`. Final check: 2414 total movies, zero duplicate `tmdbId`s.
**Rationale**: Same principle as the rest of the week — verify from an independent source
(IMDb id already on file, not just a fresh title search) before overwriting an existing tag,
and confirm the delete didn't touch the underlying file before moving on.

## 2026-08-14 (later still) — Fixed the 3 misplaced-file bugs from the nested-folder triage

**Context**: Group 2 of the 58-folder triage — 3 movies whose file sat inside a *different*
movie's top-level folder, rather than a genuine metadata problem.
**Decision**: `mv`'d each nested subfolder up to its own top-level folder on the NAS (checked
first that none of the three target folder names already existed, to rule out a collision):
`A Cure For Wellness (2016)` out of `25th Hour (2002)`'s folder; `Jeff, Who Lives at Home
(2011) [1080p]` out of `Klute (1971)`'s folder; `Pirates of the Caribbean Dead Man's Chest
(2006)` out of `Curse of the Black Pearl (2003)`'s folder. Verified after each move that the
"host" folder still had its own correct content intact (Klute and Curse of the Black Pearl both
still had their own file untouched; `25th Hour (2002)` was left with only a stray 124KB `.parts`
file — that folder never actually contained the real "25th Hour", so nothing of value was lost
by moving the misplaced file out).
Triggered Jellyfin's "Scan Media Library" task (the plain `/Library/Refresh` call alone wasn't
enough — the 3 items didn't reappear until the actual scan task, polled via
`/ScheduledTasks/{id}`, finished ~2 minutes later). All 3 came back re-identified with the same
correct TMDB/IMDb ids as before the move (new Jellyfin item ids, since Jellyfin treats a moved
file as a removed-then-readded item rather than an in-place path update — total library count
returned to the same 2519 afterward, confirming no orphans or duplicates). Added all 3 to
Radarr with the same verified pattern as the rest of the week (`monitored:false` → add → rescan
→ confirm `hasFile:true` and zero queue/grab activity → `monitored:true`). Radarr total: 2414 →
2417, zero duplicate tmdbIds.
**Rationale**: None of these needed a metadata fix, only a filesystem move — the TMDB
identification was already correct in all three cases, the files were just living in the wrong
directory.

## 2026-08-14 (yet later) — Fixed the 4 wrong-TMDB-tag cases from the nested-folder triage

**Context**: Group 3 of the 58-folder triage — 4 files that already had *a* TMDB id (so the
2026-08-13 "no TMDB id" audit never caught them) but the wrong one.
**Decision — the real fix (Los Muertos)**: `Los.muertos.2004.1080p.WEB-DL...mkv` — the actual
main film file of Lisandro Alonso's *Los Muertos (2004)* — was mistagged as "Cómo se hizo 'Los
muertos'" (a making-of documentary, tmdb:306840). Looked it up via Radarr's term search ("Los
Muertos 2004"), which returned both the wrong making-of entry and the correct film
(tmdb:36241, originalTitle "Los Muertos") side by side, confirming which was which. Applied the
correct id to the Jellyfin item; as with the Happiness fix, `RemoteSearch/Apply` updated
ProviderIds/Overview/artwork but left `Name` on the old wrong title, needing the same direct
item-DTO edit to fix. Added the now-correctly-tagged film to Radarr (it had never been linked —
excluded from every prior backfill because of this folder's shared-folder status), verified
`hasFile:true` and zero grab/queue activity, flipped `monitored:true`. Radarr total: 2417 → 2418.
**Decision — the other 3 (bonus content, not real films)**: `dead set 2`/`dead set 3` (both
wrongly tagged as an unrelated documentary, "Civil War Life: Left for Dead") and *La Libertad*'s
deleted scene (wrongly tagged as an unrelated 2010 film) aren't standalone movies — same
category as the already-documented "not real movies" bucket. Rather than hunting for a "correct"
TMDB id for content that was never meant to be its own catalogued film, cleared `ProviderIds`
entirely via a direct item-DTO edit (also cleared Overview/ratings/premiere date, which had all
been inherited from the wrong match) and reset `Name` to a plain filename-derived label, matching
how `dead set 1`/`4`/`5` already look. No Radarr entry created for these three — same treatment
as the earlier hygiene bucket.
**Rationale**: Distinguishing "this is a real movie with the wrong id" from "this was never a
real standalone movie" determined whether the fix was a re-tag (Los Muertos) or a tag-clear
(the other three) — conflating them would have either left a real film mistagged or invented a
fake catalog entry for bonus content.

## 2026-08-14 (final today) — Fixed the La Flor (2018) 8-file misidentification cluster

**Context**: Group 5 of the 58-folder triage — Mariano Llinás's ~14h film *La Flor*, ripped as 8
numbered parts (`1.1`, `1.2`, `2.1`...`3.3`), each individually mismatched by Jellyfin's
scraper to a wildly unrelated title (an Atlético Madrid documentary, two anime films, "The
House of Hate" (1918) four times, a kids' film). Real tmdb id **423778** was found earlier via
manual search (confirmed by its overview: "six independent, successive stories... four
actresses", matching the film exactly).
**Decision**: Retagged all 8 Jellyfin items to tmdb:423778 individually via `RemoteSearch/Apply`
(`ReplaceAllImages=true`, since each had inherited a wrong poster) + the same direct item-DTO
`Name`/`OriginalTitle` fix needed all week for this endpoint. Verified all 8 showed "La Flor"
with correct ProviderIds before merging. Then used Jellyfin's native multi-version support —
`POST /Videos/MergeVersions?Ids=<all 8 item ids>` — to combine them into one primary item with
8 selectable `MediaSources`, instead of 8 separate library tiles. Verified: the primary item now
lists all 8 files as versions; the raw `/Items` count stayed at 2519 (merge doesn't delete the
secondary records, just links them as alternate versions, non-destructively — reversible via
Jellyfin's "Split" if ever needed).
**Decision — not linked to Radarr**: unlike every other fix this week, deliberately did *not*
add this to Radarr. Radarr's model expects one file per movie folder; La Flor's 8 files aren't
interchangeable qualities of the same cut; they're 8 *different* segments of one long film, so
picking any single file for Radarr would only get Bazarr subtitle coverage for that one segment,
not the whole thing. Also lower priority than usual since the film is Argentine and already in
Spanish — the household's primary language — so subtitle need is minimal here anyway.
**Rationale**: Merge Versions is the Jellyfin-native answer to "one logical movie, several
physical files" — cleaner than either leaving 8 fake standalone movies or arbitrarily picking
one file as "the" movie and hiding the rest.

## 2026-08-14 (closing) — Resolved the last ambiguous case, closing out the 58-folder triage

**Context**: The one remaining "ambiguous" item from the nested-folder triage — a file tagged
as "Akira Kurosawa: It Is Wonderful to Create: 'High and Low'" (tmdb:523625, a real 37-minute
Toho documentary) sitting inside the *Tengoku to jigoku* (*High and Low*, 1963) folder.
**Finding**: Not a documentary at all. Compared file sizes — both `.avi` files in that folder
are **byte-for-byte identical** (2,197,661,696 bytes each), nowhere near a plausible size for a
37-minute doc. It's simply a duplicate rip of the main 163-minute film, mistagged with an
unrelated documentary's TMDB id (same root-cause pattern as the other wrong-tag cases fixed
earlier today).
**Decision**: Retagged it to the correct id (tmdb:12493, matching the already-correct main
file), then merged the two into one item via `MergeVersions` — same treatment as *La Flor*,
appropriate here since, unlike La Flor's 8 distinct segments, these two files genuinely are the
same content. No Radarr change needed; the main file was already linked from group 1. Left the
now-clearly-redundant 2.1GB duplicate file on disk rather than deleting it — worth revisiting
given the NAS is at 97% full, but deleting wasn't asked for and is harder to undo than a
Jellyfin re-tag.
**Closing note**: This was the last item of the original 58-folder bucket. Final tally: 26 safe
(linked to Radarr), 3 misplaced-file bugs (moved + linked), 4 wrong-tag cases (Los Muertos
retagged + linked, 3 others tag-cleared), 1 ambiguous (resolved as a duplicate, retagged +
merged), 8 La Flor fragments (retagged + merged, deliberately not linked to Radarr), 6 harmless
duplicates (no action), 10 already handled the day before. Radarr total after all of today's
work: 2418 movies (was 2361 before this week's TMDB/Radarr work began), zero duplicate tmdbIds.

**Follow-up same day**: deleted the now-redundant 2.1GB duplicate (`Tengoku to jigoku/
Tengoku to jigoku.avi`, the nested copy — confirmed first via Radarr's `movieFile.path` that it
tracks the *other*, top-level copy, so nothing linked would break) to reclaim space on the
97%-full NAS. Verified the file gone, ran a full Jellyfin library scan to clean up the merged
item's stale second `MediaSource` (library count 2519 → 2518, matching the one removed record),
and confirmed Radarr's entry (still pointing at the surviving file) was unaffected —
`hasFile:true`/`monitored:true` unchanged.

## 2026-08-14 (yet another) — Diagnosed the "9 Radarr couldn't find" from the 2026-08-12 backfill

**Context**: The 9 titles left `monitored:false` after the original 2210-title backfill were
assumed to be a folder-name-casing mismatch (per that day's note, "e.g. 'The boat that rocked'
vs the folder's actual 'The Boat That Rocked'"). Re-checked all 9 individually via Radarr's
`manualimport` endpoint (which surfaces the actual rejection reason, unlike the plain
`RescanMovie` command) plus an independent cross-check via Jellyfin's own `PlaybackInfo` stream
probe (the same method that caught *The Man from Earth*'s missing audio in an earlier session).
**Finding — 8 of the 9 have no audio track at all**, confirmed independently by both Radarr's
media analysis and Jellyfin's stream probe: *The Boat That Rocked*, *Fresno*, *Hotel Monterey*,
*La chambre*, *Nightwatching*, *Popstar: Never Stop Never Stopping*, *Snowtown*, *Stranger Than
Fiction*. Not a path/casing problem at all — the casing theory from 2026-08-12 doesn't hold up;
every path Radarr has on file matches Jellyfin's actual path exactly. These are genuinely silent
files needing a fresh download, same as *The Man from Earth* — left `monitored:false` as-is,
same treatment.
**Finding — the 9th, *The Mother and the Whore (1973)*, is fine but structurally unsupported.**
Ships as two files (`...CD1.avi` / `...CD2.avi`, a VHS-era 2-disc split of one ~3h20min film).
Confirmed it has real French audio (`mp3` codec) and plays correctly in Jellyfin as one
continuous stacked item (`PartCount: 2`). Radarr's manual-import explicitly rejects it —
`"File is suspected multi-part file, Radarr doesn't support this"` — even though the movie
lookup itself succeeds (already correctly matched to movieId 1268). Same underlying limitation
as *La Flor*'s 8-file cluster: Radarr's one-file-per-movie model can't represent this. Left
unlinked rather than force-importing just CD1, which would only get Bazarr searching subtitles
for half the runtime — same reasoning and same outcome as the La Flor decision.
**Decision**: No changes made — this was purely diagnostic. All 9 remain `monitored:false`,
correctly reflecting their real state (8 broken files, 1 Radarr-incompatible multi-part film)
rather than a fixable metadata problem. Documented per-title so a future redownload pass
(the 8 broken ones) doesn't need to re-derive which titles or why.

## 2026-08-14 (final) — Fixed the 2 loose files from the 2026-08-12 backfill

**Context**: The last open item from the original backfill's 7 errors — 2 files sitting where
the path-parent logic used for that run couldn't handle them.
**Decision — El Partido (2026)**: genuinely a loose `.mp4` directly in `Peliculas/` root, no
enclosing folder. Created `El Partido (2026)/` and moved the file in. After a full Jellyfin
rescan it re-identified correctly (same tmdb:1666712/imdb:tt41593328) but under its English
title "The Match" instead of "El Partido" — fixed via the same direct item-DTO `Name` edit used
all week, to stay consistent with the rest of the (Spanish-titled) library.
**Decision — La cara oculta (2011)**: not actually a "loose file" problem — the folder already
existed and already had a proper `La-Cara Oculta-(2011).mp4` (1.4GB) sitting in it. The real
issue was a **leftover raw DVD-structure folder** (`VIDEO_TS`/`AUDIO_TS`, 4.4GB of `.VOB`/`.IFO`/
`.BUP` files) sitting alongside it, which Jellyfin was indexing *instead of* the clean mp4 —
explains the original "can't handle this" backfill error, and produced a nonsense ~27-hour
runtime (`VideoType: Dvd`) when checked this session. Deleted the redundant `VIDEO_TS`/
`AUDIO_TS` folders (the mp4 is a complete, playable copy of the same rip — nothing lost) to
both fix the indexing and reclaim 4.4GB on the 97%-full NAS. After the rescan, Jellyfin
correctly indexed just the mp4 with a sane runtime (~96 min).
Added both to Radarr with the usual pattern — canary-free this time given how many times this
exact flow has been verified today — confirmed `hasFile:true` and zero queue/grab activity
before flipping `monitored:true`. Radarr total: 2418 → 2420.
**Rationale**: This closes every open item from the 2026-08-12 backfill's original error/review
list (7 errors + 58 nested-folder set-aside + 9 "couldn't find"), three separate sessions later.

<!-- Add new decisions above this line, newest first -->
