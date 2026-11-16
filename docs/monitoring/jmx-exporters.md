# JMX exporters on every service

[← Documentation index](../README.md)

Every Java daemon in the cluster publishes its internal counters as Prometheus metrics. Nothing is installed besides one jar and one rules file per service, and no daemon code is changed.

## How it works

The Prometheus JMX Exporter 1.1.0 is loaded as a Java agent (-javaagent) when a daemon starts. It reads the JVM's JMX beans and serves them over HTTP on its own port. The jmx_exporter role copies the jar to /opt/jmx_exporter and writes a catch-all rules file (pattern: ".\*", lower-case names), so every bean is exported. Kafka and Zeppelin use their own rules files and install steps.

Each service has one fixed port, the same on every host. The port is set in 20-ports.yml under jmx_ports and passed to the daemon through its \*\_OPTS variable (for example HDFS_NAMENODE_OPTS). Hive is started through wrapper scripts that call java directly, because an agent cannot attach through an intermediate launcher script.

## JMX port map

| Service              | Port | Nodes               |
|----------------------|------|---------------------|
| NameNode             | 7071 | node1, node2        |
| DataNode             | 7072 | node1 to node5      |
| ZooKeeper            | 7075 | node1, node2, node3 |
| ResourceManager      | 7076 | node1, node2        |
| NodeManager          | 7077 | node1 to node5      |
| ZKFC                 | 7078 | node1, node2        |
| JournalNode          | 7079 | node1, node2, node3 |
| MapReduce JobHistory | 7080 | node1               |
| HiveServer2          | 7081 | node1               |
| Hive Metastore       | 7082 | node1               |
| Spark History Server | 7083 | node1               |
| Kafka                | 7084 | node1, node2, node3 |
| Zeppelin             | 7080 | node3               |

Port 7080 is used by two different services on two different hosts, which is allowed but easy to mix up when reading a dashboard.

## Metrics from outside the JVM

- **Node exporter** (port 9100) reports CPU, memory, disk and network for each host.

- **cAdvisor** (port 9338) reports Docker container usage on the Swarm nodes.

- **Kafka exporter** (port 9308) reports topics, partitions and consumer lag.

- **Airflow StatsD exporter** (port 9102) reports DAG and task counters.

- **MySQL exporter** (port 9104) reports the state of the separate Galera database pair. No exporter covers the Group Replication nodes of the Hive metastore.

These exporters are not installed by the Ansible project. Reference configuration for each is in [`monitoring/exporters`](../../monitoring/exporters/README.md).
