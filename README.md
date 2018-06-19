# stream-platform
Scripts and documentation referred to the StreamPlatform project

This project consists in deploy and configure a real time processing logs platform. The platform is based in the technologies/componentes related below:

1. Kafka -> For queuing the logs (raw logs, beautified logs and aggregated metrics). It contributes high availability (distributed replication) and "only one read" control (consumer groups).
2. Kubernetes -> For managing docker containers. This supports Flink high availability.
3. Flink -> For distributed stream processing, for beautifying raw logs and calculating aggregated metrics.
4. Logstash -> For Elasticsearch and InfluxDB writing.
