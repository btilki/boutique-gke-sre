# Runbook: bad deploy rollback

**Alert policy:** `bad-deploy-rollback` (deploy failure / error-rate spike)
**Severity:** SEV2–SEV3
**Architecture:** [Deployment flow §7](../../architecture/overview.md#7-deployment-flow)

## Purpose

Restore service health after a faulty GitOps deploy (bad digest, config, or Helm values).

## When to use

- Error-rate SLO burn after Argo CD sync
- Failed rollout; pods CrashLoopBackOff after manifest change
- Game day scenario 01

## Prerequisites

- `kubectl` access to cluster
- Argo CD UI: https://argocd.boutique.biroltilki.art

## Steps

1. Confirm impact: `curl -I https://boutique.biroltilki.art`; check Argo CD app health
2. Identify last good commit (digest in `gitops/apps/boutique/values-images.yaml`)
3. Revert PR or `git revert` the bad merge on `main`
4. **Manual Argo CD sync** the `boutique` Application
5. Verify pods: `kubectl get pods -n boutique`
6. Smoke test storefront and checkout flow

## Validation

```bash
curl -I https://boutique.biroltilki.art
kubectl get pods -n boutique
```

## Escalation

SEV2 if checkout unavailable > 15 min → [severity.md](../incident-response/severity.md)

## Further reading

- [Game day 01](../game-days/01-bad-deploy-rollback.md)
- [operations/rollback.md](../../operations/rollback.md)
