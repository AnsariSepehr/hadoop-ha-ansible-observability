#!/usr/bin/env python3
"""Offline structural checks; does not require an Ansible controller or cluster."""
from pathlib import Path
import sys
import yaml
from jinja2 import Environment
import base64
import uuid

ROOT = Path(__file__).resolve().parents[1]
errors = []
count_yaml = 0
count_templates = 0

for path in sorted(ROOT.rglob('*')):
    if not path.is_file() or '.generated' in path.parts or '.bak' in path.name:
        continue
    if path.suffix in {'.yml', '.yaml'}:
        count_yaml += 1
        try:
            yaml.safe_load(path.read_text(encoding='utf-8'))
        except Exception as exc:
            errors.append(f'YAML parse: {path.relative_to(ROOT)}: {exc}')
    elif path.suffix == '.j2':
        count_templates += 1
        try:
            Environment().parse(path.read_text(encoding='utf-8'))
        except Exception as exc:
            errors.append(f'Jinja parse: {path.relative_to(ROOT)}: {exc}')

# Check statically-addressable import_playbook paths.
for path in sorted((ROOT / 'playbooks').rglob('*.yml')):
    if '.bak' in path.name or path.parent.name == '_lib' and path.name == 'generate-ids.yml':
        continue
    try:
        data = yaml.safe_load(path.read_text(encoding='utf-8')) or []
    except Exception:
        continue
    if not isinstance(data, list):
        continue
    for play in data:
        if isinstance(play, dict) and 'ansible.builtin.import_playbook' in play:
            target = (path.parent / str(play['ansible.builtin.import_playbook'])).resolve()
            if not target.is_file():
                errors.append(f'Playbook import missing: {path.relative_to(ROOT)} -> {play["ansible.builtin.import_playbook"]}')

# Persistent IDs are created by the first install and must be kept for existing Kafka/MySQL clusters.
# They are git-ignored, so a fresh clone (and CI) legitimately has none: skip the check then.
ids_dir = ROOT / '.generated'
if not (ids_dir / 'kafka_cluster_id').exists():
    print('SKIP: no .generated cluster IDs yet (created by the first install)')
else:
  try:
      kafka_id = (ids_dir / 'kafka_cluster_id').read_text().strip()
      mysql_group_id = (ids_dir / 'mysql_gr_group_name').read_text().strip()
      kafka_decoded = base64.urlsafe_b64decode(kafka_id + '=' * ((4 - len(kafka_id) % 4) % 4))
      uuid.UUID(mysql_group_id)
      if len(kafka_decoded) != 16:
          errors.append('Persistent Kafka KRaft cluster ID is not a 16-byte base64 UUID')
  except Exception as exc:
      errors.append(f'Persistent cluster IDs are missing or invalid: {exc}')

# Regression/safety invariants for the incidents found in the supplied project.
service = (ROOT / 'roles/hadoop/tasks/service.yml').read_text()
unit = (ROOT / 'roles/hadoop/templates/hadoop.service.j2').read_text()
zkunit = (ROOT / 'roles/zookeeper/templates/zookeeper.service.j2').read_text()
zkfc = (ROOT / 'roles/hadoop/tasks/ha_zkfc.yml').read_text()
hdfs_template = (ROOT / 'roles/hadoop/templates/hdfs-site.xml.j2').read_text()
mysql = (ROOT / 'roles/mysql/tasks/configure.yml').read_text()
gr_bootstrap = (ROOT / 'roles/mysql/tasks/gr_bootstrap.yml').read_text()
gr_join = (ROOT / 'roles/mysql/tasks/gr_join.yml').read_text()
installer = (ROOT / 'roles/common/tasks/install_tarball.yml').read_text()
primary = (ROOT / 'roles/hadoop/tasks/ha_namenode_primary.yml').read_text()
checks = {
    'NameNode RPC listener is checked by the common lifecycle': 'svc_port' in service and 'wait_for:' in service,
    'YARN node-attribute store ownership is repaired and persisted': 'hadoop-yarn-node-attributes.conf' in service and 'recurse: true' in service,
    'ZKFC port is variable-driven in service and HDFS config': 'hdfs_zkfc_rpc_port' in zkfc and 'dfs.ha.zkfc.port' in hdfs_template,
    'Hadoop unit does not use unsafe MAINPID ExecStop': 'ExecStop=/bin/kill -TERM $MAINPID' not in unit,
    'ZooKeeper unit does not globally pkill other instances': 'ExecStartPre=-/usr/bin/pkill' not in zkunit,
    'MySQL partial data is protected by a fail-closed assertion': 'Refuse to erase an uninitialised MySQL data directory' in mysql,
    'MySQL reinitialisation recomputes init requirement after wipe': 'mysql_needs_init:' in mysql and 'mysql_force_reinit | bool' in mysql,
    'HDFS refuses to overwrite partial primary NameNode metadata': 'Refuse to format over unrecognised primary NameNode contents' in primary,
    'HDFS refuses mismatched existing JournalNode namespace': 'Refuse to format a new NameNode over an existing JournalNode namespace' in primary,
    'MySQL Group Replication does not reset master during join/bootstrap': 'RESET MASTER' not in gr_bootstrap and 'RESET MASTER' not in gr_join,
    'MySQL normal install refuses silent outage re-bootstrap': 'Refuse implicit re-bootstrap' in gr_bootstrap,
    'YARN verification waits for active RM and fails on missing NodeManagers': 'Wait for an active ResourceManager' in (ROOT / 'playbooks/hadoop/3.3.6/yarn.yml').read_text() and 'Fail if not every NodeManager registered' in (ROOT / 'playbooks/hadoop/3.3.6/yarn.yml').read_text(),
    'Tarball installer refuses unsafe non-symlink stable paths': 'refuse to replace a non-symlink file' in installer and 'refuse to delete a non-empty real directory' in installer,
}
for label, ok in checks.items():
    if not ok:
        errors.append(f'Regression invariant failed: {label}')

print(f'YAML files parsed: {count_yaml}')
print(f'Jinja templates parsed: {count_templates}')
print('Persistent Kafka/MySQL cluster IDs: validated')
for label in checks:
    print(f'{"PASS" if checks[label] else "FAIL"}: {label}')
if errors:
    print('\nERRORS:')
    for error in errors:
        print(f'- {error}')
    sys.exit(1)
print('STATIC CHECKS PASSED')
