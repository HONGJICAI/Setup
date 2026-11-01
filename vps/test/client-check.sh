#!/usr/bin/env bash
# End-to-end check, run on the VPS after install.sh: connects to every enabled
# sing-box inbound as a client over 127.0.0.1 and fetches a page through each.
# shellcheck source=../lib.sh
. "$(dirname "$0")/../lib.sh"

cd "$VPS_DIR"
secrets="$STATE_DIR/secrets"
sb_image="$(docker compose config --images | grep sing-box)"
tmp="$(mktemp -d)"
trap 'docker rm -f sb-client >/dev/null 2>&1 || true; rm -rf "$tmp"' EXIT

reality_client() { # port sni
  cat <<EOF
{
  "inbounds": [{ "type": "socks", "listen": "127.0.0.1", "listen_port": 10800 }],
  "outbounds": [{
    "type": "vless",
    "server": "127.0.0.1",
    "server_port": $1,
    "uuid": "$(cat "$secrets/vless_uuid")",
    "flow": "xtls-rprx-vision",
    "tls": {
      "enabled": true,
      "server_name": "$2",
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
}

protos=(reality-a)
reality_client "$REALITY_PORT" "$REALITY_SNI" > "$tmp/reality-a.json"
if [[ -n "$REALITY_SNI_B" ]]; then
  protos+=(reality-b)
  reality_client "$REALITY_PORT_B" "$REALITY_SNI_B" > "$tmp/reality-b.json"
fi

# Trusts exactly the server's self-signed cert, like a pinned client.
if [[ "$HY2_ENABLED" == true ]]; then
  protos+=(hysteria2)
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
fi

failed=0
for proto in "${protos[@]}"; do
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

# Disabled inbounds must not be listening.
if [[ "$HY2_ENABLED" != true && -n "$(ss -Hlnu "sport = :$HY2_PORT")" ]]; then
  echo "FAIL: HY2_ENABLED=false but something listens on $HY2_PORT/udp" >&2
  failed=1
fi

# derper answers on its plain-HTTP port even before it has a certificate.
if [[ "$DERP" != true ]]; then
  exit "$failed"
fi
code="$(curl -sS --max-time 10 -o /dev/null -w '%{http_code}' http://127.0.0.1/generate_204 || true)"
if [[ "$code" == 204 ]]; then
  echo "ok: derper"
else
  echo "FAIL: derper (HTTP $code)" >&2
  docker logs derper >&2
  failed=1
fi

exit "$failed"
