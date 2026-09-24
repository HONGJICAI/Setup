#!/usr/bin/env bash
# End-to-end check, run on the VPS after install.sh: connects to both sing-box
# inbounds as a client over 127.0.0.1 and fetches a page through each.
# shellcheck source=../lib.sh
. "$(dirname "$0")/../lib.sh"

cd "$VPS_DIR"
secrets="$STATE_DIR/secrets"
sb_image="$(docker compose config --images | grep sing-box)"
tmp="$(mktemp -d)"
trap 'docker rm -f sb-client >/dev/null 2>&1 || true; rm -rf "$tmp"' EXIT

cat > "$tmp/reality.json" <<EOF
{
  "inbounds": [{ "type": "socks", "listen": "127.0.0.1", "listen_port": 10800 }],
  "outbounds": [{
    "type": "vless",
    "server": "127.0.0.1",
    "server_port": $REALITY_PORT,
    "uuid": "$(cat "$secrets/vless_uuid")",
    "flow": "xtls-rprx-vision",
    "tls": {
      "enabled": true,
      "server_name": "$REALITY_SNI",
      "utls": { "enabled": true, "fingerprint": "chrome" },
      "reality": {
        "enabled": true,
        "public_key": "$(cat "$secrets/reality_public_key")",
        "short_id": "$(cat "$secrets/reality_short_id")"
      }
    }
  }]
}
EOF

# Trusts exactly the server's self-signed cert, like a pinned client.
cat > "$tmp/hysteria2.json" <<EOF
{
  "inbounds": [{ "type": "socks", "listen": "127.0.0.1", "listen_port": 10800 }],
  "outbounds": [{
    "type": "hysteria2",
    "server": "127.0.0.1",
    "server_port": $HY2_PORT,
    "password": "$(cat "$secrets/hy2_password")",
    "tls": {
      "enabled": true,
      "server_name": "$HY2_SNI",
      "alpn": ["h3"],
      "certificate_path": "/etc/sing-box/hy2.crt"
    }
  }]
}
EOF

failed=0
for proto in reality hysteria2; do
  docker run -d --name sb-client --network host \
    -v "$tmp:/client:ro" -v "$STATE_DIR/sing-box:/etc/sing-box:ro" \
    "$sb_image" run -c "/client/$proto.json" >/dev/null
  sleep 2
  code="$(curl -sS --max-time 20 -o /dev/null -w '%{http_code}' \
    -x socks5h://127.0.0.1:10800 https://www.gstatic.com/generate_204 || true)"
  if [[ "$code" == 204 ]]; then
    echo "ok: $proto"
  else
    echo "FAIL: $proto (HTTP $code)" >&2
    docker logs sb-client >&2
    failed=1
  fi
  docker rm -f sb-client >/dev/null
done

# derper answers on its plain-HTTP port even before it has a certificate.
code="$(curl -sS --max-time 10 -o /dev/null -w '%{http_code}' http://127.0.0.1/generate_204 || true)"
if [[ "$code" == 204 ]]; then
  echo "ok: derper"
else
  echo "FAIL: derper (HTTP $code)" >&2
  docker logs derper >&2
  failed=1
fi

exit "$failed"
