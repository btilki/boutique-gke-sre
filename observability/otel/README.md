# OpenTelemetry

In-cluster OpenTelemetry Collector for traces and metrics from Online Boutique.

## Purpose

Receive OTLP from application workloads and export to Google Cloud observability backends (Cloud Trace, Managed Prometheus).

## Layout

| Path | Purpose |
|------|---------|
| `collector/config.yaml` | Collector pipeline configuration (receivers, processors, exporters) |
| `collector/deployment.yaml` | Kubernetes Deployment, ServiceAccount, and volume mounts |

## Dependencies

- GKE cluster with Workload Identity
- GCP APIs: Cloud Trace, Cloud Monitoring
- Collector GCP SA: `otel-collector@boutique-gke.iam.gserviceaccount.com` (Terraform `iam` module)

## Deployment

Synced via Argo CD `observability` Application. See [docs/setup/13-observability-slos.md](../../docs/setup/13-observability-slos.md).

## Validation

```bash
kubectl get pods -n observability -l app.kubernetes.io/name=otel-collector
kubectl logs -n observability deploy/otel-collector --tail=20
```

## Further reading

- [observability/README.md](../README.md)
- [GCP OTel documentation](https://cloud.google.com/stackdriver/docs/instrumentation/opentelemetry)
