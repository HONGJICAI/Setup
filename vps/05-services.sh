#!/usr/bin/env bash
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

echo "==> Services"

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

# Both REALITY inbounds share the UUID, keypair and short ID; clients differ only
# in port and SNI.
VLESS_UUID="$(secret vless_uuid sb generate uuid)"
REALITY_SHORT_ID="$(secret reality_short_id openssl rand -hex 8)"
HY2_PASSWORD="$(secret hy2_password openssl rand -hex 16)"
REALITY_PRIVATE_KEY="$(cat "$secrets/reality_private_key")"
REALITY_PUBLIC_KEY="$(cat "$secrets/reality_public_key")"
export VLESS_UUID REALITY_SHORT_ID HY2_PASSWORD REALITY_PRIVATE_KEY

# Self-signed Hysteria2 cert; clients pin its SHA-256. ECDSA, not Ed25519: sing-box
# clients parrot Chrome's QUIC handshake, which doesn't offer Ed25519.
# Regenerated only if HY2_SNI changes.
if [[ "$HY2_ENABLED" == true ]]; then
  if ! openssl x509 -in "$sb_dir/hy2.crt" -noout -ext subjectAltName 2>/dev/null | grep -qx "[[:space:]]*DNS:$HY2_SNI"; then
    (umask 077; openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -nodes -days 3650 \
      -subj "/CN=$HY2_SNI" -addext "subjectAltName=DNS:$HY2_SNI" \
      -keyout "$sb_dir/hy2.key" -out "$sb_dir/hy2.crt" 2>/dev/null)
  fi
  HY2_PIN="$(openssl x509 -in "$sb_dir/hy2.crt" -outform der | sha256sum | cut -d' ' -f1)"
fi

# Render each inbound from its template, then assemble and validate the config.
# envsubst only touches the listed variables; anything else that looks like $x is left as is.
frag_dir="$(mktemp -d)"
trap 'rm -rf "$frag_dir"' EXIT
render() { # template out vars [NAME=value...]
  local template="$1" out="$2" vars="$3"
  shift 3
  (umask 077; env "$@" envsubst "$vars" < "templates/$template" > "$frag_dir/$out")
}
# shellcheck disable=SC2016
reality_vars='$INBOUND_TAG $INBOUND_PORT $INBOUND_SNI $VLESS_UUID $REALITY_PRIVATE_KEY $REALITY_SHORT_ID'
render reality.json 1-reality-a.json "$reality_vars" \
  INBOUND_TAG=reality-a INBOUND_PORT="$REALITY_PORT" INBOUND_SNI="$REALITY_SNI"
if [[ -n "$REALITY_SNI_B" ]]; then
  render reality.json 2-reality-b.json "$reality_vars" \
    INBOUND_TAG=reality-b INBOUND_PORT="$REALITY_PORT_B" INBOUND_SNI="$REALITY_SNI_B"
fi
if [[ "$HY2_ENABLED" == true ]]; then
  # shellcheck disable=SC2016
  render hysteria2.json 3-hysteria2.json '$HY2_PORT $HY2_PASSWORD $HY2_SNI'
fi
(umask 077; jq -s '{
  log: { level: "warn", timestamp: true },
  inbounds: .,
  outbounds: [ { type: "direct", tag: "direct" } ]
}' "$frag_dir"/*.json > "$sb_dir/config.json.new")
docker run --rm -v "$sb_dir:/etc/sing-box:ro" "$sb_image" check -c /etc/sing-box/config.json.new
changed=0
if ! cmp -s "$sb_dir/config.json.new" "$sb_dir/config.json"; then
  mv "$sb_dir/config.json.new" "$sb_dir/config.json"
  changed=1
else
  rm "$sb_dir/config.json.new"
fi

docker compose up -d --remove-orphans
# A profile that's switched off isn't an orphan, so stop derper explicitly.
if [[ "$DERP" != true ]]; then
  docker rm -f derper >/dev/null 2>&1 || true
fi
if (( changed )); then
  docker compose restart sing-box
fi

# Wait until everything is listening.
listening() { [[ -n "$(ss -Hln "$1" "sport = :$2")" ]]; }
checks=("-t $REALITY_PORT")
[[ -n "$REALITY_SNI_B" ]] && checks+=("-t $REALITY_PORT_B")
[[ "$HY2_ENABLED" == true ]] && checks+=("-u $HY2_PORT")
if [[ "$DERP" == true ]]; then
  checks+=("-t 443" "-t 80" "-u $DERP_STUN_PORT")
