# Day-2 operations

> **Offline until rebuild:** Hostnames and the GKE cluster from the closed reference are gone. `curl` / `dig` checks below apply only after you rebuild ([setup/README.md](../setup/README.md)). While offline, expect empty DNS and failed HTTPS.

## Purpose

Ongoing operational tasks after initial bootstrap: certificate renewal, digest promotions, capacity, and platform hygiene.

## When to use

- Regular platform engineer shifts on a **live** rebuild
- After Phase 6 observability is live
- Before and after application manifest changes

## Prerequisites

- Bootstrap complete per [bootstrap.md](../bootstrap.md) (live cluster)
- Access: `kubectl`, `gcloud`, Argo CD (`argocd.boutique.biroltilki.art`)
- Storefront: `boutique.biroltilki.art`

## Architecture

Day-2 work spans Terraform (infra), GitOps (apps/policies), and Cloud Monitoring (SLOs). Changes flow Git → CI → manual Argo CD sync → validation.

## Step-by-step implementation

1. **Weekly:** Fill [error-budget/weekly-review.md](../sre/error-budget/weekly-review.md); review SLOs; run [orphan-scan-cadence.md](orphan-scan-cadence.md) if the GCP project is live
2. **On digest PR merge:** Manual sync `boutique` Application in Argo CD
3. **Monthly:** Review Kyverno policy reports and failed admissions
4. **Quarterly:** Rotate non-WIF credentials; verify backup restore drill when topic 19 GKE Backup is enabled (optional after rebuild)
5. **As needed:** Scale per [sre/capacity/baseline.md](../sre/capacity/baseline.md); open [error_budget_freeze](../../.github/ISSUE_TEMPLATE/error_budget_freeze.md) if budget &lt; 25%

## Validation

**After rebuild only:**

```bash
curl -I https://boutique.biroltilki.art
kubectl get applications -n argocd
gcloud monitoring slos list --project=boutique-gke
```

Expected (live): HTTP 200 on storefront; Argo CD apps Healthy/Synced.
Expected (offline now): empty `dig +short` and failed HTTPS — see [dns.md](../dns.md).

## Troubleshooting

| Symptom             | Cause                           | Fix                                      |
| ------------------- | ------------------------------- | ---------------------------------------- |
| Cert expiry warning | Managed cert provisioning delay | [dns.md](../dns.md), re-check ingress    |
| Sync drift          | Manual cluster edits            | Revert; sync from Git                    |
| SLO burn            | Deploy or dependency fault      | Matching runbook in `docs/sre/runbooks/` |

## Common mistakes

- Auto-syncing Argo CD in production (violates ADR-003)
- Patching cluster resources without Git follow-up
- Ignoring burn-rate alerts during business hours

## Best practices

- All changes via PR; digest-only images
- Link incidents to runbooks and postmortems
- Schedule Game day exercises before major dependency upgrades (closed path: Game day 03 only; see [STATUS](../sre/game-days/reports/STATUS.md))

## Production considerations

- Change windows for checkout-path deploys
- PDBs and HPA configured in Helm chart: `frontend` / `checkoutservice` HPA; PDBs on frontend, checkout, cart, redis-cart — see [boutique README](../../gitops/apps/boutique/README.md)
- `redis-cart` remains single-replica (no Redis HA); PDB protects voluntary eviction only
- Cloud Armor rule changes need smoke validation

## Security considerations

- Supply-chain CI uses WIF; no SA keys in GitHub
- ESO-only secrets; audit Secret Manager access
- Binary Authorization cluster rule in place; Enforce only after topic 16 ([edge-hardening.md](../security/edge-hardening.md)) — project default stays allow + dry-run

## Further reading

- [operations/rollback.md](rollback.md)
- [sre/error-budget-policy.md](../sre/error-budget-policy.md)
- [setup/README.md](../setup/README.md)
