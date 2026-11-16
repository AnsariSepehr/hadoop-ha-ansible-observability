# Kafka in KRaft mode

[← Documentation index](../README.md)

Kafka 4.0.0 runs on node1, node2 and node3 without ZooKeeper. Each node is both broker and controller, and the controllers keep the cluster metadata in a Raft quorum.

## Design

| Item                     | Value                                                 |
|--------------------------|-------------------------------------------------------|
| Java                     | OpenJDK 17, required by Kafka 4                       |
| Ports                    | 9092 broker, 9093 controller, 7084 JMX                |
| node.id                  | Position in the kafka_brokers group, starting at 1    |
| Cluster ID               | Generated once, stored in .generated/kafka_cluster_id |
| Replication factor       | The smaller of the broker count and 3                 |
| Minimum in-sync replicas | Broker count minus 1, never below 1                   |
| Automatic topic creation | Off                                                   |
| Heap                     | 2048 MB                                               |

## What the role does

1.  Creates the kafka user with a home directory that is not the data directory.

2.  Writes the KRaft configuration and formats the storage once per broker. A broker that already has metadata is never re-formatted.

3.  Installs the systemd unit and a helper that always runs the Kafka tools with Java 17, whatever JAVA_HOME is in the shell.

4.  Configures the JMX exporter and runs a smoke test with the topic kadoop-smoke-test.

The stored cluster ID matters: if it is lost and regenerated, existing brokers refuse to start.

## Verify

kafka-cli kafka-topics.sh --bootstrap-server \<NODE1_IP\>:9092 --list
