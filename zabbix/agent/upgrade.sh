#!/bin/bash
# exit if any command failed
set -euo pipefail
systemctl stop zabbix-agent
echo "Backup config files"
mkdir -p /root/zabbix-backup/
cp /etc/zabbix/ /root/zabbix-backup/
echo "Removing old zabbix packages"
sudo dnf remove zabbix-agent zabbix-release -y
# download new packages
echo "DETECT OS AND VERSION" # TODO: detect os and it's version

#rpm -Uvh https://repo.zabbix.com/zabbix/7.0/alma/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm # ALMA LINUX 9
#rpm -Uvh https://repo.zabbix.com/zabbix/7.0/alma/10/x86_64/zabbix-release-latest-7.0.el10.noarch.rpm # ALMA LINUX 10
# rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm # ROCKY LINUX 9
# rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/10/x86_64/zabbix-release-latest-7.0.el10.noarch.rpm # ROCKY LINUX 10

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
tail -f -n 30 /var/log/zabbix/zabbix_agentd.log
