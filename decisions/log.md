# Architecture Decision Records

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
