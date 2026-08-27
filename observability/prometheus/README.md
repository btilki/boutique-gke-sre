# Prometheus (optional reference)

In-cluster Prometheus is **not** part of the GitOps observability Application. Production metrics path is **OTel Collector → GMP** (**Google Managed Prometheus**) plus Cloud Monitoring SLOs.

This directory holds optional `kube-prometheus-stack` Helm values if you later add an in-cluster Prometheus for ServiceMonitors. Do not treat it as a required bootstrap step.

## Purpose

Reference Helm values only. The Argo CD `observability` app (`observability/kustomization.yaml`) syncs **OTel + Grafana** — not this chart.

## Layout

| Path          | Purpose                                          |
| ------------- | ------------------------------------------------ |
| `values.yaml` | Optional Helm values for `kube-prometheus-stack` |

## Dependencies

- Not required for topics 13–20
- If installed later: GKE cluster + `observability` namespace with `network-policy.biroltilki.art/tier: platform`

## Usage

```bash
# Optional — not the production GitOps path
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n observability -f observability/prometheus/values.yaml
```

## Validation

Skip unless you installed the optional chart. Production check is OTel + Grafana:

```bash
kubectl get pods -n observability -l app.kubernetes.io/name=otel-collector
kubectl get pods -n observability -l app.kubernetes.io/name=grafana
```

## Further reading

- [observability/README.md](../README.md)
- [docs/setup/13-observability-slos.md](../../docs/setup/13-observability-slos.md)
