#!/usr/bin/env bash
# Generate Prometheus targets from the inventory, copy the monitoring configuration to the
# monitoring node and reload Prometheus without a restart.
#
#   MON_HOST=noc.example.corp MON_USER=root CLUSTER_NAME=<cluster> bash scripts/monitoring/deploy-config.sh
#
# Needs ssh/rsync access to the monitoring node and python3 with PyYAML locally.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
: "${MON_HOST:?set MON_HOST}"; MON_USER="${MON_USER:-root}"; DATA_DIR="${DATA_DIR:-/data}"
CLUSTER_NAME="${CLUSTER_NAME:-hadoop}"; PROM_URL="${PROM_URL:-http://localhost:9090}"

python3 monitoring/prometheus/gen-targets.py \
  --inventory ansible/inventory/production.yml \
  --ports ansible/inventory/group_vars/all/20-ports.yml \
  --out monitoring/prometheus/file_sd --cluster "$CLUSTER_NAME"

dest="${MON_USER}@${MON_HOST}:${DATA_DIR}"
rsync -av monitoring/prometheus/prometheus.yml "${dest}/prometheus/config/"
rsync -av --delete monitoring/prometheus/file_sd/ "${dest}/prometheus/config/file_sd/"
rsync -av --delete monitoring/prometheus/alerts/ "${dest}/prometheus/config/alerts/"
rsync -av monitoring/grafana/provisioning/ "${dest}/grafana/provisioning/"
rsync -av --delete --exclude .gitkeep monitoring/grafana/dashboards/ "${dest}/grafana/dashboards/"

ssh "${MON_USER}@${MON_HOST}" "curl -fsS -X POST ${PROM_URL}/-/reload && echo 'prometheus reloaded'"
