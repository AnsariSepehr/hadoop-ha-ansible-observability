# Apache Zeppelin 0.12.1

Offline install of Zeppelin from `offline_packages/`, systemd service, and a
Prometheus JMX exporter on port 7080. Web UI on port 8080 (`/metrics` on the same port).

## 1. One-time integration (3 small edits)

**a) site.yml**: add this one line to `playbooks/site.yml` (after Spark):

```yaml
- import_playbook: zeppelin/0.12.1/install.yml
```

**b) inventory**: add a `zeppelin` group to `inventory/production.yml` (and `local-test.yml`),
under `children:` in the same style as your other groups:

```yaml
    zeppelin:
      hosts:
        worker3:        # use a host name that already exists in your inventory
```

**c) offline_packages/MANIFEST.md**: add a line for the new package:

```
zeppelin/zeppelin-0.12.1/zeppelin-0.12.1-bin-all.tgz   (https://downloads.apache.org/zeppelin/zeppelin-0.12.1/)
```

## 2. Put the tarball in place

    offline_packages/zeppelin/zeppelin-0.12.1/zeppelin-0.12.1-bin-all.tgz

The JMX exporter jar is reused from `offline_packages/monitoring/jmx-exporter-1.1.0/`.
Java is NOT installed by this role; a JDK 11+ must already be on the target
(see `zeppelin_java_home` in `41-zeppelin-vars.yml`).

## 3. Commands

    ansible-playbook playbooks/zeppelin/0.12.1/install.yml
    ansible-playbook playbooks/zeppelin/0.12.1/status.yml
    ansible-playbook playbooks/zeppelin/0.12.1/stop.yml
    ansible-playbook playbooks/zeppelin/0.12.1/start.yml
    ansible-playbook playbooks/zeppelin/0.12.1/clean.yml                       # keeps notebooks
    ansible-playbook playbooks/zeppelin/0.12.1/clean.yml -e zeppelin_clean_data=true

Add `-i inventory/production.yml` if your ansible.cfg does not set the inventory.

## 4. Notes

* All settings: `inventory/group_vars/all/41-zeppelin-vars.yml`.
* The tarball is read from the control machine through `inventory_dir/../offline_packages`.
  Override `zeppelin_offline_root` if your layout differs.
* Firewall: this role does not touch it. Open 8080 and 7080 (scrape) in your firewall role if needed.
* Prometheus targets: `<host>:7080` (JMX agent) and `<host>:8080/metrics` (Micrometer).
* No Zeppelin authentication (Shiro) is configured, same as the original playbook.
* Zeppelin is unrelated to Spark/Hive settings; add Spark interpreter settings (SPARK_HOME,
  HADOOP_CONF_DIR) in `zeppelin-env.sh.j2` if you want the Spark interpreter to find your cluster.

## 5. Prometheus and JMX troubleshooting

Scrape config for the monitoring node (Prometheus on 192.0.2.50):

```yaml
  - job_name: zeppelin-jmx
    static_configs: [{targets: ['192.0.2.13:7080']}]
  - job_name: zeppelin-web
    metrics_path: /metrics
    static_configs: [{targets: ['192.0.2.13:8080']}]
```

`install.yml` now fails with diagnostics if `http://127.0.0.1:7080/metrics` does not answer
on the Zeppelin host, and opens 7080 to `zeppelin_prometheus_ip` only (8080 to everyone)
when firewalld is running. Manual checks:

    # on the Zeppelin host
    curl -s localhost:7080/metrics | head
    ss -ltnp | grep 7080
    pgrep -af ZeppelinServer | grep -o 'javaagent:[^ ]*'
    # from the Prometheus host
    curl -s http://192.0.2.13:7080/metrics | head
