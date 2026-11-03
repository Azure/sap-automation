#!/bin/bash

set -e

PACKAGE_DIR="$HOME/tmp/ansible-offline-packages"
mkdir -p "$PACKAGE_DIR"
ZIP_DIR="$HOME/tmp/ansible-offline"
mkdir -p "$ZIP_DIR"


echo "Downloading Ansible collections..."
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ansible-galaxy collection download -r "${script_dir}/requirements.yml" -p "$PACKAGE_DIR/"
cp "${script_dir}/requirements.yml" "$PACKAGE_DIR/requirements.yml"

# Create a manifest
echo "Package contents:" > "$PACKAGE_DIR/MANIFEST.txt"
echo "Created: $(date -u)" >> "$PACKAGE_DIR/MANIFEST.txt"
echo "" >> "$PACKAGE_DIR/MANIFEST.txt"
echo "Collections:" >> "$PACKAGE_DIR/MANIFEST.txt"
ls -lh "$PACKAGE_DIR"/*.tar.gz 2>/dev/null >> "$PACKAGE_DIR/MANIFEST.txt" || true
echo "" >> "$PACKAGE_DIR/MANIFEST.txt"

echo ""
echo "Package ready: ${PACKAGE_DIR}/"
echo "Transfer this directory."

tar czf "$ZIP_DIR/ansible-offline-packages.tar.gz" "$PACKAGE_DIR/"
echo "Tarball package ready: ${ZIP_DIR}/ansible-offline-packages.tar.gz"
cat "$PACKAGE_DIR/MANIFEST.txt"
