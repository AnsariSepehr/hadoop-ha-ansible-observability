# Environment, prerequisites and masking conventions

[← Documentation index](README.md)

Every address, host name, account and secret in this document is a placeholder, so the text and any repository built from it can be shared publicly.

## Masking legend

| Placeholder used here        | Stands for                                                                    |
|------------------------------|-------------------------------------------------------------------------------|
| \<NODE1_IP\> to \<NODE5_IP\> | Internal addresses of the five cluster nodes, in inventory order              |
| \<NOC_IP\>                   | Address of the monitoring node that runs Docker Swarm, Prometheus and Grafana |
| example.corp                 | The company's internal DNS domain                                             |
| dashboards.example.corp      | The Grafana URL, served over HTTPS                                            |
| sso.example.corp             | The Keycloak URL used by Grafana for sign-in                                  |
| \<REALM\>                    | The Keycloak realm name                                                       |
| grafana-admins               | The Keycloak group whose members become Grafana administrators                |
| \<SECRET\>, \<PASSWORD\>     | Any password, client secret, token or key. Never commit a real value          |
| \<VAULT_PASSWORD\>           | The Ansible Vault password that unlocks secrets.yml                           |
| \<K8S_TOKEN_FILE\>           | Service-account token file used by Prometheus to scrape the Kubernetes API    |
| node1 to node5               | Ansible inventory names. These are kept because they are generic              |

## Servers involved

| Server          | Inventory name | Services                                                                                                                                                              |
|-----------------|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Cluster node 1  | node1          | ZooKeeper, JournalNode, NameNode and ZKFC, DataNode, ResourceManager, NodeManager, JobHistory, Hive Metastore and HiveServer2, Spark client and History Server, Kafka |
| Cluster node 2  | node2          | ZooKeeper, JournalNode, NameNode and ZKFC, DataNode, ResourceManager, NodeManager, Spark client, Kafka                                                                |
| Cluster node 3  | node3          | ZooKeeper, JournalNode, DataNode, NodeManager, MySQL, Kafka, Zeppelin                                                                                                 |
| Cluster node 4  | node4          | DataNode, NodeManager, MySQL                                                                                                                                          |
| Cluster node 5  | node5          | DataNode, NodeManager, MySQL                                                                                                                                          |
| Control node    | localhost      | Runs Ansible; holds the offline packages and the generated IDs                                                                                                        |
| Monitoring node | noc            | Docker Swarm with Prometheus, Grafana and a local node-exporter                                                                                                       |

## Prerequisites

- Cluster nodes run a RHEL-family system (version 8 or 9) and are reachable over SSH as root with a key.

- Each node has tar, gzip, sudo, runuser, Python 3 and a synchronised clock (chrony).

- The control node has ansible-core 2.14 or newer, python3 and ssh-keygen.

- All software is placed beforehand in offline_packages/\<software\>/\<software\>-\<version\>/, listed in MANIFEST.md. No internet access is needed, and dnf is run with --disablerepo='\*'.

- Java is also offline: OpenJDK 8 (Hadoop, ZooKeeper, Hive, Spark), OpenJDK 17 (Kafka 4) and, optionally, JDK 11 (Zeppelin 0.12 needs 11 or newer).

- The monitoring node runs Docker in Swarm mode and has an overlay network named elk that already exists.

## Offline packages

| Software           | Package expected in offline_packages/                            |
|--------------------|------------------------------------------------------------------|
| Hadoop 3.3.6       | hadoop/hadoop-3.3.6/hadoop-3.3.6.tar.gz                          |
| ZooKeeper 3.8.4    | zookeeper/zookeeper-3.8.4/apache-zookeeper-3.8.4-bin.tar.gz      |
| Hive 3.1.3         | hive/hive-3.1.3/apache-hive-3.1.3-bin.tar.gz                     |
| Spark 3.5.4        | spark/spark-3.5.4/spark-3.5.4-bin-hadoop3.tgz                    |
| Kafka 4.0.0        | kafka/kafka-4.0.0/kafka_2.13-4.0.0.tgz                           |
| MySQL 8.0.42       | mysql/mysql-server-8.0.42/\*.rpm and the Connector/J 8.0.28 jar  |
| JMX Exporter 1.1.0 | monitoring/jmx-exporter-1.1.0/jmx_prometheus_javaagent-1.1.0.jar |
| Zeppelin 0.12.1    | zeppelin/zeppelin-0.12.1/zeppelin-0.12.1-bin-all.tgz             |
