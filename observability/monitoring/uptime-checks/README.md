# Cloud Monitoring uptime checks

HTTPS synthetic checks for public endpoints.

## Purpose

Detect total storefront and Argo CD edge failures independent of in-cluster metrics.

## Checks

| Check                 | URL                                      | Interval | Status                                               |
| --------------------- | ---------------------------------------- | -------- | ---------------------------------------------------- |
| `boutique-storefront` | `boutique.biroltilki.art`                | 60s      | Applied historically (topic 13); recreate on rebuild |
| `argocd-ui`           | `argocd.boutique.biroltilki.art/healthz` | 300s     | **Ready in repo** — apply via topic 18               |

Reference YAML:

- [boutique-storefront.yaml](boutique-storefront.yaml)
- [argocd-ui.yaml](argocd-ui.yaml)

## Alert linkage

Both checks feed **`uptime-check-failed`** (OR combiner) → PagerDuty → [uptime-check-failed.md](../../../docs/sre/runbooks/uptime-check-failed.md).

| Script                                  | Role                                                              |
| --------------------------------------- | ----------------------------------------------------------------- |
| `scripts/create-uptime-check.sh`        | Storefront check + initial alert policy (topic 13)                |
| `scripts/create-argocd-uptime-check.sh` | Argo CD check; add second condition to existing policy (topic 18) |

## Validation

```bash
gcloud monitoring uptime list-configs --project=boutique-gke \
  --format='table(displayName,httpCheck.path,period)'
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art/healthz
```

## Further reading

- [../README.md](../README.md)
- [docs/setup/18-sre-operability-game-days.md](../../../docs/setup/18-sre-operability-game-days.md) — topic 18
