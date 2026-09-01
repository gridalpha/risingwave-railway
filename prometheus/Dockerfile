# Prometheus for the RisingWave cluster's own metrics. The scrape config is
# multi-line YAML, which a Railway variable cannot carry, so it is baked in
# here rather than rendered at boot.
FROM prom/prometheus:v3

COPY prometheus.yml /etc/prometheus/prometheus.yml
