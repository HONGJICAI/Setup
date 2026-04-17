#!/usr/bin/env bash
set -euo pipefail

echo "==> Homebrew"

if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools (approve the prompt)..."
  xcode-select --install || true
  until xcode-select -p >/dev/null 2>&1; do sleep 5; done
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
