# MySQL Group Replication for the Hive metastore

[← Documentation index](../README.md)

Hive keeps table definitions in a relational database called the metastore. If that database is lost, every table in the platform becomes unreadable, so it is replicated across three nodes.

## Design

| Item       | Value                                                                  |
|------------|------------------------------------------------------------------------|
| Version    | MySQL 8.0.42, installed from local RPMs                                |
| Nodes      | node3, node4, node5                                                    |
| Mode       | Group Replication, single primary: one node accepts writes, two follow |
| Ports      | 3306 for clients, 33061 for group communication                        |
| Group name | A UUID generated once and kept in .generated/mysql_gr_group_name       |
| Allow-list | The three node addresses as /32 entries                                |

A group of three tolerates one failed member and keeps a majority.

## Deployment flow

1.  Install the server from RPMs and initialise the data directory. A directory that already holds files is never wiped automatically.

2.  Write the Group Replication configuration and label the group port for SELinux.

3.  Restart mysqld so the plugin loads.

4.  If any member of an existing group is ONLINE, join it. If none is online and the node was never configured, bootstrap a new group. If none is online and the node was configured before, stop and ask for the explicit recovery playbook.

5.  Enable rejoin after restart.

The normal flow never runs RESET MASTER, so transaction history is kept.

## Recovery after a full outage

When all three members were down, bootstrap-after-outage.yml is used. The operator first compares GTID_EXECUTED on the members and names the node with the most complete history as the bootstrap host. Choosing a different node can lose transactions.

## Verify

mysql -e "SELECT MEMBER_HOST, MEMBER_STATE, MEMBER_ROLE FROM performance_schema.replication_group_members"

Expected: three rows in state ONLINE, one PRIMARY and two SECONDARY.

## Failover and the Hive connection

Hive connects to one MySQL address. After a primary change, either run hive/3.1.3/refresh-metastore-endpoint.yml or point hive_mysql_host_override at a MySQL Router or virtual address so Hive follows the primary automatically.
