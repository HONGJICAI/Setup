#!/usr/bin/env bash
# Usage: sudo ./install.sh
# Runs every step in order. Safe to re-run: secrets are generated once and kept.
set -euo pipefail

cd "$(dirname "$0")"

./01-base.sh
./02-docker.sh
./03-tailscale.sh
./04-tweaks.sh
./05-services.sh
