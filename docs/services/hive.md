# Hive

[← Documentation index](../README.md)

Hive 3.1.3 runs on node1 as two services: the Metastore, which answers questions about tables, and HiveServer2, which accepts SQL from clients over JDBC.

## Components

| Service            | Port  | Systemd unit   |
|--------------------|-------|----------------|
| Metastore (Thrift) | 9083  | hive-metastore |
| HiveServer2        | 10000 | hive-server2   |

## What the role does

1.  Requires Hadoop to be installed first and installs Hive on Java 8, the version Hive 3.1.x supports.

2.  Installs the MySQL JDBC driver (Connector/J 8.0.28).

3.  Replaces Hive's bundled Guava with the one Hadoop ships. Without this, Hive stops with NoSuchMethodError on Preconditions.

4.  Writes hive-site.xml, creates the metastore database and one account per Hive host on the MySQL primary.

5.  Initialises the schema on the first Hive host only. The project patches the stock schema script on the control node (normalising statements and checking every ALTER line ends with ;) before running schematool. A partly built database is dropped and rebuilt.

6.  Starts both services through wrapper scripts that launch java directly, so the JMX agent attaches to the real process.

## HDFS directories

/user/hive/warehouse (mode 1777), /user/hive and /tmp/hive are created in HDFS. Scratch space on local disk is /tmp/hive-hadoop.

## Verify

beeline -u jdbc:hive2://\<NODE1_IP\>:10000 -n hadoop -e "show databases"

hive_reinit_schema=true rebuilds the metastore and is destructive.
