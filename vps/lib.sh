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
HY2_PORT="${HY2_PORT:-443}"
DERP_STUN_PORT="${DERP_STUN_PORT:-3478}"
DERP_REGION_ID="${DERP_REGION_ID:-900}"
REALITY_SNI="${REALITY_SNI:-www.microsoft.com}"
HY2_SNI="${HY2_SNI:-www.bing.com}"
PUBLIC_IP="${PUBLIC_IP:-}"

if [[ "$TAILSCALE" != true && "$TAILSCALE" != false ]]; then
  echo "Error: TAILSCALE must be true or false, got '$TAILSCALE'." >&2
  exit 1
fi
if [[ -n "$DERP_DOMAIN" ]]; then
  DERP=true
  if [[ "$TAILSCALE" != true ]]; then
    echo "Error: derper verifies clients through tailscaled; set TAILSCALE=true or clear DERP_DOMAIN." >&2
    exit 1
  fi
  REALITY_PORT="${REALITY_PORT:-8443}"
  if [[ "$REALITY_PORT" == 443 ]]; then
    echo "Error: derper needs 443/tcp; pick another REALITY_PORT." >&2
    exit 1
  fi
  # Turns on the derper service in compose.yml.
  COMPOSE_PROFILES=derp
else
  DERP=false
  REALITY_PORT="${REALITY_PORT:-443}"
  COMPOSE_PROFILES=
fi
export DERP DERP_DOMAIN DERP_REGION_ID TAILSCALE COMPOSE_PROFILES REALITY_PORT HY2_PORT DERP_STUN_PORT REALITY_SNI HY2_SNI

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 install -y --no-install-recommends "$@"
}
