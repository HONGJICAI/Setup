#!/usr/bin/env bash
# shellcheck source=../lib.sh
. "$(dirname "$0")/../lib.sh"

# BBR for TCP (REALITY), and larger UDP buffers so QUIC (Hysteria2) isn't
# capped by the small kernel defaults.
conf=/etc/sysctl.d/90-setup-network.conf
cat > "$conf" <<'EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
EOF
sysctl -q -p "$conf"

echo "  congestion control: $(sysctl -n net.ipv4.tcp_congestion_control)"
