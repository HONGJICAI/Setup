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

DERP_DOMAIN="${DERP_DOMAIN:?DERP_DOMAIN must be set in .env}"
TS_AUTHKEY="${TS_AUTHKEY:-}"
REALITY_PORT="${REALITY_PORT:-8443}"
HY2_PORT="${HY2_PORT:-443}"
DERP_STUN_PORT="${DERP_STUN_PORT:-3478}"
REALITY_SNI="${REALITY_SNI:-www.microsoft.com}"
HY2_SNI="${HY2_SNI:-www.bing.com}"
PUBLIC_IP="${PUBLIC_IP:-}"
export DERP_DOMAIN REALITY_PORT HY2_PORT DERP_STUN_PORT REALITY_SNI HY2_SNI

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 install -y --no-install-recommends "$@"
}
