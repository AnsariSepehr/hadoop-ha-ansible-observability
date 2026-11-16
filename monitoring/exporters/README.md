# Exporters

Prometheus pulls metrics from small HTTP endpoints called exporters. This platform uses five kinds.

| Exporter | Port | Covers | Installed by | Folder |
|---|---|---|---|---|
| JMX Exporter (Java agent) 1.1.0 | 7071 to 7084 | Every Hadoop, ZooKeeper, Hive, Spark, Kafka and Zeppelin JVM | The Ansible `jmx_exporter`, `kafka` and `zeppelin` roles | [jmx-exporter](jmx-exporter) |
| node_exporter | 9100 | CPU, memory, disk and network of every host | Reference playbook in this folder | [node-exporter](node-exporter) |
| mysqld_exporter | 9104 | The three MySQL Group Replication members behind the Hive metastore | Reference unit in this folder | [mysqld-exporter](mysqld-exporter) |
| kafka_exporter | 9308 | Topics, partitions, consumer-group lag | Container, see folder | [kafka-exporter](kafka-exporter) |
| cAdvisor | 9338 | Docker containers on the Swarm hosts | Swarm global service, see folder | [cadvisor](cadvisor) |

The JMX exporter is installed by the project's own roles. The other four are **reference material**: they were not part of the original Ansible project, and anything marked *unverified* has not been run end to end.

Targets are not listed here. They are generated from the Ansible inventory by [`../prometheus/gen-targets.py`](../prometheus/gen-targets.py).
