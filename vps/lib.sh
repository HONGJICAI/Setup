# shellcheck shell=bash
# Sourced by every step: strict mode, root check, and settings from .env.
set -euo pipefail

VPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Generated secrets, configs and certs live here, outside the repo.
STATE_DIR=/opt/setup
export STATE_DIR

if [[ $EUID -ne 0 ]]; then
  echo "Error: run as root (sudo $0)." >&2
  exit 1
fi

if [[ ! -f "$VPS_DIR/.env" ]]; then
  echo "Error: $VPS_DIR/.env not found. Run: cp .env.example .env, then edit it." >&2
  exit 1
fi

set -a
# shellcheck source=/dev/null
. "$VPS_DIR/.env"
set +a

DERP_DOMAIN="${DERP_DOMAIN:-}"
TAILSCALE="${TAILSCALE:-true}"
TS_AUTHKEY="${TS_AUTHKEY:-}"
REALITY_PORT="${REALITY_PORT:-}"
REALITY_SNI="${REALITY_SNI:-}"
REALITY_SNI_B="${REALITY_SNI_B:-}"
REALITY_PORT_B="${REALITY_PORT_B:-}"
HY2_ENABLED="${HY2_ENABLED:-false}"
HY2_PORT="${HY2_PORT:-443}"
DERP_STUN_PORT="${DERP_STUN_PORT:-3478}"
DERP_REGION_ID="${DERP_REGION_ID:-900}"
HY2_SNI="${HY2_SNI:-www.bing.com}"
PUBLIC_IP="${PUBLIC_IP:-}"

die() {
  echo "Error: $*" >&2
  exit 1
}

for flag in TAILSCALE HY2_ENABLED; do
  if [[ "${!flag}" != true && "${!flag}" != false ]]; then
    die "$flag must be true or false, got '${!flag}'."
  fi
done

# No default: the right site depends on what China blocks and what other
# proxies overuse, so it's a deliberate choice (see README).
if [[ -z "$REALITY_SNI" ]]; then
  die "REALITY_SNI is empty. Set it in .env to a TLS 1.3 + h2 site that isn't blocked in China (see README)."
fi
if [[ -n "$REALITY_SNI_B" && "$REALITY_SNI_B" == "$REALITY_SNI" ]]; then
  die "REALITY_SNI_B must differ from REALITY_SNI."
fi

if [[ -n "$DERP_DOMAIN" ]]; then
  DERP=true
  if [[ "$TAILSCALE" != true ]]; then
    die "derper verifies clients through tailscaled; set TAILSCALE=true or clear DERP_DOMAIN."
  fi
  # derper needs 443/tcp, so both REALITY inbounds move off it.
  REALITY_PORT="${REALITY_PORT:-8443}"
  [[ -n "$REALITY_SNI_B" ]] && REALITY_PORT_B="${REALITY_PORT_B:-9443}"
  # Turns on the derper service in compose.yml.
  COMPOSE_PROFILES=derp
else
  DERP=false
  REALITY_PORT="${REALITY_PORT:-443}"
  [[ -n "$REALITY_SNI_B" ]] && REALITY_PORT_B="${REALITY_PORT_B:-8443}"
  COMPOSE_PROFILES=
fi

# Every TCP listener needs its own port.
tcp_ports=("$REALITY_PORT")
[[ -n "$REALITY_SNI_B" ]] && tcp_ports+=("$REALITY_PORT_B")
[[ "$DERP" == true ]] && tcp_ports+=(443 80)
if [[ -n "$(printf '%s\n' "${tcp_ports[@]}" | sort | uniq -d)" ]]; then
  die "TCP ports clash: ${tcp_ports[*]}. Check REALITY_PORT, REALITY_PORT_B and derper (443, 80)."
fi
if [[ "$HY2_ENABLED" == true && "$DERP" == true && "$HY2_PORT" == "$DERP_STUN_PORT" ]]; then
  die "HY2_PORT and DERP_STUN_PORT are both $HY2_PORT/udp."
fi
unset tcp_ports

export DERP DERP_DOMAIN DERP_REGION_ID TAILSCALE COMPOSE_PROFILES \
  REALITY_PORT REALITY_SNI REALITY_PORT_B REALITY_SNI_B \
  HY2_ENABLED HY2_PORT HY2_SNI DERP_STUN_PORT

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 install -y --no-install-recommends "$@"
}
