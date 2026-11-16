#!/usr/bin/env python3
"""Generate Prometheus file_sd target files from the Ansible inventory.

The inventory is the single source of truth for which node runs which service.
Generating targets from it keeps Prometheus labels identical to inventory names
(node1..nodeN) and removes hand-edited host/role labels.

    python3 monitoring/prometheus/gen-targets.py \
        --inventory ansible/inventory/production.yml \
        --ports ansible/inventory/group_vars/all/20-ports.yml \
        --out monitoring/prometheus/file_sd --cluster <cluster-name>
"""
import argparse, json, pathlib, sys
import yaml

# job name -> (inventory group, port source, role label)
# port source: ("jmx", key in jmx_ports) | ("fixed", number)
JOBS = {
    "hadoop_namenode_jmx":       ("namenodes",             ("jmx", "namenode"),        "namenode"),
    "hadoop_zkfc_jmx":           ("namenodes",             ("jmx", "zkfc"),            "zkfc"),
    "hadoop_datanode_jmx":       ("datanodes",             ("jmx", "datanode"),        "datanode"),
    "hadoop_journalnode_jmx":    ("journalnodes",          ("jmx", "journalnode"),     "journalnode"),
    "zookeeper_jmx":             ("zookeepers",            ("jmx", "zookeeper"),       "zookeeper"),
    "yarn_resourcemanager_jmx":  ("resourcemanagers",      ("jmx", "resourcemanager"), "resourcemanager"),
    "yarn_nodemanager_jmx":      ("nodemanagers",          ("jmx", "nodemanager"),     "nodemanager"),
    "mapred_historyserver_jmx":  ("history_servers",       ("jmx", "historyserver"),   "historyserver"),
    "hive_hiveserver2_jmx":      ("hive_servers",          ("jmx", "hiveserver2"),     "hiveserver2"),
    "hive_metastore_jmx":        ("hive_servers",          ("jmx", "hivemetastore"),   "hive-metastore"),
    "spark_history_jmx":         ("spark_history_servers", ("jmx", "spark_history"),   "spark-history"),
    "kafka_jmx":                 ("kafka_brokers",         ("jmx", "kafka"),           "kafka"),
    "zeppelin_jmx":              ("zeppelin",              ("fixed", 7080),            "zeppelin"),
    "node_exporter_cluster":     ("cluster",               ("fixed", 9100),            "host"),
    "mysqld_exporter_metastore": ("mysql",                 ("fixed", 9104),            "mysql-group-replication"),
}


def hosts_of(group, tree):
    """Flatten a group (hosts plus nested children) into sorted host names."""
    node = tree.get(group)
    if node is None:
        return []
    out = [h for h in (node.get("hosts") or {}) if h != "localhost"]
    for child in (node.get("children") or {}):
        out += hosts_of(child, tree)
    return sorted(set(out))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--inventory", required=True)
    ap.add_argument("--ports", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--cluster", default="hadoop", help="value of the 'cluster' label")
    a = ap.parse_args()

    inv = yaml.safe_load(open(a.inventory, encoding="utf-8"))["all"]
    jmx = yaml.safe_load(open(a.ports, encoding="utf-8"))["jmx_ports"]
    addr = {h: (v or {}).get("ansible_host", h) for h, v in inv["hosts"].items()}
    tree = inv.get("children", {})

    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    written = 0
    for job, (group, (kind, val), role) in JOBS.items():
        port = jmx[val] if kind == "jmx" else val
        sd = [{"targets": [f"{addr[h]}:{port}"],
               "labels": {"hostname": h, "role": role, "cluster": a.cluster}}
              for h in hosts_of(group, tree)]
        path = out / f"{job}.json"
        if sd:
            path.write_text(json.dumps(sd, indent=2) + "\n", encoding="utf-8")
            written += 1
        elif path.exists():
            path.unlink()   # group empty -> service not installed -> no target file
        print(f"{job:28s} {len(sd)} target(s), port {port}")
    print(f"wrote {written} file(s) to {out}", file=sys.stderr)


if __name__ == "__main__":
    main()
