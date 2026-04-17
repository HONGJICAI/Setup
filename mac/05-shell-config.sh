#!/usr/bin/env bash
set -euo pipefail

echo "==> ~/.zshrc (plugins, aliases, nvm)"

ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

# Enable OMZ plugins (only if the default plugins=(git) line is present
# and our plugins aren't already listed).
if ! grep -q 'zsh-autosuggestions' "$ZSHRC"; then
  sed -i.bak -E \
    's/^plugins=\(([^)]*)\)/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/' \
    "$ZSHRC"
fi

MARKER_BEGIN="# === mac-setup: managed block (do not edit between markers) ==="
MARKER_END="# === mac-setup: end ==="

if ! grep -qF "$MARKER_BEGIN" "$ZSHRC"; then
  cat >> "$ZSHRC" <<EOF

$MARKER_BEGIN
# nvm
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"

# aliases (these shadow built-ins in interactive shells only;
# scripts with their own shebang are unaffected)
alias ls='eza'
alias ll='eza -lah --git'
alias la='eza -la'
alias lt='eza --tree --level=2'
alias cat='bat --style=plain --paging=never'
alias find='fd'
alias grep='rg'
$MARKER_END
EOF
fi
