# Argo CD sync failures

## Purpose

Diagnose and resolve GitOps sync errors for Applications managed at https://argocd.boutique.biroltilki.art.

## When to use

- Application status `Degraded`, `Unknown`, or repeated `SyncFailed`
- Post-merge manifest not reaching cluster
- Game day 01 rollback blocked by sync error

## Prerequisites

- Argo CD UI or CLI access
- `kubectl` context to boutique-gke cluster
- Recent PR merged to `main` affecting `gitops/`

## Architecture

Argo CD pulls from GitHub → compares to cluster → sync applies manifests. Kyverno may deny resources after sync render. Manual sync per [ADR-003](../adr/003-manual-argocd-sync.md).

## Step-by-step implementation

1. Open Argo CD → select failing Application → **APP DETAILS** → **CONDITIONS**
2. Read sync error message (Helm, K8s API, or permission)
3. `kubectl get events -n <target-namespace> --sort-by='.lastTimestamp'`
4. If `OutOfSync` only: review diff; intentional drift → revert cluster or update Git
5. **Manual Sync** with prune disabled first; enable prune only after review
6. Re-check https://boutique.biroltilki.art

## Validation

```bash
argocd app get boutique
kubectl get pods -n boutique
curl -I https://boutique.biroltilki.art
```

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `permission denied` | Argo CD SA RBAC | Check `argocd` clusterrole bindings |
| Helm template error | Invalid values.yaml | Fix chart locally; `helm template` |
| Resource quota | Namespace limits | Scale down or raise quota |
| Kyverno deny | Policy violation | [kyverno-denials.md](kyverno-denials.md) |

## Common mistakes

- Force sync with prune during incident without reviewing deleted resources
- Editing live manifests instead of Git

## Best practices

- Reproduce with `argocd app diff`
- Sync platform apps before boutique app

## Production considerations

- Manual sync gate prevents surprise deploys
- Document sync time in change record

## Security considerations

- Argo CD admin behind HTTPS and strong auth
- No cluster-admin for routine operators

## Further reading

- [sre/runbooks/bad-deploy-rollback.md](../sre/runbooks/bad-deploy-rollback.md)
- [operations/rollback.md](../operations/rollback.md)
