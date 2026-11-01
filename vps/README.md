# vps setup

Sets up a fresh Ubuntu 24.04 VPS (x86_64) with:

- **sing-box**: VLESS + REALITY + Vision, optionally a second REALITY inbound
  borrowing a different site, and optionally Hysteria2 (off by default)
- **derper** (optional): a Tailscale DERP relay that only serves your own tailnet
- **Tailscale** (optional), **Docker**, BBR, key-only SSH and a ufw firewall
- an hourly check that the REALITY handshake sites still work

The same script covers every VPS. Only the ones with `DERP_DOMAIN` set in
`.env` run derper. Tailscale uses DERP only when a direct connection fails,
and each device picks the nearest region, so one or two derpers close to
where your devices are is plenty. Give each one its own `DERP_REGION_ID`.
Prefer keeping derper (and Tailscale) off the VPS you proxy through: the
more traffic one IP carries, the more it stands out.

## Usage

1. For a derper VPS only: point a DNS A record (e.g. `derp.yourdomain`) at it.
2. Pick `REALITY_SNI` (and ideally `REALITY_SNI_B`), see below.
3. On the VPS, as root:

   ```sh
   git clone https://github.com/HONGJICAI/Setup.git
   cd Setup/vps
   cp .env.example .env
   vi .env            # REALITY_SNI is required; DERP_DOMAIN only on derper VPSes
   ./install.sh
   ```

4. With `TAILSCALE=true` and no `TS_AUTHKEY`, open the printed URL to add the VPS to your
   tailnet. Then, in the Tailscale admin console, turn on **Disable key
   expiry** for it.
5. The end of the run prints (and saves to `/opt/setup/client-info.txt`):
   - a `vless://` link per REALITY inbound, a `hysteria2://` link if enabled,
     and the same again over IPv6 if the VPS has a public IPv6, with QR codes
   - on derper VPSes, a `derpMap` region to paste into your tailnet policy
     file. With several derpers, put all their regions under one `"Regions"`.

Re-running is safe. Secrets are generated on the first run only, so client
configs keep working. `.env` is gitignored, so your domain never lands in the repo.

## Picking REALITY sites

REALITY answers anyone who isn't your client with the real TLS handshake of
`REALITY_SNI`, so to an observer the connection looks like a visit to that
site. That only holds up if the site plausibly lives at this VPS's IP:

- **Avoid big brands** (`www.apple.com`, `www.microsoft.com`…). They have CDNs
  inside China, so a small overseas IP claiming to be them is an obvious tell.
- **Borrow a neighbour**: a real site hosted in the same subnet or at least
  the same provider. Scan your /24 for hosts with 443 open, read their
  certificates (`openssl s_client -connect <ip>:443 -alpn h2 -tls1_3`), and keep
  sites that resolve to that subnet, support TLS 1.3 + h2, have a valid cert,
  look legitimate, and are reachable from China. Check one with
  `bin/dest-check.sh <site>`.
- A neighbour can go away. When it does, every connection to that inbound
  fails, because REALITY contacts the site on each connection. So set
  `REALITY_SNI_B` to a second site: it runs as a separate inbound on its own
  port, and a client fallback/urltest group over both links moves to B by
  itself. `setup-dest-check.timer` checks both sites hourly
  (`journalctl -u setup-dest-check`); replace a dead one in `.env`, re-run
  `./05-services.sh`, and update that link in your clients.

## Ports

| Port | Service | When |
|------|---------|------|
| `REALITY_PORT`/tcp | VLESS + REALITY A | always: 443, or 8443 with derper |
| `REALITY_PORT_B`/tcp | VLESS + REALITY B | `REALITY_SNI_B` set: 8443, or 9443 with derper |
| `HY2_PORT` (443)/udp | Hysteria2 | `HY2_ENABLED=true` |
| 443/tcp, 80/tcp | derper (TLS, Let's Encrypt HTTP-01) | `DERP_DOMAIN` set |
| `DERP_STUN_PORT` (3478)/udp | derper STUN | `DERP_DOMAIN` set |
| 41641/udp | Tailscale direct connections | `TAILSCALE=true` |
| 22/tcp (or sshd's port) | SSH | always |

derper needs 443/tcp because it only gets a Let's Encrypt certificate when
serving on 443, so on derper VPSes REALITY moves off it. REALITY doesn't
depend on the port for its camouflage: it borrows the site's real TLS
handshake. `lib.sh` refuses settings where two TCP listeners share a port.

## Script order

`install.sh` runs:

1. `01-base.sh` — apt packages (curl, openssl, jq, ufw, qrencode, unattended-upgrades…)
2. `02-docker.sh` — Docker CE + compose plugin from Docker's apt repo
3. `03-tailscale.sh` — installs Tailscale and logs in (`TS_AUTHKEY` or login URL); skipped with `TAILSCALE=false`
4. `04-tweaks.sh` — runs every script in `tweaks/`
5. `05-services.sh` — generates secrets, renders one inbound per enabled
   service from `templates/` into a sing-box config, starts `compose.yml`
   (derper only via the `derp` profile), installs the handshake-site check,
   and prints client info

## Tweaks

One file per tweak in `tweaks/`, no numbering; drop in a new `.sh` to add one.
They're independent, and if one fails the rest still run.

- `network.sh` — BBR + larger UDP buffers for QUIC
- `ssh.sh` — key-only login. Skipped if no `authorized_keys` exists, so it can't lock you out
- `firewall.sh` — ufw: deny incoming except the ports above

## Where things live

`/opt/setup/` holds everything generated (mode 700):

- `secrets/` — VLESS UUID, REALITY keypair and short ID, Hysteria2 password.
  Both REALITY inbounds share them. Delete a file and re-run to rotate it.
- `sing-box/` — rendered `config.json` and, with Hysteria2 on, its
  self-signed cert (ECDSA; clients pin its SHA-256)
- `derper/` — Let's Encrypt certs
- `dest-check.env` — the sites `setup-dest-check` watches
- `client-info.txt` — links and `derpMap`

## Upgrading

Image versions are pinned in `compose.yml`. Bump them, then run `./05-services.sh`.

## CI

`.github/workflows/install-vps.yml` checks that an empty `REALITY_SNI` is
refused, then runs two configurations on `ubuntu-24.04`: **minimal** (one
REALITY inbound, no Tailscale) and **full** (two REALITY inbounds, Hysteria2,
derper). Each runs `install.sh` twice (the second run must keep every
secret), then `test/client-check.sh` connects through every enabled inbound
and checks derper responds, and the handshake-site check must pass on a
real site and fail on a dead one. Tailscale login is skipped there.
