# Network

## Topology

```
ISP (300 Mbps down / ~30-50 Mbps up, Argentina, dynamic public IP)
  → I-CON IC455WDB modem (bridge mode)
    → TP-Link Archer AX55 (main router, 192.168.1.1)
      → WiFi "Matias" (2.4GHz + 5GHz, WPA2/WPA3)
      → Ethernet:
          Mini PC (192.168.1.239)
          NAS (192.168.1.119)
          Gaming PC (DHCP)
```

## IP Assignments

| IP | Device | Type |
|----|--------|------|
| 192.168.1.1 | TP-Link Archer AX55 (router) | Static |
| 192.168.1.119 | Synology DS423 (NAS) | Static |
| 192.168.1.239 | Beelink SER8 (mini PC) | Static |
| DHCP | Gaming PC | Dynamic |
| DHCP | Other devices (phones, laptops) | Dynamic |

## Tailscale (VPN Overlay)

> Verified 2026-08-09 via `tailscale status` — IPs below replace any older list in this file or in `old-docs/`.

| Tailscale IP | Device | OS | Status |
|--------------|--------|----|--------|
| 100.112.136.118 | homelab (mini PC) | Linux | Online. Tags: `SSH`, `Subnets`. Advertises + approved subnet route `192.168.1.0/24` |
| 100.102.177.38 | Matias's MacBook Pro | macOS | Online |
| 100.111.162.37 | Samsung SM-S918B (S23 Ultra) | Android | Intermittent |

Tailnet: `matiasmassetti@gmail.com`. MagicDNS domain: `tail076e1b.ts.net` (enabled).
Tailscale manages DNS (resolv.conf points to 100.100.100.100).
Tailnet ACL policy (Access controls → JSON editor) is the default wide-open grant (`{"src": ["*"], "dst": ["*"], "ip": ["*"]}`) — not used to restrict anything today.

### Remote SSH access

From outside the house, SSH goes through Tailscale, not the LAN IP directly:

```
ssh matias@homelab        # MagicDNS, recommended
ssh matias@100.112.136.118  # fallback if MagicDNS resolution misbehaves
```

`ssh matias@192.168.1.239` only works from the home LAN (or via the approved Tailscale subnet route, which needs the client to have "Use subnet routes" enabled — flaky by default, prefer the two commands above).

