# JMX Exporter

The [Prometheus JMX Exporter](https://github.com/prometheus/jmx_exporter) 1.1.0 runs **inside** each Java daemon as a `-javaagent`. It reads the JVM's JMX beans and serves them over HTTP. No daemon code changes.

## Installed by Ansible

```bash
cd ansible
scripts/cluster.sh install --tags jmx           # or run playbooks/monitoring/jmx-exporter/1.1.0/install.yml
```

| Piece | Location |
|---|---|
| Role | `ansible/roles/jmx_exporter` |
| Agent jar (offline) | `ansible/offline_packages/monitoring/jmx-exporter-1.1.0/jmx_prometheus_javaagent-1.1.0.jar` |
| Rules template | `ansible/roles/jmx_exporter/templates/jmx-config.yml.j2` |
| Ports | `ansible/inventory/group_vars/all/20-ports.yml`, key `jmx_ports` |
| Kafka rules | `ansible/roles/kafka/templates/kafka-jmx.yml.j2` |
| Zeppelin rules | `ansible/roles/zeppelin/templates/zeppelin-jmx.yml.j2` |

## Port map (same port on every host)

| Service | Port | Service | Port |
|---|---|---|---|
| NameNode | 7071 | HiveServer2 | 7081 |
| DataNode | 7072 | Hive Metastore | 7082 |
| ZooKeeper | 7075 | Spark History Server | 7083 |
| ResourceManager | 7076 | Kafka | 7084 |
| NodeManager | 7077 | Zeppelin | 7080 |
| ZKFC | 7078 | MapReduce JobHistory | 7080 |
| JournalNode | 7079 | | |

Zeppelin and the JobHistory server both use 7080, on different hosts.

## Rules

The default rules file exports every bean with lower-case names:

```yaml
lowercaseOutputName: true
lowercaseOutputLabelNames: true
rules:
  - pattern: ".*"
```

Because the pattern is a catch-all, **metric names depend on the bean names**. Open Grafana Explore, type a service prefix (for example `hadoop_`), and confirm the exact name before building a panel or an alert. For tighter, named metrics, replace the catch-all with specific `pattern` and `name` rules. See `jmx-config.example.yml`.

## Check one endpoint

```bash
curl -s http://<NODE1_IP>:7071/metrics | head
```
