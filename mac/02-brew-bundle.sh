#!/usr/bin/env bash
set -euo pipefail

echo "==> Brewfile bundle"

cd "$(dirname "$0")"
brew bundle --file=./Brewfile
