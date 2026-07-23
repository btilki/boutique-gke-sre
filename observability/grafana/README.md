# Grafana

Dashboards and datasource provisioning for boutique-gke-sre.

## Purpose

Visualize SLIs, golden signals, and infrastructure health. Complements Cloud Monitoring SLO dashboards and PagerDuty alert routing.

## Layout

| Path                       | Purpose                                        |
| -------------------------- | ---------------------------------------------- |
| `datasources.yaml`         | Provisioning config for GMP + Cloud Monitoring |
| `dashboards-provider.yaml` | File provider → `/var/lib/grafana/dashboards`  |
| `deployment.yaml`          | Deployment, ServiceAccount (Workload Identity) |
| `service.yaml`             | ClusterIP Service (port 80 → Grafana 3000)     |
| `kustomization.yaml`       | ConfigMap generators + resource bundle         |
| `dashboards/`              | JSON dashboards (golden signals, SLO overview) |

## GCP service account

`grafana@boutique-gke.iam.gserviceaccount.com` — `roles/monitoring.viewer` + Workload Identity binding to `observability/grafana`.

## Admin credentials (ESO — not plain kubectl Secret)

Kyverno `block-plain-secrets` denies manual `kubectl create secret`. Store credentials in **Secret Manager**, then sync via `ExternalSecret`:

```bash
# Replace with a strong password; never commit this value
read -s GRAFANA_PASSWORD
echo -n "{\"admin-user\":\"admin\",\"admin-password\":\"${GRAFANA_PASSWORD}\"}" | \
  gcloud secrets create grafana-admin \
    --project=boutique-gke \
    --replication-policy=automatic \
    --data-file=-
```

If the secret already exists, add a new version instead:

```bash
read -s GRAFANA_PASSWORD
echo -n "{\"admin-user\":\"admin\",\"admin-password\":\"${GRAFANA_PASSWORD}\"}" | \
  gcloud secrets versions add grafana-admin --data-file=-
```

`external-secret.yaml` materializes Kubernetes Secret `grafana-admin` in `observability`.

## Public URLs

Grafana is cluster-internal or behind IAP; storefront SLOs are also visible in Cloud Console. Storefront: `boutique.biroltilki.art`

## Dependencies

- Managed Prometheus or in-cluster Prometheus
- Workload Identity for Stackdriver datasource
- Argo CD `observability` Application

## Further reading

- [observability/README.md](../README.md)
- [docs/sre/slos/catalog.md](../../docs/sre/slos/catalog.md)
- [dashboards/README.md](dashboards/README.md)
- [docs/setup/17-latency-slos-dashboards.md](../../docs/setup/17-latency-slos-dashboards.md)
