#!/usr/bin/env bash
# Export every dashboard from a running Grafana into monitoring/grafana/dashboards/<folder>/<title>.json
#
#   export GRAFANA_URL=https://dashboards.example.corp
#   export GRAFANA_TOKEN=<service-account token with Viewer role>   # never commit it
#   bash scripts/monitoring/export-grafana-dashboards.sh
#
# Then run scripts/monitoring/sanitize-dashboards.py before committing.
set -euo pipefail
: "${GRAFANA_URL:?set GRAFANA_URL}"; : "${GRAFANA_TOKEN:?set GRAFANA_TOKEN}"
OUT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/monitoring/grafana/dashboards"
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
auth=(-H "Authorization: Bearer ${GRAFANA_TOKEN}")
slug() { printf '%s' "$1" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9._-'; }

curl -fsS "${auth[@]}" "${GRAFANA_URL}/api/search?type=dash-db&limit=5000" | jq -c '.[]' | while read -r row; do
  uid=$(jq -r .uid <<<"$row"); title=$(jq -r .title <<<"$row"); folder=$(jq -r '.folderTitle // "General"' <<<"$row")
  dir="${OUT}/$(slug "$folder")"; mkdir -p "$dir"
  curl -fsS "${auth[@]}" "${GRAFANA_URL}/api/dashboards/uid/${uid}" \
    | jq '.dashboard | .id = null | del(.version)' > "${dir}/$(slug "$title").json"
  echo "exported: ${folder} / ${title}"
done
