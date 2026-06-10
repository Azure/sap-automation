#!/bin/bash
# Create a swap file on the NVMe temp disk mount point.
# waagent cannot manage swap on NVMe VMs:
#   [ResourceDiskError] unable to detect disk topology
# so we create the swap file explicitly.
#
# Usage: create-nvme-swap.sh <swap_size_mb> [mount_point]

set -e

SWAP_SIZE_MB="${1:?Usage: $0 <swap_size_mb> [mount_point]}"
MOUNT_POINT="${2:-/mnt/resource}"
SWAP_FILE="${MOUNT_POINT}/swapfile"

if [ -f "$SWAP_FILE" ] && [ "$(stat -c%s "$SWAP_FILE" 2>/dev/null)" -eq "$((SWAP_SIZE_MB * 1024 * 1024))" ]; then
  echo "Swap file already exists with correct size"
  exit 0
fi

fallocate -l "${SWAP_SIZE_MB}M" "$SWAP_FILE"
chmod 0600 "$SWAP_FILE"
mkswap "$SWAP_FILE"
swapon "$SWAP_FILE"
echo "Swap file created and activated: ${SWAP_SIZE_MB}MB at ${SWAP_FILE}"
