# Overview

[← Documentation index](README.md)

The platform runs HDFS, YARN, Hive, Spark, Kafka, Zeppelin and a MySQL metastore on five nodes. It is installed offline, in a fixed order, by one Ansible project whose only per-cluster file is the inventory. Every daemon exports Prometheus metrics, and a monitoring node on Docker Swarm scrapes them and shows them in Grafana.

**Why this project exists.** Hand-built Hadoop clusters drift: each node ends up slightly different and a rebuild cannot be reproduced. The goal was one repeatable, offline, parameterised installation with real high availability for the services that matter (HDFS, YARN, the Hive metastore database, Kafka) and one place to see the health of all of them.

**Why Ansible.** It needs no agent on the nodes, works over SSH, and the playbooks can be re-run safely. The project needs only ansible-core 2.14 or newer and the ansible.builtin modules, so nothing has to be downloaded on an isolated network.

## Status by component

| Component              | Version          | Role                                  | Runs on                                                                   | HA design                                         |
|------------------------|------------------|---------------------------------------|---------------------------------------------------------------------------|---------------------------------------------------|
| ZooKeeper              | 3.8.4            | Coordination, failover election       | node1, node2, node3                                                       | 3-member quorum                                   |
| HDFS                   | Hadoop 3.3.6     | Distributed storage                   | NameNodes node1, node2; DataNodes node1 to node5                          | Active/Standby NameNode, ZKFC, 3 JournalNodes     |
| YARN and MapReduce     | Hadoop 3.3.6     | Resource scheduling, job history      | ResourceManagers node1, node2; NodeManagers node1 to node5; history node1 | Two ResourceManagers                              |
| MySQL                  | 8.0.42           | Hive Metastore database               | node3, node4, node5                                                       | Group Replication, single primary                 |
| Hive                   | 3.1.3            | Metastore and HiveServer2             | node1                                                                     | Single instance, metastore database is replicated |
| Spark                  | 3.5.4            | Batch engine on YARN, History Server  | clients node1, node2; history node1                                       | Depends on YARN                                   |
| Kafka                  | 4.0.0            | Event streaming, KRaft (no ZooKeeper) | node1, node2, node3                                                       | 3 combined broker/controller nodes                |
| Zeppelin               | 0.12.1           | Notebook UI                           | node3                                                                     | Single instance                                   |
| JMX Exporter           | 1.1.0            | Prometheus metrics from every JVM     | All service nodes                                                         | Not applicable                                    |
| Prometheus and Grafana | 3.5.5 and 13.2.0 | Metrics and dashboards                | Monitoring node (Docker Swarm)                                            | Single instance, 30-day retention                 |

## What is still open

- The Ansible project was checked statically (YAML, templates, safety assertions). Live failover results have to be recorded by the operator: see [Verification and failover tests](verification-and-failover.md).
- Alerting is a starter set with no Alertmanager. The reference exporters (node, MySQL, Kafka, cAdvisor) are *unverified*. See [Known limitations](known-limitations.md).
- Before you publish your own fork, work through the [security checklist](security-checklist.md).
