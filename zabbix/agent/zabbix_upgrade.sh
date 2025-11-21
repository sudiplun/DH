#!/bin/bash

# exit if any command failed
set -euo pipefail

systemctl stop zabbix-agent

echo "BACKUP CONFIG FILES"
mkdir -p /root/zabbix-backup/
cp -r /etc/zabbix/ /root/zabbix-backup/

echo "REMOVING OLD ZABBIX PACKAGES"
dnf remove zabbix-agent zabbix-release -y

echo "DISABLE ZABBIX PACKAGES PROVIDED BY EPEL"
cp /etc/yum.repos.d/epel.repo /tmp/epel.repo
sed -i '0,/^$/{s/^$/excludepkgs=zabbix*\n/;}'  /etc/yum.repos.d/epel.repo

# download new packages
echo "ADDING ZABBIX AGENT REPO" 
#rpm -Uvh https://repo.zabbix.com/zabbix/7.0/alma/8/x86_64/zabbix-release-latest-7.0.el8.noarch.rpm # ALMA LINUX 8
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/alma/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm # ALMA LINUX 9
#rpm -Uvh https://repo.zabbix.com/zabbix/7.0/alma/10/x86_64/zabbix-release-latest-7.0.el10.noarch.rpm # ALMA LINUX 10
#rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/8/x86_64/zabbix-release-latest-7.0.el8.noarch.rpm # ROCKY LINUX 9
#rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm # ROCKY LINUX 9
#rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/10/x86_64/zabbix-release-latest-7.0.el10.noarch.rpm # ROCKY LINUX 10

dnf clean all

echo "INSTALL ZABBIX AGENT 7"
dnf install zabbix-agent 
mv /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf.bak

echo "ADDING AGENT CONFIG"
cat > /etc/zabbix/zabbix_agentd.conf << EOF
PidFile=/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=10.112.1.16
#ServerActive=127.0.0.1
#Hostname=Zabbix server
TLSConnect=cert
TLSAccept=cert
TLSCAFile=/etc/zabbix/certs/zabbix_ca.crt
TLSCertFile=/etc/zabbix/certs/zabbix_agent.crt
TLSKeyFile=/etc/zabbix/certs/zabbix_agent.key
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF

echo "ENABLE & RESTART AGENT"
systemctl enable zabbix-agent
systemctl start zabbix-agent

echo "LIVE LOG"
tail -f -n 30 /var/log/zabbix/zabbix_agentd.log
