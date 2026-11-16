# Changelog

## 0.1.0: initial release
- Ansible project for a five-node HA Hadoop platform (ZooKeeper, HDFS HA, YARN HA, MySQL Group Replication, Hive, Spark, Kafka KRaft, Zeppelin), sanitized for publication
- Prometheus configuration whose targets are generated from the Ansible inventory (`gen-targets.py`)
- Docker Swarm monitoring stack (Prometheus, Grafana with Keycloak sign-in, node-exporter) using Swarm secrets
- Starter alert rules, Grafana provisioning, dashboard export and sanitize tools
- Reference configuration for node_exporter, mysqld_exporter, kafka_exporter and cAdvisor (unverified)
- Documentation: architecture, one page per service, monitoring, failover tests, troubleshooting, limitations, security checklist, and the original Word guide
- Offline validation script and CI
