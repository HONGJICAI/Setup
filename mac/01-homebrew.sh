#!/usr/bin/env bash
set -euo pipefail

echo "==> Homebrew"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools (approve the prompt)..."
  xcode-select --install || true
  # Poll for up to ~20 minutes. If the user dismissed the GUI prompt
  # we bail with a clear error rather than spin forever.
  for _ in $(seq 1 240); do
    xcode-select -p >/dev/null 2>&1 && break
    sleep 5
  done
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "Error: Xcode Command Line Tools are still not installed after 20 min." >&2
    echo "  Run 'xcode-select --install', complete the GUI prompt, then re-run." >&2
    exit 1
  fi
fi

if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ "$(uname -m)" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

eval "$("$BREW_PREFIX/bin/brew" shellenv)"

if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
  echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> "$HOME/.zprofile"
fi

brew update
