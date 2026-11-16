# Grafana dashboards

[← Documentation index](../README.md)

The dashboards were built in Grafana on top of the Prometheus data source. This section describes how they are stored and what each board is for. Put the exported JSON files in `monitoring/grafana/dashboards/` and the screenshots in `docs/images/dashboards/`.

## How dashboards are stored

| Path in the repository | Path on the monitoring node | Content |
|---|---|---|
| `monitoring/grafana/provisioning/datasources/prometheus.yml` | `/data/grafana/provisioning/datasources/` | The Prometheus data source, uid `prometheus` |
| `monitoring/grafana/provisioning/dashboards/provider.yml` | `/data/grafana/provisioning/dashboards/` | Tells Grafana to load JSON files from a folder |
| `monitoring/grafana/dashboards/<folder>/*.json` | `/data/grafana/dashboards/<folder>/` | One JSON file per dashboard; each sub-folder becomes a Grafana folder |
| (not in git) | `/data/grafana/data` | Grafana database: users, preferences |

Dashboards are code. Export them from the running Grafana, sanitize them, commit them, and a rebuilt Grafana comes back with the same boards.

### Export and publish workflow

1. In Grafana create a service-account token with the Viewer role.
2. Export everything:

```bash
export GRAFANA_URL=https://dashboards.example.corp
export GRAFANA_TOKEN=<token>             # never commit it
bash scripts/monitoring/export-grafana-dashboards.sh
```

3. Mask the files and point every panel at the provisioned data source:

```bash
python3 scripts/monitoring/sanitize-dashboards.py
```

4. Run `bash scripts/tools/validate.sh`, commit, then deploy with `bash scripts/monitoring/deploy-config.sh`.

The sanitizer sets `id` to null, drops `version`, rewrites the data source to `uid: prometheus`, masks private IPv4 addresses and any term listed in your git-ignored `.forbidden-terms`, and warns about anything that looks like a secret.

## Dashboard set

| Dashboard                | Question it answers                                                   | Main jobs used                                                   |
|--------------------------|-----------------------------------------------------------------------|------------------------------------------------------------------|
| Cluster overview         | Is everything up, and which service is not?                           | All up series                                                    |
| Nodes                    | Is any host short of CPU, memory, disk or network?                    | node_exporter_hadoop                                             |
| HDFS                     | Which NameNode is active, how full is HDFS, are blocks missing?       | hadoop_namenode_jmx, hadoop_datanode_jmx, hadoop_journalnode_jmx |
| YARN                     | How many applications run or wait, how many NodeManagers are healthy? | yarn_resourcemanager_jmx, yarn_nodemanager_jmx                   |
| ZooKeeper and Kafka      | Is the quorum healthy, is any consumer behind?                        | zookeeper_jmx, kafka_jmx, kafka_exporter                         |
| Hive, Spark and Zeppelin | Are the query and notebook services responsive?                       | hive\_\*, spark_history_server_jmx, zeppelin\_\*                 |
| Database                 | Are the replicas in sync?                                             | mariadb_galera, node_exporter_db                                 |
| Containers               | Which Swarm service uses the most memory or CPU?                      | cadvisor_docker                                                  |

The titles above are a suggested set. Use your own board names in the final document.

## Useful queries

Metric names produced by the JMX exporter follow the rules file, so confirm the exact name in Grafana Explore before building a panel. The queries below use standard series that do not depend on those rules.

\# Targets that are down, per job  
sum by (job) (up == 0)  
  
\# CPU use per node, percent  
100 - avg by (hostname) (rate(node_cpu_seconds_total{mode="idle", job="node_exporter_hadoop"}\[5m\])) \* 100  
  
\# Memory available per node, percent  
100 \* node_memory_MemAvailable_bytes{job="node_exporter_hadoop"} / node_memory_MemTotal_bytes{job="node_exporter_hadoop"}  
  
\# Free space on the data disk, percent  
100 \* node_filesystem_avail_bytes{mountpoint="/data"} / node_filesystem_size_bytes{mountpoint="/data"}

## Screenshots to add

| Figure    | What to capture                                       |
|-----------|-------------------------------------------------------|
| Figure 5  | Cluster overview: every job and its UP count          |
| Figure 6  | HDFS board: active NameNode, capacity, live DataNodes |
| Figure 7  | YARN board: running applications and NodeManagers     |
| Figure 8  | Nodes board: CPU, memory and disk for the five nodes  |
| Figure 9  | Prometheus Status, Targets page with all jobs UP      |
| Figure 10 | Grafana sign-in page showing the Keycloak button      |

> **Placeholder:** insert each screenshot under its figure number. Blur host names, addresses and user names before publishing.

## Access

Sign-in goes through Keycloak. Members of grafana-admins can edit dashboards and data sources, and all other users are viewers. The local admin account exists as a fallback and its password is currently set in the stack file, so rotate it and move it to a secret ([section 20: Security checklist before publishing](../security-checklist.md)).
