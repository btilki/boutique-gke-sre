# Runbook: Redis / cart down

**Alert policy:** `redis-cart-down`  
**Architecture:** [Failure scenarios §10](../../architecture/overview.md#10-failure-scenarios)

> Full steps expanded in Phase 7; game day 03.

## Purpose

Restore cart and checkout when Redis or `cartservice` is unavailable.

## Initial triage

1. `kubectl get pods -n boutique -l app=redis-cart` (or cart Redis workload name)
2. `kubectl logs -n boutique -l app=cartservice --tail=50`
3. Test add-to-cart on storefront

## Mitigation

1. Restart Redis StatefulSet if corrupt pod state
2. Scale `cartservice` if HPA capped
3. Restore from backup if data loss — [redis-restore.md](redis-restore.md)

## Further reading

- [Game day 03](../game-days/03-redis-cart-down.md)
