# Troubleshooting: problems and fixes

[← Documentation index](README.md)

| Symptom                                                             | Cause                                                                                                        | Fix                                                                                                |
|---------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| ZooKeeper start-up sometimes marked failed although the process ran | The unit was Type=forking and relied on a PID file path that did not always match the one zkServer.sh writes | Unit reworked so systemd detects the real process                                                  |
| A node that never joined the quorum looked healthy                  | The check accepted standalone as a leader                                                                    | Verification now needs exactly one leader                                                          |
| HDFS bootstrap continued before a NameNode was active               | The wait task had retries and delay but no until                                                             | It now retries until the active-state probe succeeds                                               |
| Two units for the same NameNode or JournalNode                      | Old unprefixed units existed next to the hadoop-\* units                                                     | Old units are retired after checking MainPID=0. The play stops if one still owns a process         |
| kill: not enough arguments when stopping                            | ExecStop used \$MAINPID, which can be empty                                                                  | Custom ExecStop removed. systemd's normal SIGTERM handling is used                                 |
| Starting one ZooKeeper member killed another                        | A global pkill in ExecStartPre                                                                               | Removed                                                                                            |
| A standby NameNode was reported down while healthy                  | Health was judged by systemd state alone                                                                     | The role also checks the RPC port. A standby listens on it                                         |
| ZKFC was checked on loopback                                        | The listener is on the node's advertised address                                                             | The check uses that address and the configurable port 8019                                         |
| ResourceManager failed after a reboot                               | Its node-attribute store in /tmp lost its owner                                                              | A tmpfiles rule keeps the ownership and the role repairs it before start                           |
| Formatting would have wiped live metadata                           | Bootstrap could run over existing JournalNode data                                                           | Format refuses unless explicitly forced                                                            |
| MySQL data directory could be wiped by a rerun                      | A partly filled directory was treated as empty                                                               | Fails closed. Forced re-initialisation needs a flag                                                |
| Group Replication error 3092                                        | Configuration, SELinux port label or log problem                                                             | Check the error log, the GR settings and the port label first. Never delete data to fix membership |
| GTID history lost on re-bootstrap                                   | RESET MASTER ran in normal flows                                                                             | Removed from normal flows                                                                          |
| Hive stopped with NoSuchMethodError on Preconditions                | Hive's Guava differs from Hadoop's                                                                           | hive_replace_guava: true (default)                                                                 |
| Hive schema script failed                                           | Stock script had merged statements                                                                           | The schema is patched and checked on the control node before use                                   |
| Tarball install removed a real directory                            | A real folder sat where a link should be                                                                     | The installer refuses to delete a non-empty real directory                                         |

## Monitoring problems

| Symptom | Cause | Fix |
|---|---|---|
| A Zeppelin web-metrics target is DOWN with a content-type or format error | Prometheus 3 rejects a scrape whose `Content-Type` is not a valid exposition format | Set `fallback_scrape_protocol: PrometheusText0.0.4` on that job (already in `prometheus.yml`) |
| A job exists but shows no targets | Its inventory group is empty, so `gen-targets.py` writes no file for it | Add hosts to the group, or ignore the job |
| New DataNode is missing in Grafana | `file_sd` files were not regenerated | Run `gen-targets.py` (or `deploy-config.sh`). Prometheus then picks the file up by itself |
| A JMX port answers on one host but not another | The daemon was started before the agent was configured, or a firewall blocks the port | Restart the daemon after `jmx_exporter` ran; open the port to the monitoring node only |
| Panel shows "No data" after importing a dashboard | The dashboard points at a data source uid that does not exist | Run `sanitize-dashboards.py`, which rewrites it to `uid: prometheus` |
| Grafana loops on sign-in | `GF_SERVER_ROOT_URL` or the Keycloak redirect URI does not match the public URL exactly | Make both identical, including `https` and no trailing slash |
| A metric name from a guide does not exist | The JMX rules are a catch-all, so names follow the bean names | Search the real name in Grafana Explore before using it in a panel or alert |

