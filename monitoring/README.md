# Monitoring Stack

This directory is reserved for separate Helm-based observability deployments:

- kube-prometheus-stack for metrics, alerting, and Grafana
- Loki for logs aggregation

These charts should be deployed independently from the application Helm chart to mirror a real platform split between application delivery and observability.
