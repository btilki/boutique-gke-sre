# Postmortem: Redis cart down game day — restore blocked by Binary Authorization

**Date:** 2026-07-04
**Severity:** SEV2 (exercise) — checkout / storefront unavailable during inject; extended by BA deny on restore
**Authors:** Platform owner (solo game day)
**Type:** Game day follow-up (not an unplanned production incident)
**Related report:** [game-days/reports/2026-07-04-redis-cart-down.md](../game-days/reports/2026-07-04-redis-cart-down.md)

## Summary

During game day 03 (Redis / cart down), scaling `redis-cart` to zero correctly broke the storefront (`HTTP 500`). Restore via `kubectl scale` failed for ~6 minutes because Binary Authorization enforce mode rejected the recreated pod: the Artifact Registry image lacked a trusted cosign attestation. Service was restored after a temporary BA DRYRUN window, then enforce was re-enabled. PagerDuty / `redis-cart-down` alert acknowledgment was not exercised.

## Impact

- **Duration:** ~7 minutes user-visible impact (18:31–18:38 UTC), including BA workaround
- **Users affected:** Anyone hitting `boutique.biroltilki.art` during the window (reference environment; solo exercise)
- **SLO / error budget consumed:** Browse and checkout availability would have burned during 5xx window; not formally measured in this exercise
- **Secondary impact:** Temporary BA policy softening (`DRYRUN_AUDIT_LOG_ONLY`) — accepted risk for restore, then reversed

## Timeline (UTC)

| Time        | Event                                                                                |
| ----------- | ------------------------------------------------------------------------------------ |
| 18:30       | Baseline: `redis-cart` 1/1, storefront `HTTP 200`, BA `ENFORCED_BLOCK_AND_AUDIT_LOG` |
| 18:31       | Inject: `CONFIRM=yes ./scripts/game-days/inject-redis-down.sh` → replicas 0          |
| 18:31       | Detection: storefront `HTTP 500`; `redis-cart` gone                                  |
| 18:31       | Mitigation started: `kubectl scale deployment redis-cart --replicas=1`               |
| 18:31–18:33 | New pod denied by Binary Authorization (missing cosign attestation)                  |
| 18:37       | BA set to `DRYRUN_AUDIT_LOG_ONLY` via Terraform targeted apply                       |
| 18:37       | `kubectl rollout restart deployment/redis-cart` → 1/1 Running                        |
| 18:38       | Storefront `HTTP 200`; BA re-enforced                                                |
| 18:38       | Resolved — final validation healthy                                                  |

**TTD:** Immediate (synthetic curl + deployment status)
**TTR:** ~7 minutes (including BA policy change)

## Root cause

### Why the user path failed (expected inject)

1. Cart state depends on `redis-cart`.
2. Scaling Redis to zero removes that dependency.
3. `cartservice` cannot serve cart → frontend returns 5xx.

### Why restore was delayed (unexpected)

1. Why was the new pod denied? → Binary Authorization enforce requires attested images.
2. Why no attestation? → `redis-cart` image in AR was not signed/attested by the trusted attestor in CI/mirror path.
3. Why did the old pod work? → It was created before enforce (or under a prior policy); it was not recreated until scale-to-zero.
4. Why did scale-to-zero matter? → It forced Admission of a new pod against current BA policy.
5. Why was the runbook incomplete? → Restore steps assumed `kubectl scale` alone was sufficient and did not document BA / attestation as a restore prerequisite.

**Blameless framing:** Policy worked as designed. The gap was operational readiness (signed images + runbook coverage), not “BA misconfiguration.”

## What went well

- Inject script and confirmation gate worked
- Failure mode was immediate and obvious
- Game day produced a clear timeline and action list
- Enforce was restored after the emergency DRYRUN window

## What went poorly

- Restore path under BA enforce was not rehearsed before the game day
- Alert → PagerDuty → runbook path was skipped
- Game day 03 / redis runbook lacked BA scale-to-zero guidance at the time of the exercise

## Action items

| Action                                                                                                                 | Owner    | Due                      | Priority | Status |
| ---------------------------------------------------------------------------------------------------------------------- | -------- | ------------------------ | -------- | ------ |
| Ensure `redis-cart` (and platform Redis image) is cosign-signed/attested in CI or mirror workflow                      | Platform | On next rebuild          | P1       | Open   |
| Document BA + scale-to-zero in [redis-cart-down.md](../runbooks/redis-cart-down.md)                                    | SRE      | Follow-up                | P1       | Open   |
| Add restore fallback (signed image or emergency DRYRUN) to [03-redis-cart-down.md](../game-days/03-redis-cart-down.md) | SRE      | Follow-up                | P2       | Open   |
| Re-run GD03 with PagerDuty ack + `redis-cart-down` alert validation                                                    | On-call  | After rebuild (topic 18) | P2       | Open   |

## Lessons learned

- Scale-to-zero under Binary Authorization is a **recreate**, not a wake-up — attested digests are restore prerequisites.
- Game days should explicitly include **alert routing** criteria, or record “not in scope” before inject.
- Temporary BA DRYRUN is a valid break-glass for game days / incidents if time-boxed and re-enforced in the same exercise.
- A game day report should promote to a postmortem when restore surprises appear — this document is that promotion.

## Related

- [Game day report](../game-days/reports/2026-07-04-redis-cart-down.md)
- [STATUS.md](../game-days/reports/STATUS.md)
- [edge-hardening.md](../../security/edge-hardening.md)
- [TEMPLATE.md](TEMPLATE.md)
