# kafka_exporter

Broker JMX metrics (port 7084) describe the brokers. **Consumer lag and topic and partition state** come from [danielqsj/kafka_exporter](https://github.com/danielqsj/kafka-exporter), which talks to Kafka as a client. Port 9308.

> **Unverified reference.** Run it anywhere that can reach the brokers, for example on the monitoring node.

```bash
docker run -d --name kafka-exporter --restart unless-stopped -p 9308:9308 \
  danielqsj/kafka-exporter:<version> \
  --kafka.server=<NODE1_IP>:9092 --kafka.server=<NODE2_IP>:9092 --kafka.server=<NODE3_IP>:9092
```

Add the job from `monitoring/prometheus/extra-jobs.example.yml` (`kafka_exporter`).
