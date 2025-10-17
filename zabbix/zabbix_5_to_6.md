# Upgrade zabbix 5 LTS to 6 LTS

zabbix upgrade means the zabbix upgrade and setup with compatiable databases server (like mariadb)
https://www.zabbix.com/documentation/6.0/en/manual/installation/requirements#required-software

---

### to upgrade zabbix 5 to 6 LTS

- stop zabbix server (highly recommend)
  `systemctl stop zaabix-server zabbix-agent httpd`
- backup or dump sql database
  `mysqldump -u root -p zabbix > zabbix_backup.sql`
- Remove older version of mariadb and upgrade to required compatiable version for zabbix 6 LTS (i.e 10.5 +)
  `dnf remvoe mariadb-server mariadb`

Now upgrade mariadb v5.5 to 10.11 lts
Create a new repository file: sudo vi /etc/yum.repos.d/MariaDB.repo.

```bash
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.11/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
```

`dnf install MariaDB-server MariaDB-client`

- secure database
  `sudo mysql_secure_installation`

---

Refernce: https://www.zabbix.com/download?zabbix=6.0&os_distribution=rocky_linux&os_version=8&components=server_frontend_agent&db=mysql&ws=apache

create `zabbix` database and import dump file to it.

```sql
CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost' IDENTIFIED BY 'password_new';
set global log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
QUIT;
```

`zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix `

```bash
mysql -uroot -p
1234
mysql> set global log_bin_trust_function_creators = 0;
mysql> quit;
```

---

# Migration

Refernce: https://www.zabbix.com/documentation/6.0/en/manual/appendix/install/db_primary_keys#post-migration

Rename old tables and create new tables by running history_pk_prepare.sql.
`mysql -u zabbix -p zabbix < /usr/share/zabbix-sql-scripts/mysql/history_pk_prepare.sql`

Migration with stopped server

- `mysql -u root -p`
- `USE zabbix;`

```sql
SET @@max_execution_time=0;

       INSERT IGNORE INTO history SELECT * FROM history_old;
       INSERT IGNORE INTO history_uint SELECT * FROM history_uint_old;
       INSERT IGNORE INTO history_str SELECT * FROM history_str_old;
       INSERT IGNORE INTO history_log SELECT * FROM history_log_old;
       INSERT IGNORE INTO history_text SELECT * FROM history_text_old;
```

---

# Post-migration

For all databases, once the migration is completed, do the following:
Verify that everything works as expected.
Drop old tables:

```sql
DROP TABLE history_old; DROP TABLE history_uint_old; DROP TABLE history_str_old; DROP TABLE history_log_old; DROP TABLE history_text_old;
```
