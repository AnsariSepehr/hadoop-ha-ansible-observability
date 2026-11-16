# Known limitations and open work

[← Documentation index](README.md)

An honest list. Items marked *unverified* have not been run end to end.

## Not finished or not highly available

- **Single instances.** Hive, Zeppelin, the JobHistory server, the Spark History Server, Prometheus and Grafana each run once. Their data is protected (replicated metastore database, HDFS storage, persistent bind mounts) but the service itself is not.
- **Starter alert rules only.** [`monitoring/prometheus/alerts/hadoop-platform.yml`](../monitoring/prometheus/alerts/hadoop-platform.yml) covers availability and host resources. There is no Alertmanager in the stack, so nothing is delivered yet. Service-specific rules need metric names confirmed in Grafana Explore first.
- **Self-signed certificates** protect the HDFS web interfaces. Browsers warn and clients must trust the certificates. Use `hadoop_ssl_mode: custom` with a company CA for production.
- **The Kubernetes jobs** in `extra-jobs.example.yml` use a CA file. The original deployment skipped TLS verification, which is not recommended.
- **The Hive metastore database exporter** is a reference ([mysqld-exporter](../monitoring/exporters/mysqld-exporter/README.md)) and is *unverified*.
- **node_exporter, kafka_exporter and cAdvisor** are reference material, not Ansible roles in the original project.

## Prometheus labels and the Ansible inventory

The original, hand-written `prometheus.yml` disagreed with the inventory in several ways: three naming schemes for the same hosts (`node1`, `master/worker1`, `ceph1`), a wrong host label on the Zeppelin job, incomplete `mysql` and `roles` labels, and two exporters (ZKFC on 7078 and the JobHistory server on 7080) that were running but never scraped.

**This repository removes the cause.** Cluster targets are generated from the inventory by [`gen-targets.py`](../monitoring/prometheus/gen-targets.py), so names and roles cannot drift, and the ZKFC and JobHistory jobs are included. If you keep a hand-written file instead, check it against the inventory.

One naming detail remains: Zeppelin and the JobHistory server both use JMX port 7080, on different hosts. The `role` label tells them apart.

The Zeppelin role default for `zeppelin_port` is 8080, which ZooKeeper's admin server also uses on node3. The inventory value 8890 avoids the clash. Keep it.

## Stated but not fully verified

- The Ansible project was validated statically: all YAML and Jinja files parse, import targets exist and the safety assertions pass. Syntax checks, template rendering and live failover were not run in the original build environment. [Verification and failover tests](verification-and-failover.md) holds the tests to run.
- Failover times of 15 to 30 seconds are the expected range, not a measured result.
- `scripts/monitoring/deploy-config.sh` and the dashboard export script were checked for syntax and, where possible, with test fixtures, but were *not run against a live Grafana or monitoring node*.
