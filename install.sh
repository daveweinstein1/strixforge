#!/bin/bash
# Strixforge Bootstrap Script
# This script downloads and runs the Strixforge installer.
#
# Usage: curl -fsSL https://bit.ly/strixforge | sudo bash
#
# What this script does:
# 1. Downloads the latest strixforge binary from GitHub Releases
# 2. Makes it executable
# 3. Runs it with any arguments passed to this script
# 4. Cleans up the temporary file

set -euo pipefail

REPO="daveweinstein1/strixforge"
BINARY="strixforge"
TMP_FILE="/tmp/${BINARY}"

echo "Strixforge Bootstrap"
echo "===================="
echo ""
echo "Downloading latest release from GitHub..."

# Download the binary
curl -fsSL "https://github.com/${REPO}/releases/latest/download/${BINARY}" -o "${TMP_FILE}"

# Make executable
chmod +x "${TMP_FILE}"

echo "Starting installer..."
echo ""

# Run the installer with any passed arguments
"${TMP_FILE}" "$@"

# Cleanup
rm -f "${TMP_FILE}"
