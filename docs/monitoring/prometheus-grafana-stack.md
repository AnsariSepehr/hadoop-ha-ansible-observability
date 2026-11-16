# Prometheus and Grafana on Docker Swarm

[← Documentation index](../README.md)

Monitoring runs on its own node, noc, outside the cluster it watches. If the cluster fails, the dashboards and their history stay available.

## Design

| Item            | Value                                                            |
|-----------------|------------------------------------------------------------------|
| Host            | noc, Docker in Swarm mode                                        |
| Stack file      | docker-compose.grafana.yml                                       |
| Network         | External overlay network elk, shared with the Elastic Stack      |
| Prometheus      | prom/prometheus:v3.5.5, 30-day retention                         |
| Grafana         | grafana/grafana:13.2.0, public name dashboards.example.corp      |
| Node exporter   | prom/node-exporter:v1.8.2, reports on the monitoring host itself |
| Persistent data | Bind mounts under /data/prometheus and /data/grafana             |

Persistent data sits on the host, not in anonymous volumes, so a stack redeploy does not lose history or dashboards.

## The stack file

The stack file is [`monitoring/stack/docker-compose.grafana.yml`](../../monitoring/stack/docker-compose.grafana.yml). It defines three services on the external overlay network `elk`: `prometheus`, `grafana` and `node-exporter`.

Two choices differ from a quick first deployment, on purpose:

- **Secrets are Swarm secrets.** The Grafana admin password and the Keycloak client secret are read from files (`GF_SECURITY_ADMIN_PASSWORD__FILE`, `GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET__FILE`). They never appear in the stack file, in `docker inspect` output or in git.
- **Names come from the environment.** The Grafana domain, the Keycloak host and the realm are `${...}` values loaded from `monitoring.env` at deploy time (see [`monitoring.env.example`](../../monitoring/stack/monitoring.env.example)).

```bash
printf '%s' '<value>' | docker secret create grafana_admin_password -
printf '%s' '<value>' | docker secret create grafana_oauth_client_secret -
set -a; . monitoring/stack/monitoring.env; set +a
docker stack deploy -c monitoring/stack/docker-compose.grafana.yml monitoring
```

The Grafana OIDC settings (PKCE, group-to-role mapping, sign-out redirect) follow the Grafana section of the companion SSO repository.

## What the Prometheus options do

| Option                             | Effect                                                                                        |
|------------------------------------|-----------------------------------------------------------------------------------------------|
| --storage.tsdb.retention.time=30d  | Metrics older than 30 days are deleted                                                        |
| --web.enable-lifecycle             | Allows a configuration reload with POST /-/reload, so editing prometheus.yml needs no restart |
| --web.enable-remote-write-receiver | Lets other systems push metrics into this Prometheus                                          |
| :ro mounts                         | The container cannot change its own configuration or the Kubernetes token                     |

## Global settings

Prometheus scrapes every 15 seconds and evaluates rules every 15 seconds. Every series carries the external label monitor="hadoop-noc". The Kubernetes jobs scrape every 30 seconds.

## Scrape jobs

| Job | Port | Source | What it collects |
|---|---|---|---|
| `prometheus` | 9090 | static | Prometheus itself |
| `node_exporter_monitoring_node` | 9100 | static (`node-exporter` service) | Host metrics of the monitoring node |
| `node_exporter_cluster` | 9100 | generated | CPU, memory, disk, network of every cluster node |
| `hadoop_namenode_jmx` | 7071 | generated | NameNode state, capacity, blocks |
| `hadoop_datanode_jmx` | 7072 | generated | DataNode I/O and capacity |
| `hadoop_journalnode_jmx` | 7079 | generated | Edit-log writes |
| `hadoop_zkfc_jmx` | 7078 | generated | Failover controller |
| `zookeeper_jmx` | 7075 | generated | Ensemble state and latency |
| `yarn_resourcemanager_jmx` | 7076 | generated | Queues, applications |
| `yarn_nodemanager_jmx` | 7077 | generated | Node health, containers |
| `mapred_historyserver_jmx` | 7080 | generated | JobHistory server JVM |
| `hive_hiveserver2_jmx` | 7081 | generated | Hive sessions and queries |
| `hive_metastore_jmx` | 7082 | generated | Metastore calls |
| `spark_history_jmx` | 7083 | generated | Spark History Server JVM |
| `kafka_jmx` | 7084 | generated | Broker and controller metrics |
| `zeppelin_jmx` | 7080 | generated | Zeppelin JVM |
| `zeppelin_web_metrics` | 8890 | static | Zeppelin web metrics |
| `mysqld_exporter_metastore` | 9104 | generated | Group Replication members of the Hive metastore (needs the [reference exporter](../../monitoring/exporters/mysqld-exporter/README.md)) |

A job whose inventory group is empty gets no target file and is simply skipped. Optional jobs for Kafka lag, cAdvisor, Airflow, Ranger, Trino and Kubernetes are in [`extra-jobs.example.yml`](../../monitoring/prometheus/extra-jobs.example.yml).

## Labels and generated targets

Cluster targets are **generated from the Ansible inventory** by [`gen-targets.py`](../../monitoring/prometheus/gen-targets.py). Every target carries three labels taken from the inventory: `hostname` (`node1` to `nodeN`), `role` (for example `namenode`) and `cluster`. Because one script produces them all, the labels cannot drift from the inventory, and adding a DataNode to the inventory adds its targets with one command.

```bash
python3 monitoring/prometheus/gen-targets.py \
  --inventory ansible/inventory/production.yml \
  --ports ansible/inventory/group_vars/all/20-ports.yml \
  --out monitoring/prometheus/file_sd --cluster <cluster-name>
```

Prometheus re-reads the generated `file_sd` files on its own, so a reload is only needed when `prometheus.yml` itself changes. Services that the Ansible project does not install (Kafka exporter, cAdvisor, Airflow, Ranger, Trino, Kubernetes) are in [`extra-jobs.example.yml`](../../monitoring/prometheus/extra-jobs.example.yml).

The Zeppelin web job sets `fallback_scrape_protocol: PrometheusText0.0.4`: Zeppelin's `/metrics` response is not served in a format Prometheus 3 accepts by default, so the job states which text format to assume.

## Reload and check

curl -X POST http://\<NOC_IP\>:9090/-/reload \# after editing prometheus.yml  
curl -s http://\<NOC_IP\>:9090/api/v1/targets \| grep -c '"health":"up"'

In the Prometheus UI, open Status, then Targets. Every job should list its targets as UP.
