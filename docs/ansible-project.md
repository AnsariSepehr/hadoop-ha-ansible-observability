# The Ansible project

[← Documentation index](README.md)

## Why one inventory and no hard-coded addresses

Each machine is declared once, with a name and an address. It receives its roles by joining groups, so one machine can be NameNode, ZooKeeper and Kafka at the same time. No playbook or template contains an address. Quorums, nn1/nn2 and rm1/rm2 identifiers, ZooKeeper myid, Kafka node.id and all connection strings are computed from the group membership in 30-derived.yml. A group left empty means that service is not installed.

## Directory layout

hadoop-ha-ansible/  
├── ansible.cfg  
├── Makefile make preflight \| install \| start \| stop \| status \| clean \| test  
├── inventory/  
│ ├── production.yml the only file edited per cluster  
│ └── group_vars/all/  
│ ├── 00-cluster.yml cluster name, users, paths, feature switches  
│ ├── 10-versions.yml versions, package paths, Java catalog  
│ ├── 20-ports.yml every port, including one JMX port per service  
│ ├── 30-derived.yml values computed from the inventory (do not edit)  
│ ├── 40-resources.yml memory for YARN, Spark, Hive, Kafka (auto or fixed)  
│ └── secrets.yml passwords, encrypted with Ansible Vault  
├── offline_packages/ all binaries, with MANIFEST.md  
├── roles/ common, java, zookeeper, hadoop, mysql, hive, spark, kafka, jmx_exporter, zeppelin  
├── playbooks/ site.yml plus one folder per service and version  
├── scripts/cluster.sh wrapper: install \| start \| stop \| status \| clean  
├── .generated/ stable Kafka cluster ID and MySQL group UUID (do not delete)  
└── docs/ operations notes, bug-fix notes, Zeppelin notes

## Roles and what each one does

| Role         | Purpose                                                                                                                                                                       |
|--------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| common       | Operating system preparation: service user, SSH trust between nodes, /etc/hosts, kernel limits and sysctl tuning, NTP check, optional firewalld rules, safe tarball installer |
| java         | Installs the Java version each service asks for, from a tarball or from local RPMs                                                                                            |
| zookeeper    | Installs the ensemble, writes myid, zoo.cfg and the systemd unit, verifies one leader                                                                                         |
| hadoop       | HDFS and YARN: configuration, systemd units, HA bootstrap, SSL, HDFS directories                                                                                              |
| mysql        | Installs MySQL, bootstraps and joins Group Replication                                                                                                                        |
| hive         | Metastore and HiveServer2, schema initialisation, metastore endpoint refresh                                                                                                  |
| spark        | Spark on YARN, History Server, HDFS directories, smoke test                                                                                                                   |
| kafka        | KRaft cluster formatting, broker configuration, topic smoke test                                                                                                              |
| jmx_exporter | Installs the Prometheus JMX agent and its rules file                                                                                                                          |
| zeppelin     | Notebook server, systemd unit, firewall rule for Prometheus                                                                                                                   |

## Run order

site.yml imports one playbook per stage, each with its own tag. The stages are independent, so any one can be re-run, provided the services it depends on already exist.

| Order | Tag            | Playbook                                  | What it does                                                 |
|-------|----------------|-------------------------------------------|--------------------------------------------------------------|
| 1     | preflight      | system/preflight.yml                      | Checks the inventory, secrets, packages and operating system |
| 2     | initialize     | system/initialize.yml                     | Prepares every node                                          |
| 3     | jmx            | monitoring/jmx-exporter/1.1.0/install.yml | Installs the metrics agent                                   |
| 4     | zookeeper      | zookeeper/3.8.4/install.yml               | Starts the ensemble                                          |
| 5     | hadoop_install | hadoop/3.3.6/install.yml                  | Installs Hadoop and writes configuration                     |
| 6     | hadoop_ssl     | hadoop/3.3.6/ssl.yml                      | HTTPS for HDFS web interfaces                                |
| 7     | hadoop_ha      | hadoop/3.3.6/bootstrap-ha.yml             | Formats and starts HDFS HA                                   |
| 8     | yarn           | hadoop/3.3.6/yarn.yml                     | Starts YARN and checks every NodeManager                     |
| 9     | mysql          | mysql/8.0.42/install.yml                  | Builds the Group Replication cluster                         |
| 10    | hive           | hive/3.1.3/install.yml                    | Metastore and HiveServer2                                    |
| 11    | spark          | spark/3.5.4/install.yml                   | Spark and History Server                                     |
| 12    | kafka          | kafka/4.0.0/install.yml                   | KRaft cluster                                                |

Zeppelin has its own playbook, zeppelin/0.12.1/install.yml, and was added after Spark. Typical commands:

make preflight \# asks for \<VAULT_PASSWORD\>  
make install  
scripts/cluster.sh install --from hive \# resume at a stage  
scripts/cluster.sh install --tags hive,spark \# only some stages  
make status

## Safety rules built into the playbooks

- Destructive actions run only with an explicit flag: confirm_destroy_data=yes, hdfs_force_reformat=true, hive_reinit_schema=true, mysql_force_reinit=true.

- HDFS bootstrap refuses to format over existing JournalNode data when NameNode metadata is missing.

- MySQL never wipes a partly filled data directory on its own and never runs RESET MASTER during a normal deployment.

- The tarball installer refuses to delete a real directory that sits where a stable symlink should be.

- Versions are checked against the playbook folder name, so a playbook for 3.3.6 will not run with another hadoop_version.

- Installs are versioned on disk: /opt/hadoop-3.3.6 with a fixed link /opt/hadoop.
