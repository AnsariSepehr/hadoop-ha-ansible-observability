#!/usr/bin/env bash
# Thin wrapper around the orchestration playbooks.
#   scripts/cluster.sh install|start|stop|status|clean [extra ansible-playbook args]
#
# install also understands (see the tags in playbooks/site.yml):
#   --from <stage>     start at <stage> and skip every stage before it
#   --list-stages      print the stage names in install order
# Examples:
#   scripts/cluster.sh install --from hive --ask-vault-pass
#   scripts/cluster.sh install --tags hive,spark          # only these stages
#   scripts/cluster.sh install --skip-tags preflight      # everything except preflight
set -euo pipefail
cd "$(dirname "$0")/.."
cmd="${1:-}"; shift || true

# Stage tags in install order - keep identical to the unique (first) tag of each line in playbooks/site.yml
STAGES=(preflight initialize jmx zookeeper hadoop_install hadoop_ssl hadoop_ha yarn mysql hive spark kafka)

install() {
  local from="" args=() skip=() found=0 s
  while [ $# -gt 0 ]; do
    case "$1" in
      --list-stages) printf '%s\n' "${STAGES[@]}"; exit 0 ;;
      --from)        [ $# -ge 2 ] || { echo "--from needs a stage name"; exit 1; }; from="$2"; shift 2 ;;
      --from=*)      from="${1#--from=}"; shift ;;
      *)             args+=("$1"); shift ;;
    esac
  done
  if [ -n "$from" ]; then
    for s in "${STAGES[@]}"; do
      if [ "$s" = "$from" ]; then found=1; break; fi
      skip+=("$s")
    done
    if [ "$found" -eq 0 ]; then
      echo "unknown stage '$from'. Valid stages: ${STAGES[*]}" >&2; exit 1
    fi
    if [ "${#skip[@]}" -gt 0 ]; then
      args+=(--skip-tags "$(IFS=,; echo "${skip[*]}")")
      echo ">> starting at '$from' - skipping: ${skip[*]}" >&2
    fi
  fi
  exec ansible-playbook playbooks/site.yml ${args[@]+"${args[@]}"}
}

case "$cmd" in
  install) install "$@" ;;
  start)   exec ansible-playbook playbooks/start-cluster.yml "$@" ;;
  stop)    exec ansible-playbook playbooks/stop-cluster.yml "$@" ;;
  status)  exec ansible-playbook playbooks/status-cluster.yml "$@" ;;
  clean)   exec ansible-playbook playbooks/clean-all.yml "$@" ;;
  *) echo "usage: $0 {install|start|stop|status|clean} [ansible-playbook options]"; exit 1 ;;
esac
