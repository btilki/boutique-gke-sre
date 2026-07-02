# Game day 03 — Redis / cart down

## Purpose

Exercise checkout/cart degradation when Redis cart is unavailable.

## When to use

Scheduled game day; alert `redis-cart-down` and runbook [redis-cart-down.md](../runbooks/redis-cart-down.md).

## Prerequisites

- Script: `scripts/game-days/inject-redis-down.sh`
- PagerDuty integration live
- Checkout SLO dashboards ready

## Architecture

Cart service depends on `redis-cart` Deployment. Scaling to zero simulates datastore outage; checkout path should fail or degrade measurably.

## Step-by-step implementation

1. Baseline browse and checkout at https://boutique.biroltilki.art
2. Inject failure:
   ```bash
   CONFIRM=yes ./scripts/game-days/inject-redis-down.sh
   ```
3. Attempt add-to-cart / checkout; confirm user impact
4. Verify alert and on-call runbook execution
5. **Restore:**
   ```bash
   kubectl scale deployment redis-cart -n boutique --replicas=1
   ```
6. Validate checkout recovery

## Validation

```bash
kubectl get deploy redis-cart -n boutique
# Manual checkout smoke test on storefront
```

## Troubleshooting

| Symptom       | Cause             | Fix                           |
| ------------- | ----------------- | ----------------------------- |
| No alert      | Cart still cached | Clear session; retry checkout |
| Slow recovery | PVC attach delay  | Check Redis pod events        |

## Common mistakes

- Forgetting restore step (leaves cart broken)
- Running outside game-day window

## Best practices

- Time-box exercise; explicit restore in run log
- Secondary validates checkout path

## Production considerations

- Checkout SLO most sensitive; prefer low-traffic window

## Security considerations

- No data destruction; scale only

## Further reading

- [runbooks/redis-cart-down.md](../runbooks/redis-cart-down.md)
- [runbooks/redis-restore.md](../runbooks/redis-restore.md)
