# Documentation index

Read in this order the first time.

1. [Overview](overview.md): what the platform is, what runs where, what is still open
2. [Architecture](architecture.md): how the pieces fit together, and why
3. [Prerequisites and masking conventions](prerequisites.md): servers, packages, placeholders
4. [The Ansible project](ansible-project.md): layout, variables, run order, safety rules
5. **Services**, in install order: [ZooKeeper](services/zookeeper.md) → [HDFS HA](services/hdfs.md) → [YARN](services/yarn.md) → [MySQL Group Replication](services/mysql-group-replication.md) → [Hive](services/hive.md) → [Spark](services/spark.md) → [Kafka](services/kafka.md) → [Zeppelin](services/zeppelin.md)
6. [Security and access](security-and-access.md)
7. **Monitoring**: [JMX exporters](monitoring/jmx-exporters.md) → [Prometheus and Grafana stack](monitoring/prometheus-grafana-stack.md) → [Grafana dashboards](monitoring/grafana-dashboards.md); exporter reference in [`../monitoring/exporters`](../monitoring/exporters/README.md)
8. **Operate**: [Verification and failover tests](verification-and-failover.md), [Troubleshooting](troubleshooting.md), [Known limitations](known-limitations.md), [Security checklist](security-checklist.md), [Reference](reference.md)
9. **Grow**: [Adding a service to monitoring](adding-a-service.md), [Roadmap](roadmap.md)
10. The same content as one Word document: [guide/](guide/)

Images live in [images/](images/). Put your Grafana screenshots in [images/dashboards/](images/dashboards/).
