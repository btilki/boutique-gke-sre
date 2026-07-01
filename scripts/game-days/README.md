# Game-day scripts

Failure injection helpers for Phase 7 game days. **Not** for production use outside scheduled exercises.

## Purpose

Automate controlled fault injection referenced by [docs/sre/game-days/](../../docs/sre/game-days/).

## Scripts

| Script | Scenario | Guide |
|--------|----------|-------|
| `inject-pod-failure.sh` | Single pod delete / zone stress | [02-zone-pod-failure.md](../../docs/sre/game-days/02-zone-pod-failure.md) |
| `inject-redis-down.sh` | Scale Redis cart to zero | [03-redis-cart-down.md](../../docs/sre/game-days/03-redis-cart-down.md) |

## Safety

All scripts require `CONFIRM=yes`. Read safety comments at the top of each script before running.

## Prerequisites

- `kubectl` context pointing at boutique-gke cluster
- On-call notified per [docs/sre/oncall/README.md](../../docs/sre/oncall/README.md)

## Further reading

- [scripts/README.md](../README.md)
