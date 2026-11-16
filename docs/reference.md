# Reference: ports, commands, sources

[← Documentation index](README.md)

## Port map

| Service              | Ports                                                         |
|----------------------|---------------------------------------------------------------|
| ZooKeeper            | 2181 client, 2888 peer, 3888 election, 8080 admin             |
| HDFS NameNode        | 8020 RPC, 9870 HTTP, 9871 HTTPS                               |
| HDFS JournalNode     | 8485 RPC, 8480 HTTP                                           |
| ZKFC                 | 8019                                                          |
| HDFS DataNode        | 9866 data, 9864 HTTP, 9865 HTTPS                              |
| YARN ResourceManager | 8032, 8030, 8031, 8033, 8088                                  |
| YARN NodeManager     | 45454 RPC, 8042 web                                           |
| MapReduce JobHistory | 10020 RPC, 19888 web                                          |
| MySQL                | 3306 client, 33061 group communication                        |
| Hive                 | 9083 Metastore, 10000 HiveServer2                             |
| Spark History Server | 18080                                                         |
| Kafka                | 9092 broker, 9093 controller                                  |
| Zeppelin             | 8890 web, 8443 TLS                                            |
| JMX exporters        | 7071 to 7084, 9404 Trino                                      |
| Prometheus           | 9090                                                          |
| Exporters            | 9100 node, 9104 MySQL, 9308 Kafka, 9338 cAdvisor, 9102 StatsD |

## Command reference

\# Install and operate  
make preflight  
make install  
make status  
make stop  
make start  
scripts/cluster.sh install --list-stages  
scripts/cluster.sh install --from hive  
  
\# Add a DataNode and NodeManager  
ansible-playbook playbooks/system/initialize.yml --limit \<node\>  
ansible-playbook playbooks/hadoop/3.3.6/install.yml --limit \<node\>  
ansible-playbook playbooks/hadoop/3.3.6/start.yml --limit \<node\>  
  
\# Day-to-day checks  
journalctl -u hadoop-namenode -f  
sudo -u hadoop hdfs haadmin -getAllServiceState  
sudo -u hadoop yarn node -list  
  
\# Destructive (explicit confirmation only)  
make clean CONFIRM_DESTROY_DATA=yes  
  
\# Monitoring stack  
docker stack deploy -c docker-compose.grafana.yml \<stack\>  
curl -X POST http://\<NOC_IP\>:9090/-/reload

## Systemd services

hadoop-journalnode, hadoop-namenode, hadoop-zkfc, hadoop-datanode, hadoop-resourcemanager, hadoop-nodemanager, hadoop-historyserver, zookeeper, mysqld, hive-metastore, hive-server2, spark-history-server, kafka, zeppelin.

## Sources

- The hadoop-ha-ansible project: README.md, docs/OPERATIONS.md, docs/BUGFIX-2026-10.md, docs/ZEPPELIN.md, TEST-REPORT.md.

- The prometheus.yml and docker-compose.grafana.yml files from the monitoring node, with secrets and addresses masked.

- The enterprise SSO guide, for Grafana, Knox and Zeppelin sign-in.
