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

| Tailscale IP | Device | OS | Status |
|--------------|--------|----|--------|
| 100.118.87.121 | homelab (mini PC) | Linux | Online, offers exit node |
| 100.64.172.116 | Matias's MacBook Pro | macOS | Intermittent |
| 100.77.190.51 | NVIDIA Shield Android TV | Android | Intermittent |
| 100.121.189.40 | Samsung SM-S918B (S23 Ultra) | Android | Intermittent |

Tailscale manages DNS (resolv.conf points to 100.100.100.100).

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

| Subdomain | Service | Local Target |
|-----------|---------|-------------|
| media.matiasmassetti.com | Jellyfin | 192.168.1.239:8096 |
| radarr.matiasmassetti.com | Radarr | 192.168.1.239:7878 |
| sonarr.matiasmassetti.com | Sonarr | 192.168.1.239:8989 |
| descargas.matiasmassetti.com | qBittorrent | 192.168.1.239:8080 |
| pedidos.matiasmassetti.com | Jellyseerr | 192.168.1.239:5055 |
| home.matiasmassetti.com | Homarr | 192.168.1.239:7575 |
| status.matiasmassetti.com | Uptime Kuma | 192.168.1.239:3001 |
| cloud.matiasmassetti.com | OpenCloud | 192.168.1.239:9200 |

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
