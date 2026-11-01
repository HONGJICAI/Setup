#!/usr/bin/env bash
# Checks that each REALITY handshake site still works as a REALITY target:
# reachable on 443, TLS 1.3, h2, and a certificate that verifies.
# If one breaks, every client using that inbound fails to connect.
#
# Usage: dest-check.sh [sni...]   (default: $DEST_SNIS, space-separated)
# Installed as /usr/local/bin/setup-dest-check and run hourly by
# setup-dest-check.timer; see `journalctl -u setup-dest-check`.
set -uo pipefail

if (( $# == 0 )); then
  # shellcheck disable=SC2086
  set -- ${DEST_SNIS:-}
fi
if (( $# == 0 )); then
  echo "Usage: $0 sni..." >&2
  exit 2
fi

failed=0
for sni in "$@"; do
  addr="$(getent ahostsv4 "$sni" 2>/dev/null | awk 'NR == 1 { print $1 }')"
  out="$(timeout 15 openssl s_client -connect "$sni:443" -servername "$sni" \
    -tls1_3 -alpn h2 -verify_return_error < /dev/null 2>&1)"
  problems=()
  [[ -z "$addr" ]] && problems+=("no DNS")
  grep -q 'New, TLSv1.3' <<< "$out" || problems+=("no TLS 1.3")
  grep -q 'ALPN protocol: h2' <<< "$out" || problems+=("no h2")
  grep -q 'Verify return code: 0 (ok)' <<< "$out" || problems+=("cert does not verify")
  if (( ${#problems[@]} )); then
    echo "FAIL: $sni (${addr:-?}): ${problems[*]}"
    failed=1
  else
    echo "ok: $sni ($addr)"
  fi
done
exit "$failed"