fi
for check in "${checks[@]}"; do
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

# Hourly check that the REALITY handshake sites still work; a dead one takes
# its inbound down with it.
dest_snis="$REALITY_SNI${REALITY_SNI_B:+ $REALITY_SNI_B}"
echo "DEST_SNIS=\"$dest_snis\"" > "$STATE_DIR/dest-check.env"
install -m 0755 bin/dest-check.sh /usr/local/bin/setup-dest-check
install -m 0644 systemd/setup-dest-check.service systemd/setup-dest-check.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now setup-dest-check.timer >/dev/null 2>&1
echo "==> REALITY handshake sites"
# shellcheck disable=SC2086
if ! setup-dest-check $dest_snis; then
  echo "Warning: a REALITY handshake site is unusable; its inbound won't connect. Pick another." >&2
fi

# Client info.
if [[ -z "$PUBLIC_IP" ]]; then
  PUBLIC_IP="$(curl -4 -fsS --max-time 10 https://api.ipify.org || curl -4 -fsS --max-time 10 https://ifconfig.me)"
fi
# IPv6 often survives when the IPv4 is blocked, so print links for it too.
PUBLIC_IP6="$(curl -6 -fsS --max-time 5 https://api64.ipify.org 2>/dev/null || true)"
[[ "$PUBLIC_IP6" == *:* ]] || PUBLIC_IP6=

vless_link() { # host port sni name
  echo "vless://$VLESS_UUID@$1:$2?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$3&fp=chrome&pbk=$REALITY_PUBLIC_KEY&sid=$REALITY_SHORT_ID&type=tcp#$4"
}
hy2_link() { # host name
  # insecure=1 only skips CA checks for the self-signed cert; pinSHA256 still pins it.
  echo "hysteria2://$HY2_PASSWORD@$1:$HY2_PORT/?sni=$HY2_SNI&insecure=1&pinSHA256=$HY2_PIN#$2"
}

links=() # "label|link"
hosts=("$PUBLIC_IP|")
[[ -n "$PUBLIC_IP6" ]] && hosts+=("[$PUBLIC_IP6]|-v6")
for entry in "${hosts[@]}"; do
  host="${entry%|*}" suffix="${entry#*|}"
  links+=("VLESS + REALITY A ($REALITY_PORT/tcp, $REALITY_SNI)|$(vless_link "$host" "$REALITY_PORT" "$REALITY_SNI" "vps-reality-a$suffix")")
  if [[ -n "$REALITY_SNI_B" ]]; then
    links+=("VLESS + REALITY B ($REALITY_PORT_B/tcp, $REALITY_SNI_B)|$(vless_link "$host" "$REALITY_PORT_B" "$REALITY_SNI_B" "vps-reality-b$suffix")")
  fi
  if [[ "$HY2_ENABLED" == true ]]; then
    links+=("Hysteria2 ($HY2_PORT/udp; cert pinned by SHA-256)|$(hy2_link "$host" "vps-hysteria2$suffix")")
  fi
done

info="$STATE_DIR/client-info.txt"
(
  umask 077
  for entry in "${links[@]}"; do
    printf '%s:\n%s\n\n' "${entry%%|*}" "${entry#*|}"
  done > "$info"
  if [[ -n "$REALITY_SNI_B" ]]; then
    cat >> "$info" <<EOF
Put the A and B links in one fallback/urltest group in your client, so it moves
to B by itself if A's handshake site goes down.

EOF
  fi
)

if [[ "$DERP" == true ]]; then
  (umask 077; cat >> "$info" <<EOF
Tailscale DERP: add this region under "derpMap" > "Regions" in your tailnet
policy file (Access controls); merge regions from other VPSes alongside it.
Check with 'tailscale netcheck' on a client.
"derpMap": {
  "Regions": {
    "$DERP_REGION_ID": {
      "RegionID": $DERP_REGION_ID,
      "RegionCode": "vps$DERP_REGION_ID",
      "RegionName": "$DERP_DOMAIN",
      "Nodes": [
        {
          "Name": "${DERP_REGION_ID}a",
          "RegionID": $DERP_REGION_ID,
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
fi

echo
cat "$info"
if [[ -t 1 ]]; then
  for entry in "${links[@]}"; do
    echo "${entry%%|*}:"
    qrencode -t ansiutf8 "${entry#*|}"
  done
fi
echo
echo "Saved to $info"
