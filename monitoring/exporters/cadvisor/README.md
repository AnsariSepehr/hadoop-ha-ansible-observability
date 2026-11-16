# cAdvisor on Docker Swarm

Per-container CPU, memory and network for the monitoring host and any other Swarm node. Published on port 9338 so it does not clash with other services.

> **Unverified reference.**

```yaml
# add to a stack file; mode global runs one copy per Swarm node
services:
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:<version>
    deploy: { mode: global }
    ports:
      - { target: 8080, published: 9338, mode: host }
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
```

Add the job `cadvisor_docker` from `monitoring/prometheus/extra-jobs.example.yml`.
