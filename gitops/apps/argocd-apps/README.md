# Argo CD Applications

Application CRs consumed by the app-of-apps root (`gitops/bootstrap/root-app.yaml`).

| File | Sync target |
|------|-------------|
| `boutique-application.yaml` | Online Boutique Helm chart |
| `policies-application.yaml` | Kyverno + NetworkPolicy |
| `observability-application.yaml` | OTel, Prometheus, Grafana |

All Applications use **manual sync** (ADR 003).
