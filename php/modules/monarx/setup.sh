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

echo "📥 Downloading required scripts..."

# Download scripts with basic error handling
if ! wget -q "${REPO_BASE}/${INSTALL_SCRIPT}" -O "$INSTALL_SCRIPT"; then
    echo "❌ Failed to download $INSTALL_SCRIPT" >&2
    exit 1
fi

if ! wget -q "${REPO_BASE}/${UPDATE_SCRIPT}" -O "$UPDATE_SCRIPT"; then
    echo "❌ Failed to download $UPDATE_SCRIPT" >&2
    exit 1
fi

# Make scripts executable
chmod +x "$INSTALL_SCRIPT" "$UPDATE_SCRIPT"

echo "🚀 Running installation script..."

# Ensure the install script can read user input from the terminal
if [ -w /dev/tty ]; then
    bash "./$INSTALL_SCRIPT" < /dev/tty
else
    echo "⚠️  Warning: No terminal available for input. Running non-interactively." >&2
    bash "./$INSTALL_SCRIPT"
fi

echo "📦 Moving update script to /usr/local/bin/"
sudo cp "$UPDATE_SCRIPT" /usr/local/bin/
sudo chmod +x "/usr/local/bin/$UPDATE_SCRIPT"

echo "✅ Monarx installation completed successfully."
echo "🧰 Update script available at: /usr/local/bin/$UPDATE_SCRIPT"
