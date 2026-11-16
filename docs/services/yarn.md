# YARN and MapReduce

[← Documentation index](../README.md)

YARN decides which node runs which container. Two ResourceManagers (rm1 on node1, rm2 on node2) use the same ZooKeeper ensemble for election, and five NodeManagers do the work.

## Components

| Component            | Nodes          | Ports                                                           |
|----------------------|----------------|-----------------------------------------------------------------|
| ResourceManager      | node1, node2   | 8032 client, 8030 scheduler, 8031 tracker, 8033 admin, 8088 web |
| NodeManager          | node1 to node5 | 45454 RPC, 8042 web                                             |
| MapReduce JobHistory | node1          | 10020, 19888                                                    |

## Memory is computed, not typed

With resource_mode: auto, each NodeManager gets 70 percent of that node's RAM, rounded down to a multiple of 256 MB with a floor of 2048 MB. The scheduler minimum is 1024 MB and the maximum is half of the NodeManager memory, never below 2048 MB. MapReduce tasks get at most 2048 MB, with a heap of 80 percent. Setting resource_mode: fixed switches to the values in 40-resources.yml.

## Start-up check

yarn.yml starts the ResourceManagers, waits until one is active, then counts NodeManagers in the RUNNING state with a bounded command. It prints diagnostics and fails if any NodeManager is missing, so a half-joined cluster cannot pass as healthy.

sudo -u hadoop yarn rmadmin -getAllServiceState  
sudo -u hadoop yarn node -list
