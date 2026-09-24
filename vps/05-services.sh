#!/usr/bin/env bash
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

echo "==> Services (sing-box + derper)"

cd "$VPS_DIR"
secrets="$STATE_DIR/secrets"
sb_dir="$STATE_DIR/sing-box"
mkdir -p "$secrets" "$sb_dir" "$STATE_DIR/derper"
chmod 700 "$STATE_DIR" "$secrets"

sb_image="$(docker compose config --images | grep sing-box)"
sb() { docker run --rm "$sb_image" "$@"; }

# Secrets are generated on the first run only, so re-runs keep client configs valid.
# Delete a file under $secrets to rotate that secret.
secret() {
  local file="$secrets/$1"
  shift
  if [[ ! -s "$file" ]]; then
    (umask 077; "$@" > "$file")
  fi
  cat "$file"
}

reality_keypair() {
  local out
  out="$(sb generate reality-keypair)"
  awk '/PrivateKey/ { print $2 }' <<< "$out" > "$secrets/reality_private_key"
  awk '/PublicKey/ { print $2 }' <<< "$out" > "$secrets/reality_public_key"
}
if [[ ! -s "$secrets/reality_private_key" || ! -s "$secrets/reality_public_key" ]]; then
  (umask 077; reality_keypair)
fi

VLESS_UUID="$(secret vless_uuid sb generate uuid)"
REALITY_SHORT_ID="$(secret reality_short_id openssl rand -hex 8)"
HY2_PASSWORD="$(secret hy2_password openssl rand -hex 16)"
REALITY_PRIVATE_KEY="$(cat "$secrets/reality_private_key")"
REALITY_PUBLIC_KEY="$(cat "$secrets/reality_public_key")"
export VLESS_UUID REALITY_SHORT_ID HY2_PASSWORD REALITY_PRIVATE_KEY

# Self-signed Hysteria2 cert; clients pin its SHA-256. ECDSA, not Ed25519: sing-box
# clients parrot Chrome's QUIC handshake, which doesn't offer Ed25519.
# Regenerated only if HY2_SNI changes.
if ! openssl x509 -in "$sb_dir/hy2.crt" -noout -ext subjectAltName 2>/dev/null | grep -qx "[[:space:]]*DNS:$HY2_SNI"; then
  (umask 077; openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 3650 \
    -subj "/CN=$HY2_SNI" -addext "subjectAltName=DNS:$HY2_SNI" \
    -keyout "$sb_dir/hy2.key" -out "$sb_dir/hy2.crt" 2>/dev/null)
fi
HY2_PIN="$(openssl x509 -in "$sb_dir/hy2.crt" -outform der | sha256sum | cut -d' ' -f1)"

# Render, validate, then swap in the config.
# Only these get substituted; anything else that looks like $x in the template is left as is.
# shellcheck disable=SC2016
vars='$REALITY_PORT $REALITY_SNI $VLESS_UUID $REALITY_PRIVATE_KEY $REALITY_SHORT_ID $HY2_PORT $HY2_PASSWORD $HY2_SNI'
(umask 077; envsubst "$vars" < templates/sing-box.json > "$sb_dir/config.json.new")
docker run --rm -v "$sb_dir:/etc/sing-box:ro" "$sb_image" check -c /etc/sing-box/config.json.new
changed=0
if ! cmp -s "$sb_dir/config.json.new" "$sb_dir/config.json"; then
  mv "$sb_dir/config.json.new" "$sb_dir/config.json"
  changed=1
else
  rm "$sb_dir/config.json.new"
fi

docker compose up -d --remove-orphans
if (( changed )); then
  docker compose restart sing-box
fi

# Wait until everything is listening.
listening() { [[ -n "$(ss -Hln "$1" "sport = :$2")" ]]; }
for check in "-t $REALITY_PORT" "-u $HY2_PORT" "-t 443" "-t 80" "-u $DERP_STUN_PORT"; do
  read -r proto port <<< "$check"
  for _ in $(seq 1 30); do
    listening "$proto" "$port" && break
    sleep 1
  done
  if ! listening "$proto" "$port"; then
    echo "Error: nothing listening on ${proto#-} port $port" >&2
    docker compose ps
    docker compose logs --tail 50
    exit 1
  fi
done
docker compose ps

# Client info.
if [[ -z "$PUBLIC_IP" ]]; then
  PUBLIC_IP="$(curl -4 -fsS --max-time 10 https://api.ipify.org || curl -4 -fsS --max-time 10 https://ifconfig.me)"
fi
vless_link="vless://$VLESS_UUID@$PUBLIC_IP:$REALITY_PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$REALITY_SNI&fp=chrome&pbk=$REALITY_PUBLIC_KEY&sid=$REALITY_SHORT_ID&type=tcp#vps-reality"
# insecure=1 only skips CA checks for the self-signed cert; pinSHA256 still pins it.
hy2_link="hysteria2://$HY2_PASSWORD@$PUBLIC_IP:$HY2_PORT/?sni=$HY2_SNI&insecure=1&pinSHA256=$HY2_PIN#vps-hysteria2"

info="$STATE_DIR/client-info.txt"
(umask 077; cat > "$info" <<EOF
VLESS + REALITY (primary, $REALITY_PORT/tcp):
$vless_link

Hysteria2 (backup, $HY2_PORT/udp; cert pinned by SHA-256):
$hy2_link

Tailscale DERP: add to your tailnet policy file (Access controls), then check
with 'tailscale netcheck' on a client:
"derpMap": {
  "Regions": {
    "900": {
      "RegionID": 900,
      "RegionCode": "vps",
      "RegionName": "VPS",
      "Nodes": [
        {
          "Name": "900a",
          "RegionID": 900,
          "HostName": "$DERP_DOMAIN",
          "IPv4": "$PUBLIC_IP",
          "STUNPort": $DERP_STUN_PORT
        }
      ]
    }
  }
}
EOF
)

echo
cat "$info"
if [[ -t 1 ]]; then
  echo
  echo "VLESS + REALITY:"
  qrencode -t ansiutf8 "$vless_link"
  echo "Hysteria2:"
  qrencode -t ansiutf8 "$hy2_link"
fi
echo
echo "Saved to $info"
