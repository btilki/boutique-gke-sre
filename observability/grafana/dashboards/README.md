# Grafana dashboards

JSON dashboard definitions for Online Boutique SRE views.

## Purpose

Version-controlled Grafana dashboards synced via ConfigMap + provisioning (GitOps).

## Dashboards

| File                           | UID                       | Focus                                                                     |
| ------------------------------ | ------------------------- | ------------------------------------------------------------------------- |
| `boutique-golden-signals.json` | `boutique-golden-signals` | Traffic / errors / saturation (GMP); latency deferred to Cloud Monitoring |
| `slo-overview.json`            | `boutique-slo-overview`   | SLO targets, alert→runbook links, pod Ready/restart stats                 |

## Deferred

| Dashboard           | Reason                                     |
| ------------------- | ------------------------------------------ |
| `ingress-edge.json` | Optional follow-up (Cloud Armor / LB edge) |

## Conventions

- Export / author with `"id": null` for portable imports
- Datasource UIDs must match [`../datasources.yaml`](../datasources.yaml): `gmp`, `gcm`
- Dashboard links point at runbooks under `docs/sre/runbooks/`
- Provisioned from ConfigMaps `grafana-dashboards` + `grafana-dashboard-provider` (see `kustomization.yaml`)

## Import / apply

**Preferred (rebuild):** Argo CD sync of `observability` Application — dashboards appear under folder **Boutique SRE**.

**Manual:** Grafana → Dashboards → Import → upload JSON from this directory.

**Setup guide:** [docs/setup/17-latency-slos-dashboards.md](../../../docs/setup/17-latency-slos-dashboards.md) (topic 17).

## Repo-only validation

```bash
python3 -c "import json,pathlib; [json.load(open(p)) for p in pathlib.Path('observability/grafana/dashboards').glob('*.json')]; print('ok')"
```

## Further reading

- [../README.md](../README.md)
- [docs/sre/slos/catalog.md](../../../docs/sre/slos/catalog.md)
