#!/usr/bin/env bash
# shellcheck source=../lib.sh
. "$(dirname "$0")/../lib.sh"

# Services use host networking, so ufw (INPUT chain) governs them directly.
# Ports removed from .env later stay open until you `ufw delete` them.
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null

# Keep whatever port sshd is actually on reachable before enabling.
for port in $(sshd -T 2>/dev/null | awk '$1 == "port" { print $2 }'); do
  ufw allow "$port/tcp" comment 'ssh' >/dev/null
done
ufw allow 22/tcp comment 'ssh' >/dev/null

ufw allow 80/tcp comment 'derper ACME' >/dev/null
ufw allow 443/tcp comment 'derper' >/dev/null
ufw allow "$DERP_STUN_PORT/udp" comment 'derper STUN' >/dev/null
ufw allow "$REALITY_PORT/tcp" comment 'sing-box REALITY' >/dev/null
ufw allow "$HY2_PORT/udp" comment 'sing-box Hysteria2' >/dev/null
ufw allow 41641/udp comment 'tailscale direct' >/dev/null

ufw --force enable >/dev/null
ufw status verbose
