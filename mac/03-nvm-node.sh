#!/usr/bin/env bash
set -euo pipefail

echo "==> nvm + Node LTS"

export NVM_DIR="$HOME/.nvm"

if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
fi

# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"

nvm install --lts
nvm alias default 'lts/*'
