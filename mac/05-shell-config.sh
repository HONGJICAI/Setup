#!/usr/bin/env bash
set -euo pipefail

echo "==> ~/.zshrc (plugins, aliases, nvm)"

ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

# Enable oh-my-zsh plugins. If a plugins=(...) line exists we extend it;
# otherwise we prepend one (oh-my-zsh must read `plugins` before its
# `source $ZSH/oh-my-zsh.sh` line, so appending would not activate them).
# Idempotency: look for zsh-autosuggestions already inside a plugins=() line.
if ! grep -qE '^plugins=\([^)]*zsh-autosuggestions' "$ZSHRC"; then
  if grep -qE '^plugins=\(' "$ZSHRC"; then
    sed -i.bak -E \
      's/^plugins=\(([^)]*)\)/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting)/' \
      "$ZSHRC"
    rm -f "$ZSHRC.bak"
  else
    tmp=$(mktemp)
    printf 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)\n' > "$tmp"
    cat "$ZSHRC" >> "$tmp"
    mv "$tmp" "$ZSHRC"
  fi
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

# eza is close enough to ls that these aliases are safe. bat is
# intentionally NOT aliased over cat because its flags differ enough
# to surprise when pasting from docs. Use \`bat\` directly.
alias ls='eza'
alias ll='eza -lah --git'
alias la='eza -la'
alias lt='eza --tree --level=2'
$MARKER_END
EOF
fi
