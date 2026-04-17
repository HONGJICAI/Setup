#!/usr/bin/env bash
# Usage: ./install.sh
# Runs every step in order. Safe to re-run.
set -euo pipefail

cd "$(dirname "$0")"

./01-homebrew.sh
./02-brew-bundle.sh
./03-nvm-node.sh
./04-oh-my-zsh.sh
./05-shell-config.sh
./06-ghostty-config.sh

echo
echo "All done. Open a new terminal (or: exec zsh) to pick up shell changes."
