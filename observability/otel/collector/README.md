# OpenTelemetry Collector manifests

| File                                     | Description                                                     |
| ---------------------------------------- | --------------------------------------------------------------- |
| [config.yaml](config.yaml)               | Collector pipeline — export to Cloud Trace + Managed Prometheus |
| [deployment.yaml](deployment.yaml)       | Deployment, ServiceAccount in `observability` namespace         |
| [service.yaml](service.yaml)             | ClusterIP Service for OTLP gRPC/HTTP                            |
| [kustomization.yaml](kustomization.yaml) | ConfigMap generator + resource bundle                           |

Phase 6 — see [docs/setup/13-observability-slos.md](../../../docs/setup/13-observability-slos.md).
