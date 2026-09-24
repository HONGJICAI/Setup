# vps setup

Sets up a fresh Ubuntu 24.04 VPS (x86_64) with:

- **sing-box**: VLESS + REALITY + Vision as the main proxy, Hysteria2 as a UDP backup
- **derper** (optional): a Tailscale DERP relay that only serves your own tailnet
- **Tailscale** (optional), **Docker**, BBR, key-only SSH and a ufw firewall

The same script covers every VPS. Only the ones with `DERP_DOMAIN` set in
`.env` run derper. Tailscale uses DERP only when a direct connection fails,
and each device picks the nearest region, so one or two derpers close to
where your devices are is plenty. Give each one its own `DERP_REGION_ID`.

## Usage

1. For a derper VPS only: point a DNS A record (e.g. `derp.yourdomain`) at it.
2. On the VPS, as root:

   ```sh
   git clone https://github.com/HONGJICAI/Setup.git
   cd Setup/vps
   cp .env.example .env
   vi .env            # DERP_DOMAIN only on derper VPSes
   ./install.sh
   ```

3. With `TAILSCALE=true` and no `TS_AUTHKEY`, open the printed URL to add the VPS to your
   tailnet. Then, in the Tailscale admin console, turn on **Disable key
   expiry** for it.
4. The end of the run prints (and saves to `/opt/setup/client-info.txt`):
   - a `vless://` and a `hysteria2://` link, with QR codes, to import into clients
   - on derper VPSes, a `derpMap` region to paste into your tailnet policy
     file. With several derpers, put all their regions under one `"Regions"`.

Re-running is safe. Secrets are generated on the first run only, so client
configs keep working. `.env` is gitignored, so your domain never lands in the repo.

## Ports

| Port | Service | When |
|------|---------|------|
| `REALITY_PORT`/tcp | VLESS + REALITY | always: 443, or 8443 with derper |
| `HY2_PORT` (443)/udp | Hysteria2 | always |
| 443/tcp, 80/tcp | derper (TLS, Let's Encrypt HTTP-01) | `DERP_DOMAIN` set |
| `DERP_STUN_PORT` (3478)/udp | derper STUN | `DERP_DOMAIN` set |
| 41641/udp | Tailscale direct connections | `TAILSCALE=true` |
| 22/tcp (or sshd's port) | SSH | always |

derper needs 443/tcp because it only gets a Let's Encrypt certificate when
serving on 443, so on derper VPSes REALITY moves to 8443. REALITY doesn't
depend on the port for its camouflage: it borrows `REALITY_SNI`'s real TLS
handshake.

## Script order

`install.sh` runs:

1. `01-base.sh` — apt packages (curl, openssl, ufw, qrencode, unattended-upgrades…)
2. `02-docker.sh` — Docker CE + compose plugin from Docker's apt repo
3. `03-tailscale.sh` — installs Tailscale and logs in (`TS_AUTHKEY` or login URL); skipped with `TAILSCALE=false`
4. `04-tweaks.sh` — runs every script in `tweaks/`
5. `05-services.sh` — generates secrets, renders `templates/sing-box.json`,
   starts `compose.yml` (derper only via the `derp` profile), and prints client info

## Tweaks

One file per tweak in `tweaks/`, no numbering; drop in a new `.sh` to add one.
They're independent, and if one fails the rest still run.

- `network.sh` — BBR + larger UDP buffers for QUIC
- `ssh.sh` — key-only login. Skipped if no `authorized_keys` exists, so it can't lock you out
- `firewall.sh` — ufw: deny incoming except the ports above

## Where things live

`/opt/setup/` holds everything generated (mode 700):

- `secrets/` — VLESS UUID, REALITY keypair and short ID, Hysteria2 password.
  Delete a file and re-run to rotate it.
- `sing-box/` — rendered `config.json` and the self-signed Hysteria2 cert
  (ECDSA; clients pin its SHA-256)
- `derper/` — Let's Encrypt certs
- `client-info.txt` — links and `derpMap`

## Upgrading

Image versions are pinned in `compose.yml`. Bump them, then run `./05-services.sh`.

## CI

`.github/workflows/install-vps.yml` runs, with derper off and on, `install.sh` twice on `ubuntu-24.04`
(checking the second run keeps every secret), then `test/client-check.sh`
connects through both REALITY and Hysteria2 and checks derper responds.
Tailscale login is skipped there.
