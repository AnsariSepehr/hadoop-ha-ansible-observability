# Zeppelin

[← Documentation index](../README.md)

Apache Zeppelin 0.12.1 is the web notebook for Spark, Hive and SQL work. It runs on node3 and was added after the main stack, with its own role and playbook.

## Design

| Item     | Value                                                              |
|----------|--------------------------------------------------------------------|
| Node     | node3 (group zeppelin)                                             |
| User     | zeppelin, a dedicated system account                               |
| Web port | 8890, also serving /metrics                                        |
| TLS port | 8443 (available)                                                   |
| JMX port | 7080                                                               |
| Memory   | Server 1024 to 2048 MB, each interpreter 512 to 1024 MB            |
| Java     | JDK 11 or newer, set with zeppelin_java_home or detected from PATH |

## What the role does

1.  Checks the Java path, then creates the group and user.

2.  Extracts the offline tarball under /opt and links the stable path.

3.  Copies the JMX agent and a catch-all rules file, writes zeppelin-env.sh and the systemd unit.

4.  Starts the service and waits for the web and JMX ports.

5.  When firewalld is running, opens the web port to everyone and the JMX port only to the monitoring node.

6.  Confirms that the exporter serves metrics and that the REST API answers.

## Commands

ansible-playbook playbooks/zeppelin/0.12.1/install.yml  
ansible-playbook playbooks/zeppelin/0.12.1/status.yml  
ansible-playbook playbooks/zeppelin/0.12.1/clean.yml \# keeps notebooks  
ansible-playbook playbooks/zeppelin/0.12.1/clean.yml -e zeppelin_clean_data=true
