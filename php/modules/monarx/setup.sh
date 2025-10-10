#!/bin/bash
set -euo pipefail

# Variables
MONARX_DIRECTORY="$HOME/monarx-protection-install"
INSTALL_SCRIPT="installation.sh"
UPDATE_SCRIPT="update-monarx.sh"
REPO_BASE="https://raw.githubusercontent.com/sudiplun/DH/main/php/modules/monarx"

# Create working directory
mkdir -p "$MONARX_DIRECTORY"
cd "$MONARX_DIRECTORY"

echo "📥 Cloning required scripts..."
wget -q --show-progress "${REPO_BASE}/${INSTALL_SCRIPT}" -O "$INSTALL_SCRIPT"
wget -q --show-progress "${REPO_BASE}/${UPDATE_SCRIPT}" -O "$UPDATE_SCRIPT"

# Make sure the scripts are executable
chmod +x "$INSTALL_SCRIPT" "$UPDATE_SCRIPT"

echo "🚀 Running installation script..."
bash "$MONARX_DIRECTORY/$INSTALL_SCRIPT"

echo -e "📦 Moving update script to /usr/local/bin/"
sudo cp "$MONARX_DIRECTORY/$UPDATE_SCRIPT" /usr/local/bin/
sudo chmod +x /usr/local/bin/$UPDATE_SCRIPT

echo "✅ Monarx installation completed successfully."
echo "🧰 Update script available at: /usr/local/bin/$UPDATE_SCRIPT"
