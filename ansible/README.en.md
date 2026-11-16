# Hadoop HA platform: Ansible project (English quick start)

The full original README is in Persian ([README.md](README.md)). This page is the short English version. The complete explanation of every service is in [`../docs`](../docs/README.md).

## What it installs

ZooKeeper 3.8.4, HDFS and YARN (Hadoop 3.3.6, two NameNodes and two ResourceManagers), MySQL 8.0.42 Group Replication, Hive 3.1.3, Spark 3.5.4, Kafka 4.0.0 (KRaft), Zeppelin 0.12.1 and the Prometheus JMX Exporter, all **offline**.

## Quick start

```bash
# 1. put the packages in offline_packages/ (see offline_packages/MANIFEST.md)
# 2. edit the only per-cluster file
vi inventory/production.yml                 # addresses are examples (192.0.2.x); set your own
# 3. secrets
cp inventory/group_vars/all/secrets.yml.example inventory/group_vars/all/secrets.yml
vi inventory/group_vars/all/secrets.yml     # replace every CHANGE_ME
ansible-vault encrypt inventory/group_vars/all/secrets.yml
# 4. run
make preflight
make install
make status
```

Other commands: `scripts/cluster.sh install --from hive`, `scripts/cluster.sh install --tags jmx`, `make stop`, `make start`.

`secrets.yml` and the generated `.generated/` folder (SSH key, certificates, cluster IDs) are git-ignored. **Never commit them.** Keep `.generated/kafka_cluster_id` and `.generated/mysql_gr_group_name` for the life of the cluster.

## Safety

Destructive actions need an explicit flag (`confirm_destroy_data=yes`, `hdfs_force_reformat=true`, `hive_reinit_schema=true`, `mysql_force_reinit=true`). See [`../docs/ansible-project.md`](../docs/ansible-project.md#safety-rules-built-into-the-playbooks).

## Checks without a cluster

```bash
python3 tests/static-check.py
```
