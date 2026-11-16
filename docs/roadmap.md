# Roadmap

[← Documentation index](README.md)

Ordered by value for the effort. Nothing here is implemented yet.

| Area | Item |
|---|---|
| Alerting | Add Alertmanager to the Swarm stack; route to e-mail or chat; add service-specific rules (HDFS missing blocks, under-replicated blocks, YARN pending applications, Kafka consumer lag, replication-group size) after confirming metric names |
| Exporters | Turn node_exporter, mysqld_exporter, kafka_exporter and cAdvisor reference material into tested Ansible roles |
| High availability | Second Hive Metastore and HiveServer2 behind a virtual address; Prometheus in a pair with remote write |
| Dashboards | Commit all exported dashboards; add an SLO board (HDFS availability, YARN queue wait) |
| Security | CA-signed certificates for Hadoop web UIs; Keycloak group-based access to Zeppelin; TLS between Prometheus and the exporters |
| Testing | Molecule or Vagrant scenario that builds a three-node cluster and runs the failover tests automatically |
| CI | Run `promtool check config` and `check rules` in CI with a pinned Prometheus image |
