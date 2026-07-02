# Grafana

Dashboards and datasource provisioning for boutique-gke-sre.

## Purpose

Visualize SLIs, golden signals, and infrastructure health. Complements Cloud Monitoring SLO dashboards and PagerDuty alert routing.

## Layout

| Path               | Purpose                                                           |
| ------------------ | ----------------------------------------------------------------- |
| `datasources.yaml` | Provisioning config for Prometheus, Cloud Monitoring, Cloud Trace |
| `dashboards/`      | JSON dashboard exports (golden signals, SLO overview)             |

## Public URLs

Grafana is cluster-internal or behind IAP; storefront SLOs are also visible in Cloud Console. Storefront: https://boutique.biroltilki.art

## Dependencies

- Managed Prometheus or in-cluster Prometheus
- Workload Identity for Stackdriver datasource
- Argo CD `observability` Application

## Further reading

- [observability/README.md](../README.md)
- [docs/sre/slos/catalog.md](../../docs/sre/slos/catalog.md)
