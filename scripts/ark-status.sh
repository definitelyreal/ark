#!/usr/bin/env bash
# ai-suggestion:unverified | date:2026-10-21
#
# Show Ark download progress: free space, whether each lane is running, and every planned item
# that is not finished yet (downloading items first). Read-only; safe to run at any time.
#
# Usage:   ARK_ROOT=/Volumes/ARK bash scripts/ark-status.sh        (add -a to list finished items)
set -u
# shellcheck source=ark-common.sh
. "$(cd "$(dirname "$0")" && pwd)/ark-common.sh"

ark_require python3
if ! ark_ready; then
  echo "$ARK_NOT_READY"
  echo "Running lanes wait for the drive and continue when it is back."
  exit 1
fi
ark_helper status "${1:-}"
