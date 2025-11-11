## Activity Process and Steps

1. Pre-Upgrade Preparation

- Stop the Zabbix server and backup the database, configuration files, and /etc/zabbix directory.
- Migrate database from current vm to new vm.
- Verify database engine version ensure MariaDB 10.5.27
- Set global variable `log_bin_trust_function_creators = 1;` to allow function updates during schema migration.

2. Database Character Set Validation

- Check that all Zabbix tables use utf8mb4 encoding and utf8mb4_bin collation.
- Identify non-compliant tables using the INFORMATION_SCHEMA.TABLES query.
- Convert all Zabbix tables automatically using a generated ALTER TABLE script.

3. Schema Preparation

- Install the Zabbix 6 LTS SQL scripts package (zabbix-sql-scripts).
- Execute preparatory scripts double.sql and history_pk_prepare.sql against the Zabbix database.
- Confirm successful execution and verify no schema errors or warnings.

4. Data Migration

- Set @@max_statement_time=0 to disable statement timeout for large inserts.
- Migrate historical data from \*\_old tables into new history tables using INSERT IGNORE queries.
- Validate migrated rows count and confirm no duplicate or failed entries.

5. Application Upgrade

- Upgrade Zabbix server, frontend, and agent packages to the latest 7 LTS version.
- Restart Zabbix server — it will automatically trigger the internal database schema upgrade.
- Monitor server logs (/var/log/zabbix/zabbix_server.log) for upgrade completion confirmation.

5. Post-Upgrade Validation

- Check that the Zabbix frontend loads properly and all monitored hosts are reporting data.
- Validate history, triggers, and graphs to ensure data integrity.
- Reset `log_bin_trust_function_creators = 0;` and take a fresh backup post-migration.
