# Monitoring

Prometheus, Grafana and the exporters that watch the Hadoop platform. Everything here runs on a separate monitoring node (Docker Swarm), outside the cluster it observes.

| Folder | Content |
|---|---|
| [`stack/`](stack) | Docker Swarm stack: Prometheus 3.5.5, Grafana 13.2.0 with Keycloak sign-in, node-exporter. Secrets are Swarm secrets |
| [`prometheus/`](prometheus) | `prometheus.yml`, the inventory-driven target generator `gen-targets.py`, optional jobs, starter alert rules |
| [`grafana/`](grafana) | Provisioning files and the dashboard JSON folders (one sub-folder per Grafana folder) |
| [`exporters/`](exporters) | JMX exporter, node_exporter, mysqld_exporter, kafka_exporter, cAdvisor |

## Deploy in four steps

```bash
# 1. secrets and names
printf '%s' '<value>' | docker secret create grafana_admin_password -
printf '%s' '<value>' | docker secret create grafana_oauth_client_secret -
cp monitoring/stack/monitoring.env.example monitoring/stack/monitoring.env && vi monitoring/stack/monitoring.env

# 2. generate targets from the Ansible inventory, copy files, reload Prometheus
MON_HOST=<NOC_HOST> CLUSTER_NAME=<cluster-name> bash scripts/monitoring/deploy-config.sh

# 3. start the stack on the Swarm manager (first time only; later runs just reload)
set -a; . monitoring/stack/monitoring.env; set +a
docker stack deploy -c monitoring/stack/docker-compose.grafana.yml monitoring

# 4. check
curl -s http://<NOC_IP>:9090/api/v1/targets | grep -c '"health":"up"'
```

Full explanation: [docs/monitoring](../docs/monitoring/prometheus-grafana-stack.md).

## Dashboards

Export them from your Grafana with `scripts/monitoring/export-grafana-dashboards.sh`, sanitize with `scripts/monitoring/sanitize-dashboards.py`, and commit them under [`grafana/dashboards/`](grafana/dashboards). See [docs/monitoring/grafana-dashboards.md](../docs/monitoring/grafana-dashboards.md).
