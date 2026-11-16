# Build and validation report — 2026-10-31

## Source reviewed

- Source: `hadoop-ha-ansible.tar(1).gz` uploaded to the conversation Library on 2026-10-31, plus the newer saved `playbooks/hadoop/3.3.6/yarn.yml` supplied separately.
- Project components: Hadoop 3.3.6 (HDFS HA/YARN), ZooKeeper 3.8.4, MySQL 8.0.42 Group Replication, Hive 3.1.3, Spark 3.5.4, Kafka 4.0.0 KRaft, and JMX Exporter 1.1.0.
- Cached facts, generated SSH private key, fetched TLS certificate cache, Hive schema patch, and backup files were excluded. The existing Kafka KRaft cluster ID and MySQL Group Replication UUID were preserved in `.generated/` so an existing data cluster does not silently acquire new identities. The encrypted Ansible Vault file remains encrypted.

## Corrections applied

1. Reworked the common Hadoop daemon lifecycle so it checks systemd state and listener availability, stops stale services in a controlled way, terminates only the matching Hadoop JVM, waits for the port to be released, and fails rather than returning false success.
2. NameNode RPC is now checked for both active and standby NameNodes. The standby NameNode does listen on its RPC address; systemd `active` alone is not a sufficient health check.
3. ZKFC port 8019 is now a configurable inventory variable and is checked against the node's advertised address.
4. Removed fragile `$MAINPID` `ExecStop` commands from Hadoop and ZooKeeper units; systemd's normal SIGTERM/process-group handling is used.
5. Removed ZooKeeper's global `pkill` from `ExecStartPre` so starting an ensemble member cannot kill an unrelated ZooKeeper process.
6. Added persistent `systemd-tmpfiles` ownership for the YARN ResourceManager node-attribute store and repaired existing directory ownership before ResourceManager start.
7. Restored the newer YARN verification workflow: wait for an active ResourceManager, count RUNNING NodeManagers with a bounded command, print diagnostics, and fail if any NodeManager is missing.
8. HDFS bootstrap now refuses to format over existing JournalNode metadata if NameNode metadata is missing, and refuses to erase non-empty unrecognised standby metadata without explicit full-reformat confirmation.
9. MySQL no longer automatically wipes a partially populated data directory when `mysql.ibd` is absent. Forced reinitialisation now correctly runs initialization after the confirmed wipe.
10. Removed recursive rewriting of arbitrary MySQL configuration files under `/etc`.
11. Removed `RESET MASTER` from normal Group Replication bootstrap/join flows to preserve GTID and binary-log history. Normal deployment refuses implicit re-bootstrap of a previously configured, fully offline group; the explicit outage-recovery playbook opts in only on the operator-selected bootstrap host.
12. The tarball installer now refuses to recursively delete a non-empty real directory occupying a stable software symlink path.
13. Added an Ansible controller version preflight (ansible-core >= 2.14).

## Tests executed in this build environment

| Test | Result |
|---|---|
| Parse all YAML/YML files with PyYAML | PASS — 126 files |
| Parse all Jinja2 templates | PASS — 24 templates |
| Check static `import_playbook` targets | PASS — no missing imports |
| Regression assertions for Hadoop/YARN/ZKFC, HDFS safety, MySQL safety, installer safety | PASS — 13 assertions |
| Bash syntax of test runner | PASS |

## Tests not executable here

This build environment does not have `ansible-playbook`, `yamllint`, or a connection to the five target hosts / their offline repositories. Consequently, this report does **not** claim that Ansible syntax-check, Ansible template rendering, or a live end-to-end cluster installation has passed. The project's `tests/run-tests.sh` performs those checks on the actual Ansible control node and deliberately exits with status 2 if Ansible is unavailable.

Before production use, run from the control node:

```bash
cd hadoop-ha-ansible
ANSIBLE_VAULT_PASSWORD_FILE=/secure/path/to/vault-password make test
ansible-playbook -i inventory/production.yml playbooks/system/preflight.yml --ask-vault-pass
```

Then run the deployment in a maintenance window and verify the HDFS HA, YARN HA, ZooKeeper quorum, MySQL Group Replication, Hive, Spark, and Kafka status playbooks. A static archive review cannot prove live failover or application-level behavior.

## Security note

The uploaded source archive contained a generated `.generated/ssh/id_rsa` and cached host facts. The private key and caches are intentionally excluded; the SSH key is regenerated and re-authorised by the initialization playbook. The stable Kafka and MySQL cluster identifiers are retained. If the uploaded archive or its private key was distributed beyond the trusted administration boundary, rotate that SSH key on the cluster.
