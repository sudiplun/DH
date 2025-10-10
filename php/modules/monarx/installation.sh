#!/bin/bash
set -e

# -----------------------------
# Monarx Install + Auto Update Script
# -----------------------------

# Prompt user for required variables
read -p "Enter Monarx Client ID: " CLIENT_ID
read -p "Enter Monarx Client Secret: " CLIENT_SECRET
read -p "Enter Host ID: " HOST_ID

# Variables
MONARX_PACKAGE="monarx-protect-autodetect"
AGENT_PACKAGE="monarx-agent"
CONFIG_FILE="/etc/monarx-agent.conf"
UPDATE_SCRIPT="/usr/local/bin/update-monarx.sh"
CRON_FILE="/etc/cron.d/monarx-auto-update"

# Detect OS Family
if [ -f /etc/redhat-release ]; then
    OS_FAMILY="RedHat"
elif [ -f /etc/debian_version ]; then
    OS_FAMILY="Debian"
else
    echo "Unsupported OS family. Exiting..."
    exit 1
fi

echo "Detected OS Family: $OS_FAMILY"

### ----------------------------
### Install Packages
### ----------------------------
if [[ "$OS_FAMILY" == "RedHat" ]]; then
    echo "Setting up Monarx repository for RedHat-based systems..."
    curl -fsS https://repository.monarx.com/repository/monarx-yum/monarx.repo -o /etc/yum.repos.d/monarx.repo
    rpm --import https://repository.monarx.com/repository/monarx/publickey/monarxpub.gpg

    echo "Installing Monarx package..."
    yum install -y "$MONARX_PACKAGE"

elif [[ "$OS_FAMILY" == "Debian" ]]; then
    echo "Installing required packages: lsb-release, curl, gnupg"
    apt-get update -y
    apt-get install -y lsb-release curl gnupg

    DISTRO_CODENAME=$(lsb_release -sc)
    echo "Detected distribution codename: $DISTRO_CODENAME"

    echo "Importing Monarx GPG key..."
    curl -fsS https://repository.monarx.com/repository/monarx/publickey/monarxpub.gpg -o /etc/apt/trusted.gpg.d/monarx.asc

    if [[ "$(lsb_release -is)" == "Ubuntu" ]]; then
        echo "Adding Monarx Ubuntu repository..."
        echo "deb [arch=amd64] https://repository.monarx.com/repository/ubuntu-${DISTRO_CODENAME}/ ${DISTRO_CODENAME} main" \
            > /etc/apt/sources.list.d/monarx.list
    else
        echo "Adding Monarx Debian repository..."
        echo "deb [arch=amd64] https://repository.monarx.com/repository/debian-${DISTRO_CODENAME}/ ${DISTRO_CODENAME} main" \
            > /etc/apt/sources.list.d/monarx.list
    fi

    echo "Updating apt cache..."
    apt-get update -y
    echo "Installing Monarx package..."
    apt-get install -y "$MONARX_PACKAGE"
fi

### ----------------------------
### Configure Monarx Agent
### ----------------------------
echo "Creating Monarx Agent configuration..."
mkdir -p "$(dirname "$CONFIG_FILE")"
cat > "$CONFIG_FILE" <<EOF
client_id     = ${CLIENT_ID}
client_secret = ${CLIENT_SECRET}
host_id       = ${HOST_ID}
EOF

chmod 600 "$CONFIG_FILE"
chown root:root "$CONFIG_FILE"

### ----------------------------
### Enable & Restart Service
### ----------------------------
echo "Starting and enabling Monarx Agent service..."
systemctl daemon-reload || true
systemctl enable monarx-agent
systemctl restart monarx-agent

### ----------------------------
### Create Auto-Update Script
### ----------------------------
echo "Creating Monarx auto-update script at $UPDATE_SCRIPT"

cat > "$UPDATE_SCRIPT" <<'EOF'
#!/bin/bash
set -e
LOGFILE="/var/log/monarx-auto-update.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting Monarx auto-update..." >> "$LOGFILE"

if [ -f /etc/redhat-release ]; then
    echo "Detected RedHat-based system." >> "$LOGFILE"
    yum clean all -y >> "$LOGFILE" 2>&1
    yum update -y monarx-protect monarx-protect-autodetect >> "$LOGFILE" 2>&1
    yum update -y monarx-agent >> "$LOGFILE" 2>&1

elif [ -f /etc/debian_version ]; then
    echo "Detected Debian-based system." >> "$LOGFILE"
    apt-get update -y >> "$LOGFILE" 2>&1
    apt-get install -y monarx-protect monarx-protect-autodetect >> "$LOGFILE" 2>&1
    apt-get install -y monarx-agent >> "$LOGFILE" 2>&1
fi

echo "[$DATE] Restarting web server and PHP-FPM..." >> "$LOGFILE"
# Restart common services safely if they exist
systemctl reload apache2 2>/dev/null || systemctl reload httpd 2>/dev/null || true
systemctl reload php-fpm 2>/dev/null || systemctl reload php8.1-fpm 2>/dev/null || true

# Kill old PHP processes (FPM or suPHP)
pkill -f "php" || true

echo "[$DATE] Monarx auto-update completed successfully." >> "$LOGFILE"
EOF

chmod +x "$UPDATE_SCRIPT"

### ----------------------------
### Add Cron Job
### ----------------------------
echo "Adding weekly cron job for Monarx auto-update..."

cat > "$CRON_FILE" <<EOF
# Run Monarx auto-update every Sunday at 3:00 AM
0 3 * * 0 root $UPDATE_SCRIPT
EOF

chmod 644 "$CRON_FILE"

echo "✅ Monarx installation complete."
echo "🕒 Auto-update scheduled weekly at 3:00 AM every Sunday."
echo "📜 Log file: /var/log/monarx-auto-update.log"
