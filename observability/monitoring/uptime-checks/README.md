# Cloud Monitoring uptime checks

HTTPS synthetic checks for public endpoints.

## Purpose

Detect total storefront and Argo CD edge failures independent of in-cluster metrics.

## Planned checks

| Check                 | URL                                            | Interval |
| --------------------- | ---------------------------------------------- | -------- |
| `boutique-storefront` | https://boutique.biroltilki.art                | 60s      |
| `argocd-ui`           | https://argocd.boutique.biroltilki.art/healthz | 300s     |

## Alert linkage

Failures route to `uptime-check-failed` alert policy → PagerDuty.

## Validation

```bash
gcloud monitoring uptime list-configs --project=boutique-gke
curl -I https://boutique.biroltilki.art
```

## Further reading

- [../README.md](../README.md)