**Tailscale SSH is enabled** (not plain OpenSSH auth) and periodically requires re-authentication ("check mode"). When it triggers, the `ssh` client hangs and prints a `https://login.tailscale.com/a/...` link — open it and sign in with `matiasmassetti@gmail.com` to continue. Before that check succeeds, connection attempts can look like a dead/blocked SSH (timeouts or instant "connection refused" on various ports) if the Tailscale client on the connecting device is also mid-reconnect — check `tailscale status` first before assuming a firewall problem (there isn't one; see Firewall section below).

## DNS

### On the mini PC
- resolv.conf managed by Tailscale → 100.100.100.100
- Pi-hole listens on port 53 (192.168.1.239)
- Pi-hole upstream → Unbound (172.30.0.2:5335, recursive resolver)
- DNSSEC enabled

### For the network
- Router DNS should point to 192.168.1.239 (Pi-hole) for whole-network ad blocking
- Docker containers use `dns: 192.168.1.239` with `1.1.1.1` fallback

## Domain & Cloudflare

- **Domain**: matiasmassetti.com
- **Registrar**: Porkbun (~$10/year)
- **DNS Provider**: Cloudflare (manages all records)
- **SSL**: Automatic via Cloudflare
- **DDoS**: Cloudflare free tier
- **Tunnel**: `cloudflared` container — no port forwarding needed

### Cloudflare Tunnel Public URLs

Pulled from the tunnel's live ingress config via the Cloudflare API on 2026-08-11 (ground truth, not guesswork — see `CLAUDE.md` for account/tunnel IDs and how to query it again). Account has a scoped API token at `~/.config/secrets/cloudflare_api_token` for managing this without the dashboard.

| Subdomain | Service | Local Target |
|-----------|---------|-------------|
| media.matiasmassetti.com | Jellyfin | 192.168.1.239:8096 |
| radarr.matiasmassetti.com | Radarr | 192.168.1.239:7878 |
| sonarr.matiasmassetti.com | Sonarr | 192.168.1.239:8989 |
| bazarr.matiasmassetti.com | Bazarr | 192.168.1.239:6767 |
| lidarr.matiasmassetti.com | Lidarr | 192.168.1.239:8686 |
| prowlarr.matiasmassetti.com | Prowlarr | 192.168.1.239:9696 |
| profilarr.matiasmassetti.com | Profilarr | 192.168.1.239:6868 |
| descargas.matiasmassetti.com | qBittorrent | 192.168.1.239:8080 |
| usenet.matiasmassetti.com | SABnzbd | 192.168.1.239:8085 |
| pedidos.matiasmassetti.com | Jellyseerr | 192.168.1.239:5055 |
| home.matiasmassetti.com | homepage | 192.168.1.239:3000 (was Homarr on :7575 — Homarr is gone, tunnel entry fixed 2026-08-11) |
| status.matiasmassetti.com | Uptime Kuma | 192.168.1.239:3001 |
| cloud.matiasmassetti.com | OpenCloud | 192.168.1.239:9200 |
| cinemateca.matiasmassetti.com | Cinemateca | 192.168.1.239:8001 |
| assets.matiasmassetti.com | image-server | 192.168.1.239:4010 |
| cen-api.matiasmassetti.com | cen-dashboard | 192.168.1.239:3003 |
| ricota-api.matiasmassetti.com | Ricota DB (Caddy) | `ricota-caddy:80` (container hostname, same `docker_homelab` network as cloudflared) |

**Removed 2026-08-11**: `nas.matiasmassetti.com` → `192.168.1.119:5000` was exposing the Synology DSM login page directly to the internet, with no Cloudflare Access policy visible in front of it — Matias didn't know it was there. Both the tunnel ingress rule and the DNS CNAME record (`d9a9622c...`, pointed at the tunnel's `.cfargotunnel.com` address, created 2026-02-08) were deleted via API once the token got `Zone:DNS:Edit`. The hostname no longer resolves at all. Remote NAS access still available via Tailscale.

**Cloudflare Access added 2026-08-12**: 15 of the 17 hostnames above now sit behind a Cloudflare Access policy (email OTP to `matiasmassetti@gmail.com`, 168h session) in addition to their own app login — everything except `media.matiasmassetti.com` (Jellyfin) and `pedidos.matiasmassetti.com` (Jellyseerr), left open deliberately since family/friends use those two directly. Full list and rationale in `decisions/log.md`. Managed via the same API token (`Access: Apps and Policies: Edit` was added to it for this).

## Router

- **Model**: TP-Link Archer AX55 (AX3000, WiFi 6, triple-core)
- **Features**: 4x4 MU-MIMO, OFDMA, beamforming
- **MAC**: EC-75-0C-04-16-24
- **Management**: http://192.168.1.1 or TP-Link Tether app
- **DHCP range**: ~192.168.1.100-199
- **ISP Modem**: I-CON IC455WDB in bridge mode (all routing disabled)

## Firewall

No custom firewall rules on the mini PC (ufw not configured).
All external access goes through Cloudflare Tunnel — no ports exposed to the internet.

## Docker Networks

| Network | Subnet | Purpose |
|---------|--------|---------|
| arr_network | (bridge, auto) | ARR stack services |
| docker_homelab | (bridge, auto) | Infrastructure + cloud services |
| dns_network | 172.30.0.0/24 | Pi-hole + Unbound |
| media_tracker_network | 172.21.0.0/16 | Media tracker project |
| openclaw_network | 172.31.0.0/24 | OpenClaw AI agent (isolated, no cross-network access) |
