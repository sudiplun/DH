#!/bin/bash
# exit if any command failed
set -euo pipefail

systemctl stop zabbix-agent

echo "Backup config files"
mkdir -p /root/zabbix-backup/
cp -r /etc/zabbix/ /root/zabbix-backup/

echo "Removing old zabbix packages"
sudo dnf remove zabbix-agent zabbix-release -y

echo "Disable Zabbix packages provided by EPEL"
cp /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.bak
sed -i '0,/^$/{s/^$/excludepkgs=zabbix*\n/;}'  /etc/yum.repos.d/epel.repo

# download new packages
echo "DETECT OS AND VERSION" # TODO: detect os and it's version 
# Function to detect OS and version
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
        ID=$ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VERSION=$(lsb_release -sr)
    elif [ -f /etc/redhat-release ]; then
        OS=$(cat /etc/redhat-release | cut -d' ' -f1)
        VERSION=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+' | cut -d'.' -f1)
    else
        OS=$(uname -s)
        VERSION=$(uname -r)
    fi
}
# Get the major version only
get_major_version() {
    local version=$1
    # Extract the major version number (before the first dot)
    echo $version | cut -d'.' -f1
}
# Detect the OS
detect_os
# Get the major version
MAJOR_VERSION=$(get_major_version $VERSION)
# Determine the correct repository URL based on OS and major version
install_zabbix_repo() {
    case $ID in
        almalinux)
            case $MAJOR_VERSION in
                8|8.*)
                    rpm -Uvh https://repo.zabbix.com/zabbix/7.0/alma/8/x86_64/zabbix-release-latest-7.0.el8.noarch.rpm
                    ;;
                9|9.*)
                    rpm -Uvh https://repo.zabbix.com/zabbix/7.0/alma/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm
                    ;;
                10|10.*)
                    rpm -Uvh https://repo.zabbix.com/zabbix/7.0/alma/10/x86_64/zabbix-release-latest-7.0.el10.noarch.rpm
                    ;;
                *)
                    echo "Unsupported AlmaLinux version: $MAJOR_VERSION"
                    exit 1
                    ;;
            esac
            ;;
        rocky)
            case $MAJOR_VERSION in
                8|8.*)
                    rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/8/x86_64/zabbix-release-latest-7.0.el8.noarch.rpm
                    ;;
                9|9.*)
                    rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm
                    ;;
                10|10.*)
                    rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/10/x86_64/zabbix-release-latest-7.0.el10.noarch.rpm
                    ;;
                *)
                    echo "Unsupported Rocky Linux version: $MAJOR_VERSION"
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "Unsupported OS: $OS ($ID)"
            exit 1
            ;;
    esac
}
# Install the appropriate Zabbix repository
install_zabbix_repo

dnf clean all

echo "INSTALL ZABBIX AGENT 7"
sudo dnf install zabbix-agent 
mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.bak19
mv /etc/zabbix/zabbix_agentd.conf.rpmsave /etc/zabbix/zabbix_agentd.conf

sed -i 's/10\.112\.1\.19/10\.112\.1\.16/g' /etc/zabbix/zabbix_agentd.conf

echo "ENABLE & RESTART AGENT"
systemctl enable zabbix-agent
systemctl start zabbix-agent

echo "LIVE LOG"
t
