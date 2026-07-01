# Prometheus

In-cluster Prometheus for Kubernetes and application metrics.

## Purpose

Scrape ServiceMonitors/PodMonitors from the boutique namespace and platform components. Optionally remote-write to Google Managed Prometheus.

## Layout

| Path | Purpose |
|------|---------|
| `values.yaml` | Helm values for `kube-prometheus-stack` |

## Dependencies

- GKE cluster
- Argo CD or Helm release in `observability` namespace
- ServiceMonitor CRDs from kube-prometheus-stack

## Usage

```bash
# Reference only — production path is GitOps sync
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n observability -f observability/prometheus/values.yaml
```

## Validation

```bash
kubectl get pods -n observability -l app.kubernetes.io/name=prometheus
kubectl port-forward -n observability svc/prometheus-kube-prometheus-prometheus 9090:9090
```

## Further reading

- [observability/README.md](../README.md)
- [docs/setup/13-observability-slos.md](../../docs/setup/13-observability-slos.md)
