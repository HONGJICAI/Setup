#!/usr/bin/env bash
set -euo pipefail

echo "==> Ghostty config"

CONFIG_DIR="$HOME/.config/ghostty"
CONFIG_FILE="$CONFIG_DIR/config"

mkdir -p "$CONFIG_DIR"

if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" <<'EOF'
font-family = JetBrainsMono Nerd Font
font-size = 14
window-padding-x = 8
window-padding-y = 8
EOF
fi
