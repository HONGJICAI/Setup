#!/usr/bin/env bash
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

echo "==> Base packages"

# Lock timeout: a fresh VPS often runs unattended-upgrades right after boot.
apt-get -o DPkg::Lock::Timeout=300 update
apt_install ca-certificates curl gettext-base iproute2 openssl qrencode ufw unattended-upgrades
