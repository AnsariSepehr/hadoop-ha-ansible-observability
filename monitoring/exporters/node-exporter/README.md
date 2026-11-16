# node_exporter

Host-level metrics (CPU, memory, disk, network, load) for every cluster node, on port 9100.

> **Unverified reference.** The original project did not install node_exporter with Ansible. The playbook and unit below follow the same offline pattern as the other roles. Test on one node first.

## Offline install

1. Download `node_exporter-<version>.linux-amd64.tar.gz` and place it at `ansible/offline_packages/monitoring/node-exporter/`.
2. Run the playbook:

```bash
cd ansible
ansible-playbook ../monitoring/exporters/node-exporter/install.yml \
  -e node_exporter_tarball=offline_packages/monitoring/node-exporter/node_exporter-<version>.linux-amd64.tar.gz \
  -e node_exporter_version=<version>
```

The unit listens on all interfaces. Restrict port 9100 to the monitoring node with the firewall (`manage_firewall: true`, or a rich rule).

## Monitoring node

The monitoring node runs node_exporter as a Swarm service inside the stack file. See `monitoring/stack/docker-compose.grafana.yml`.
