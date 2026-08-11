# Server TODO

General punch list for the homelab. Not a decision record (see `decisions/log.md` for those) —
just things that need doing. Check items off / remove them as they're resolved, add new ones
as they come up.

## Open

- [ ] **Audit Cloudflare Access on exposed ARR subdomains** (found 2026-08-11) — Radarr,
      Sonarr, Bazarr, Prowlarr, Lidarr, Profilarr (and others) are reachable over the public
      internet via the Cloudflare Tunnel. Unknown whether any Access policy (email OTP, etc.)
      sits in front of them, or if they rely solely on their own app-level login. The
      Cloudflare API token used so far (`~/.config/secrets/cloudflare_api_token`) can't read
      Access config — needs either a broader token or a manual check in the Zero Trust
      dashboard (Access → Applications).
- [ ] **Decide on `ricota-db/`** — lives inside the homelab repo (`~/homelab/ricota-db/`) but
      is untracked in git; has `.env` and `keys.txt` with real secrets in it. Either commit it
      with secrets stripped out (`.env.example` instead) and add real `.env`/`keys.txt` to
      `.gitignore`, or move it out of the homelab repo entirely if it's not meant to live here.
- [ ] **OpenClaw / Claudito — revive or retire** — fully torn down (no containers, no
      network), but docs used to describe it as an active daily service (Telegram bot, morning
      brief). Either bring it back properly or remove the historical section from
      `services/services.md` so it stops implying it's live.
- [ ] **Stats plugin — decide if Playback Reporting (already installed) is enough**, or if it's
      worth adding Jellystat for a nicer visual dashboard (needs its own container + Postgres).

## Done (kept for context, remove once stale)

- [x] Radarr/Sonarr Telegram notifications (2026-08-11)
- [x] Jellyfin "now playing" Telegram notification via Webhook plugin (2026-08-11)
- [x] Jellyseerr admin + per-user Telegram notifications (2026-08-11)
- [x] `home.matiasmassetti.com` tunnel target fixed, Homarr → homepage (2026-08-11)
- [x] `nas.matiasmassetti.com` — removed public DSM exposure, ingress rule + DNS record both deleted (2026-08-11)
- [x] `CLAUDE.md` / `services/services.md` / `network/network.md` synced with real running stack (2026-08-11)
