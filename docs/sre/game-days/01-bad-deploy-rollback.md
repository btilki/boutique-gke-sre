# Game day 01 — Bad deploy rollback

## Purpose

Exercise detection and rollback when a faulty GitOps deploy degrades `boutique.biroltilki.art`.

## When to use

Scheduled game day; pairs with runbook [bad-deploy-rollback.md](../runbooks/bad-deploy-rollback.md).

## Prerequisites

- Argo CD: `argocd.boutique.biroltilki.art`
- Ability to merge/revert PR on `main`
- PagerDuty routing configured

## Architecture

Fault injection: introduce benign misconfiguration (e.g. bad env var) via PR → merge → manual sync → observe burn/error rate → revert.

## Step-by-step implementation

1. Record baseline: `curl -I `boutique.biroltilki.art``
2. Open PR with intentional non-fatal misconfig (documented in game-day log)
3. Merge; **manual Argo CD sync** `boutique` Application
4. Confirm alert `bad-deploy-rollback` or error-rate spike
5. On-call executes runbook: revert commit, sync, smoke test
6. Record time-to-detect and time-to-recover

## Validation

```bash
curl -I https://boutique.biroltilki.art
kubectl get pods -n boutique
argocd app get boutique
```

## Troubleshooting

| Symptom             | Cause              | Fix                                    |
| ------------------- | ------------------ | -------------------------------------- |
| No alert            | Threshold too high | Tune policy; see game day 04           |
| Sync won't rollback | Kyverno deny       | Fix manifest per troubleshooting guide |

## Common mistakes

- Injecting fatal image digest (use config-only fault)
- Skipping manual sync step

## Best practices

- Pre-approve fault PR in game-day doc
- Secondary on-call observes

## Production considerations

- Run in agreed window; comms per [incident-response/comms.md](../incident-response/comms.md)

## Security considerations

- No real secrets in fault PR

## Further reading

- [operations/rollback.md](../../operations/rollback.md)
- [ADR-003](../../adr/003-manual-argocd-sync.md)
- After run: copy [reports/TEMPLATE.md](reports/TEMPLATE.md) → dated report; update [reports/STATUS.md](reports/STATUS.md)
- Status: **Deferred** until cluster rebuild — [STATUS.md](reports/STATUS.md)
