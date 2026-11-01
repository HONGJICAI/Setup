#!/usr/bin/env bash
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

echo "==> Docker"

if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  # Official repo, per https://docs.docker.com/engine/install/ubuntu/ (same layout for Debian).
  # shellcheck source=/dev/null
  . /etc/os-release
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/$ID/gpg" -o /etc/apt/keyrings/docker.asc
  chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc]" \
    "https://download.docker.com/linux/$ID $VERSION_CODENAME stable" > /etc/apt/sources.list.d/docker.list
  apt-get -o DPkg::Lock::Timeout=300 update
  apt_install docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

systemctl enable --now docker
docker --version
docker compose version
