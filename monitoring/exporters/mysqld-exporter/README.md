# mysqld_exporter for the Hive metastore database

The three MySQL 8.0.42 Group Replication members (inventory group `mysql`) hold the Hive metastore. **No exporter covers them by default**, so a lost secondary would go unnoticed. This folder closes that gap.

> **Unverified reference.** Not part of the original Ansible project.

## 1. Create a low-privilege account (on the primary)

See [`exporter-user.sql.example`](exporter-user.sql.example). Run it once; Group Replication copies it to the other members.

## 2. Install on node3, node4, node5

1. Place `mysqld_exporter-<version>.linux-amd64.tar.gz` under `ansible/offline_packages/monitoring/mysqld-exporter/` and unpack it to `/opt/mysqld_exporter`.
2. Create `/etc/mysqld_exporter.cnf` (mode 0600, owner `mysqld_exporter`):

```ini
[client]
user=exporter
password=<PASSWORD>
host=127.0.0.1
```

3. Install [`mysqld_exporter.service`](mysqld_exporter.service) and start it. The port is 9104.

## 3. What to watch

Group Replication member state is in `performance_schema.replication_group_members`. With the exporter, confirm the metric names in Grafana Explore (search `mysql_perf_schema_replication_group`) before alerting. The starter alert `MetastoreDatabaseMemberDown` only checks that each exporter answers.
