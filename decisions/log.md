# Architecture Decision Records

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

<!-- Add new decisions above this line, newest first -->
