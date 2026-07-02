# Observability

OTel, Prometheus, Grafana, and Cloud Monitoring SLO/alert definitions for boutique-gke-sre.

## Purpose

Metrics, traces, dashboards, and SRE alerting configuration for Online Boutique on GKE.

## Layout

```
observability/
├── otel/
│   ├── collector/
│   │   ├── config.yaml          # OTel Collector pipeline config
│   │   └── deployment.yaml      # Collector Deployment manifest
│   └── README.md
├── prometheus/
│   ├── values.yaml              # kube-prometheus-stack Helm values
│   └── README.md
├── grafana/
│   ├── datasources.yaml         # Datasource provisioning
│   ├── dashboards/              # JSON dashboard exports
│   └── README.md
├── monitoring/
│   ├── slos/                    # Cloud Monitoring SLO definitions
│   ├── alert-policies/          # Burn-rate and ops alerts
│   ├── uptime-checks/           # HTTPS synthetic checks
│   ├── log-based-metrics/       # Custom SLI metrics from logs
│   └── README.md
└── README.md
```

## Public endpoints

| Service    | URL                                    |
| ---------- | -------------------------------------- |
| Storefront | https://boutique.biroltilki.art        |
| Argo CD    | https://argocd.boutique.biroltilki.art |

## Data flow

```
Online Boutique pods (OTLP)
  → OTel Collector
  → Cloud Trace + Managed Prometheus
  → Grafana dashboards + Cloud Monitoring SLOs
  → Burn-rate alerts → PagerDuty
```

## Phase

Content implemented in **Phase 6**. See [docs/setup/13-observability-slos.md](../docs/setup/13-observability-slos.md).

## GitOps

Synced via Argo CD `observability` Application under `gitops/apps/argocd-apps/`.

## Further reading

- [docs/sre/slos/catalog.md](../docs/sre/slos/catalog.md)
- [docs/sre/runbooks/README.md](../docs/sre/runbooks/README.md)
