# Dashboards

Put exported dashboard JSON here, one sub-folder per Grafana folder. Each sub-folder becomes a folder in Grafana (`foldersFromFilesStructure: true`).

| Folder | Suggested content |
|---|---|
| `00-overview` | Cluster overview: every job and its UP count |
| `10-nodes` | CPU, memory, disk, network per node |
| `20-hdfs` | Active NameNode, capacity, live DataNodes, missing blocks |
| `30-yarn` | Applications, queues, NodeManagers |
| `40-zookeeper-kafka` | Quorum health, broker metrics, consumer lag |
| `50-hive-spark-zeppelin` | HiveServer2, metastore, Spark History, Zeppelin |
| `60-databases` | MySQL Group Replication, other databases |
| `70-containers` | Docker Swarm services (cAdvisor) |

Workflow: `scripts/monitoring/export-grafana-dashboards.sh`, then `python3 scripts/monitoring/sanitize-dashboards.py`, then `bash scripts/tools/validate.sh`. Details in [docs/monitoring/grafana-dashboards.md](../../../docs/monitoring/grafana-dashboards.md).
