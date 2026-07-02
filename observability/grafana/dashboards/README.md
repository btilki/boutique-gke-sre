# Grafana dashboards

JSON dashboard definitions for Online Boutique SRE views.

## Purpose

Version-controlled Grafana dashboards synced via ConfigMap sidecar or GitOps.

## Planned dashboards

| Dashboard                      | Focus                                            |
| ------------------------------ | ------------------------------------------------ |
| `boutique-golden-signals.json` | Latency, traffic, errors, saturation per service |
| `slo-overview.json`            | Browse/checkout SLO burn and error budget        |
| `ingress-edge.json`            | HTTPS edge, Cloud Armor, LB health               |

## Conventions

- Export dashboards with `"id": null` for portable imports
- Use Managed Prometheus or Cloud Monitoring datasource UIDs consistent with `datasources.yaml`
- Link panels to runbooks in `docs/sre/runbooks/`

## Further reading

- [../README.md](../README.md)
