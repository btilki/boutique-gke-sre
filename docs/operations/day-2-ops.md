# Day-2 operations

## Purpose

Ongoing operational tasks after initial bootstrap: certificate renewal, digest promotions, capacity, and platform hygiene.

## When to use

- Regular platform engineer shifts
- After Phase 6 observability is live
- Before and after production manifest changes

## Prerequisites

- Bootstrap complete per [bootstrap.md](../bootstrap.md)
- Access: `kubectl`, `gcloud`, Argo CD (https://argocd.boutique.biroltilki.art)
- Storefront: https://boutique.biroltilki.art

## Architecture

Day-2 work spans Terraform (infra), GitOps (apps/policies), and Cloud Monitoring (SLOs). Changes flow Git → CI → manual Argo CD sync → validation.

## Step-by-step implementation

1. **Weekly:** Review SLO dashboards and error budget in Cloud Monitoring
2. **On digest PR merge:** Manual sync `boutique` Application in Argo CD
3. **Monthly:** Review Kyverno policy reports and failed admissions
4. **Quarterly:** Rotate non-WIF credentials; verify backup restore drill
5. **As needed:** Scale node pools via Terraform or HPA tuning in Helm values

## Validation

```bash
curl -I https://boutique.biroltilki.art
kubectl get applications -n argocd
gcloud monitoring slos list --project=boutique-gke
```

Expected: HTTP 200 on storefront; Argo CD apps Healthy/Synced.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Cert expiry warning | Managed cert provisioning delay | [dns.md](../dns.md), re-check ingress |
| Sync drift | Manual cluster edits | Revert; sync from Git |
| SLO burn | Deploy or dependency fault | Matching runbook in `docs/sre/runbooks/` |

## Common mistakes

- Auto-syncing Argo CD in production (violates ADR-003)
- Patching cluster resources without Git follow-up
- Ignoring burn-rate alerts during business hours

## Best practices

- All changes via PR; digest-only images
- Link incidents to runbooks and postmortems
- Run game days before major dependency upgrades

## Production considerations

- Change windows for checkout-path deploys
- PDBs and HPA already configured in Helm chart
- Cloud Armor rule changes need smoke validation

## Security considerations

- WIF-only CI; no SA keys in GitHub
- ESO-only secrets; audit Secret Manager access
- Binary Authorization enforced at deploy

## Further reading

- [operations/rollback.md](rollback.md)
- [sre/error-budget-policy.md](../sre/error-budget-policy.md)
- [setup/README.md](../setup/README.md)
