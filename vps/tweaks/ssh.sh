#!/usr/bin/env bash
# shellcheck source=../lib.sh
. "$(dirname "$0")/../lib.sh"

# Key-only SSH. Skipped when no key is installed, so this can't lock you out.
if ! command -v sshd >/dev/null 2>&1; then
  echo "  sshd not installed, skipping"
  exit 0
fi

keys="$(cat /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys 2>/dev/null | grep -c '^[^#[:space:]]' || true)"
if (( keys == 0 )); then
  echo "Warning: no SSH authorized_keys found, leaving password login enabled." >&2
  exit 0
fi

# 00- so it wins: sshd keeps the first value it reads, and cloud images often
# ship a 50-cloud-init.conf that turns password login back on.
cat > /etc/ssh/sshd_config.d/00-setup.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
EOF
# sshd -t/-T need this; with socket activation (Ubuntu 24.04) it only exists once ssh.service has run.
mkdir -p /run/sshd
sshd -t
systemctl try-reload-or-restart ssh.service

echo "  password login disabled ($keys authorized key(s) found)"
