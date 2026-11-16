# Verification and failover tests

[← Documentation index](README.md)

A green install does not prove high availability. Run each test in a maintenance window and record the result in the last column.

## Health checks after install

| Area         | Command                                                        | Expected                    |
|--------------|----------------------------------------------------------------|-----------------------------|
| All services | make status                                                    | Every stage reports success |
| ZooKeeper    | echo srvr \| nc \<NODE1_IP\> 2181 \| grep Mode                 | One leader, two followers   |
| HDFS         | hdfs haadmin -getAllServiceState                               | One active, one standby     |
| HDFS         | hdfs dfsadmin -report                                          | Five live DataNodes         |
| YARN         | yarn rmadmin -getAllServiceState                               | One active, one standby     |
| YARN         | yarn node -list                                                | Five NodeManagers RUNNING   |
| MySQL        | Query replication_group_members                                | Three ONLINE, one PRIMARY   |
| Hive         | beeline -u jdbc:hive2://\<NODE1_IP\>:10000 -e "show databases" | List of databases           |
| Kafka        | kafka-topics.sh --list                                         | The smoke-test topic exists |
| Metrics      | Prometheus, Status, Targets                                    | All jobs UP                 |

## Failover tests

| Test            | Action                                         | Expected result                                                                  | Result         |
|-----------------|------------------------------------------------|----------------------------------------------------------------------------------|----------------|
| NameNode        | Stop hadoop-namenode on the active node        | The other NameNode is active in 15 to 30 seconds. HDFS reads and writes continue | To be recorded |
| ResourceManager | Stop hadoop-resourcemanager on the active node | The other becomes active. Running applications recover                           | To be recorded |
| ZooKeeper       | Stop one member                                | Quorum holds. A new leader is elected if the leader was stopped                  | To be recorded |
| JournalNode     | Stop one of three                              | HDFS keeps working. Two of three is enough                                       | To be recorded |
| MySQL           | Stop the primary                               | A secondary becomes primary. Run refresh-metastore-endpoint.yml                  | To be recorded |
| Kafka           | Stop one broker                                | Topics stay available. Producers with acks=all keep writing                      | To be recorded |

Example for the NameNode test:

sudo systemctl stop hadoop-namenode \# on the active node  
sudo -u hadoop hdfs haadmin -getAllServiceState \# run again after 30 seconds  
sudo systemctl start hadoop-namenode \# bring it back as standby

## Alerts worth adding

Prometheus already holds the data to alert on these. No alert rules are in the current configuration.

- Any target down for more than two minutes.

- No active NameNode, or two active NameNodes.

- Less than 15 percent free space on /data.

- Fewer than five NodeManagers.

- A MySQL group with fewer than three online members.
