#!/bin/bash

# Script to update Monarx protection packages and restart services
# Supports: Debian/Ubuntu, RHEL/CentOS/Rocky/AlmaLinux

set -e  # Exit on any error

LOG_FILE="/var/log/monarx-update.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Monarx Update Script Started at $(date) ==="

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "ERROR: Cannot detect OS. /etc/os-release not found."
    exit 1
fi

echo "Detected OS: $OS $VER"

# Function to restart services
restart_services() {
    echo "Restarting web and PHP-FPM services..."

    # Common service names
    WEB_SERVICES=("nginx" "apache2" "httpd")
    FPM_SERVICES=("php8.2-fpm" "php8.1-fpm" "php8.0-fpm" "php7.4-fpm" "php-fpm")

    # Restart web server (whichever is active)
    for svc in "${WEB_SERVICES[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            echo "Restarting $svc..."
            systemctl restart "$svc"
        fi
    done

    # Restart PHP-FPM (whichever version is active)
    for svc in "${FPM_SERVICES[@]}"; do
        if systemctl is-active --quiet "$svc"; then
            echo "Restarting $svc..."
            systemctl restart "$svc"
        fi
    done

    echo "Services restarted."
}

# Update packages based on OS
case "$OS" in
    ubuntu|debian)
        echo "Updating APT packages..."
        apt-get update -y
        apt-get install --only-upgrade -y monarx-protect monarx-protect-autodetect monarx-agent
        ;;

    rhel|centos|rocky|almalinux|fedora)
        echo "Updating YUM/DNF packages..."
        if command -v dnf &> /dev/null; then
            dnf update -y monarx-protect monarx-protect-autodetect monarx-agent
        elif command -v yum &> /dev/null; then
            yum update -y monarx-protect monarx-protect-autodetect monarx-agent
        else
            echo "ERROR: Neither dnf nor yum found."
            exit 1
        fi
        ;;

    *)
        echo "ERROR: Unsupported OS: $OS"
        exit 1
        ;;
esac

# Verify packages are installed
echo "Verifying Monarx packages..."
if ! dpkg -l monarx-protect monarx-agent &>/dev/null 2>&1 && \
   ! rpm -q monarx-protect monarx-agent &>/dev/null 2>&1; then
    echo "WARNING: Monarx packages may not be installed or updated properly."
fi

# Restart services
restart_services

echo "=== Monarx Update Completed Successfully at $(date) ==="
echo "Log saved to: $LOG_FILE"
