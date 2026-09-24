#!/usr/bin/env bash
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

echo "==> Tailscale"

# derper verifies clients through this node's tailscaled, so it must be logged in.
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
systemctl enable --now tailscaled

if tailscale status >/dev/null 2>&1; then
  echo "  already logged in"
  exit 0
fi

if [[ -n "$TS_AUTHKEY" ]]; then
  tailscale up --authkey="$TS_AUTHKEY"
elif [[ -t 0 ]]; then
  echo "  Open the URL below to add this VPS to your tailnet."
  tailscale up
else
  echo "Warning: not logged in to Tailscale and no TS_AUTHKEY set." >&2
  echo "  Run 'tailscale up' on the VPS. Until then derper rejects every client." >&2
  exit 0
fi

echo "  Logged in. In the admin console, turn on 'Disable key expiry' for this"
echo "  machine, or it drops off the tailnet (and derper stops verifying) in ~180 days."
