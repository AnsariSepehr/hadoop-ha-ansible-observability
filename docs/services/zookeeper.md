# ZooKeeper

[← Documentation index](../README.md)

ZooKeeper 3.8.4 runs as a three-member ensemble on node1, node2 and node3. Hadoop uses it to elect the active NameNode and ResourceManager, so it is installed before HDFS.

## Why it is needed

Without a coordinator, two NameNodes could both believe they are active and corrupt the file system. ZooKeeper holds a lock that only one NameNode can own. If the owner dies, its lock expires and the other node takes over.

## What the role does

1.  Installs the binaries under /opt/\<name\>-\<version\> with a fixed link /opt/zookeeper.

2.  Writes myid from the node's position in the zookeepers group, and zoo.cfg with one server.N line per member.

3.  Writes the systemd unit and the JVM options file, and keeps /run/zookeeper across reboots with a tmpfiles rule.

4.  Starts the service and counts leaders. The check passes only when exactly one member reports leader.

## Key settings

| Setting                 | Value           | Meaning                                 |
|-------------------------|-----------------|-----------------------------------------|
| Client port             | 2181            | Used by ZKFC, ResourceManagers and Hive |
| Peer and election ports | 2888 and 3888   | Traffic between ensemble members        |
| Admin server            | 8080            | Built-in HTTP admin interface           |
| Data directory          | /data/zookeeper | Snapshots and transaction logs          |
| Java                    | OpenJDK 8       | Set by zookeeper_java_version           |

## Verify

systemctl status zookeeper  
echo srvr \| nc \<NODE1_IP\> 2181 \| grep Mode \# one node must show: Mode: leader
