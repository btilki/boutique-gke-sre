# Game day 02 — Zone / pod failure

## Purpose

Validate resilience when a pod is deleted or a zone is stressed (node loss).

## When to use

Scheduled game day after PDBs and multi-replica deploys are live.

## Prerequisites

- `kubectl` access
- Script: `scripts/game-days/inject-pod-failure.sh`
- Runbook: general pod recovery in cluster ops

## Architecture

Kubernetes recreates pods; PDBs limit simultaneous disruption. HPA and cluster autoscaler may react to capacity pressure.

## Step-by-step implementation

1. Notify on-call; note baseline latency at https://boutique.biroltilki.art
2. Run injection:
   ```bash
   CONFIRM=yes NAMESPACE=boutique DEPLOYMENT=frontend \
     ./scripts/game-days/inject-pod-failure.sh
   ```
3. Watch pod recovery: `kubectl get pods -n boutique -w`
4. Confirm browse SLO stable or alert if not
5. Optional: cordon/drain node in non-prod window (advanced)

## Validation

```bash
kubectl get pods -n boutique -o wide
curl -I https://boutique.biroltilki.art
```

Expected: new pod Running; storefront HTTP 200.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Pending pod | Insufficient capacity | Check cluster autoscaler |
| Repeated crashes | Bad image on new node | Check events |

## Common mistakes

- Deleting all replicas at once
- Running without `CONFIRM=yes`

## Best practices

- Target single replica first
- Document zone distribution before/after

## Production considerations

- GKE regional cluster survives single zone loss; validate over time

## Security considerations

- Script requires explicit confirmation

## Further reading

- [scripts/game-days/README.md](../../../scripts/game-days/README.md)
