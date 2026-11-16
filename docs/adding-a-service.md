# Adding a new service to monitoring

[← Documentation index](README.md)

Follow these steps for any new Java daemon or exporter.

1. **Pick a JMX port.** Add one key to `jmx_ports` in `ansible/inventory/group_vars/all/20-ports.yml`. Ports 7071 to 7084 are taken. Use one port per *service*, the same on every host.
2. **Attach the agent.** In the service's role, add the `-javaagent` option (see `ansible/roles/jmx_exporter` and how the Kafka and Zeppelin roles do it) and restart the daemon.
3. **Add an inventory group** if the service has its own hosts.
4. **Teach the generator.** Add one line to the `JOBS` table in [`gen-targets.py`](../monitoring/prometheus/gen-targets.py): job name, inventory group, port source, role label.
5. **Add the scrape job.** Copy a `file_sd_configs` block in [`prometheus.yml`](../monitoring/prometheus/prometheus.yml). `scripts/tools/validate.sh` fails if the job points at a file the generator does not produce.
6. **Open the port** to the monitoring node only.
7. **Build a dashboard** in Grafana, export it with `scripts/monitoring/export-grafana-dashboards.sh`, sanitize it, and commit it under `monitoring/grafana/dashboards/<NN-folder>/`.
8. **Add an alert** for "target down" at least. Confirm metric names in Grafana Explore before writing service-specific rules.
9. **Document it** in `docs/services/<name>.md`, and add its failure modes to [troubleshooting](troubleshooting.md).

For services that are not Java (databases, message brokers with their own exporter), run the exporter next to the service, add its job to [`extra-jobs.example.yml`](../monitoring/prometheus/extra-jobs.example.yml), and add a folder under `monitoring/exporters/`.
