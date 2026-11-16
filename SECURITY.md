# Security policy

This repository contains documentation, templates and scripts, **no live secrets and no real hostnames**. If you find a real credential, host name or IP address in any file or in the git history, open a private security advisory (or contact the maintainer) instead of a public issue, so it can be rotated and scrubbed.

The playbooks change system configuration (users, kernel limits, firewall, services) and some can delete data when given an explicit confirmation flag. Read them before running; they are provided without warranty (see LICENSE).

Never commit: `secrets.yml`, `monitoring.env`, Kubernetes token files, TLS keys or keystores, the `.generated/` folder, or Grafana API tokens.
