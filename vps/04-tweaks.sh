#!/usr/bin/env bash
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"

# Runs every tweaks/*.sh. Tweaks are independent, so one failing doesn't stop the rest.
failed=()
for tweak in "$VPS_DIR"/tweaks/*.sh; do
  name="$(basename "$tweak" .sh)"
  echo "==> Tweak: $name"
  if ! bash "$tweak"; then
    echo "Warning: $name failed" >&2
    failed+=("$name")
  fi
done

if (( ${#failed[@]} )); then
  echo "Error: tweaks failed: ${failed[*]}" >&2
  exit 1
fi
