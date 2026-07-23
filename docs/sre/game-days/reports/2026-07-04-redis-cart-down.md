# Game day report — Redis / cart down

**Date:** 2026-07-04
**Scenario:** [03 — Redis / cart down](../03-redis-cart-down.md)
**Environment:** `boutique-gke` (production reference)
**Facilitator:** Platform owner (solo exercise)
**Severity (exercise):** Simulated SEV2 (checkout path)

## Objective

Validate cart/checkout degradation when `redis-cart` is unavailable, exercise the `redis-cart-down` runbook path, and confirm service recovery after restore.

## Baseline (pre-inject)

| Check                 | Result                         |
| --------------------- | ------------------------------ |
| `redis-cart` replicas | `1/1` Running                  |
| Storefront `curl -I`  | `HTTP 200`                     |
| Binary Authorization  | `ENFORCED_BLOCK_AND_AUDIT_LOG` |

## Inject

```bash
CONFIRM=yes ./scripts/game-days/inject-redis-down.sh
```

Scaled `redis-cart` deployment to **0** replicas in namespace `boutique`.

## Observed impact

| Signal                              | Result                                                          |
| ----------------------------------- | --------------------------------------------------------------- |
| `redis-cart` pods                   | None (scaled to 0)                                              |
| Storefront `curl -I`                | `HTTP 500` (within seconds)                                     |
| `cartservice` logs                  | `GetCartAsync` errors continued from live sessions              |
| PagerDuty / `redis-cart-down` alert | Not verified in this run (manual exercise; alert policy exists) |

**User impact:** Browse and checkout path broken — storefront returned 5xx while cart backend was down.

## Timeline (UTC)

| Time        | Event                                                                                            |
| ----------- | ------------------------------------------------------------------------------------------------ |
| 18:30       | Baseline: `redis-cart` 1/1, storefront `HTTP 200`                                                |
| 18:31       | Injected failure (`inject-redis-down.sh`)                                                        |
| 18:31       | Confirmed `redis-cart` 0/0; storefront `HTTP 500`                                                |
| 18:31       | Attempted restore: `kubectl scale deployment redis-cart --replicas=1`                            |
| 18:31–18:33 | **Restore blocked** — new pod denied by Binary Authorization (no cosign attestation on AR image) |
| 18:37       | Mitigation: Terraform targeted apply — BA `DRYRUN_AUDIT_LOG_ONLY`                                |
| 18:37       | `kubectl rollout restart deployment/redis-cart` — pod `1/1 Running`                              |
| 18:38       | Storefront `HTTP 200`; BA re-enforced `ENFORCED_BLOCK_AND_AUDIT_LOG`                             |
| 18:38       | Final validation: all deploys `1/1`, storefront healthy                                          |

**Time to detect (TTD):** Immediate (synthetic `curl` + deployment status)
**Time to restore (TTR):** ~7 minutes (including BA workaround)

## Root cause (failure inject)

Expected: `redis-cart` unavailable → `cartservice` cannot persist cart state → checkout path fails.

## Root cause (delayed restore)

`redis-cart` image in Artifact Registry (`boutique/redis-cart@sha256:18e7e25…`) lacks a cosign attestation trusted by `boutique-cosign-attestor`. The original pod was created before enforce mode; **scaling to zero forced recreation**, which Binary Authorization blocked under `ENFORCED_BLOCK_AND_AUDIT_LOG`.

## What went well

- Inject script worked as documented (`CONFIRM=yes` gate).
- Failure was immediate and visible (`HTTP 500`).
- Runbook and game-day guide steps were clear.
- Recovery validated end-to-end after DRYRUN window.

## What went poorly

- Restore via `kubectl scale` alone is **insufficient** under BA enforce without signed images.
- Game-day guide restore step does not mention BA / attestation prerequisite.
- Alert firing and PagerDuty ack were not exercised in this run.

## Action items

| Action                                                                                                  | Priority | Status |
| ------------------------------------------------------------------------------------------------------- | -------- | ------ |
| Sign `redis-cart` in `build-scan-sign` CI (or mirror workflow)                                          | P1       | Open   |
| Document BA + scale-to-zero interaction in [redis-cart-down runbook](../../runbooks/redis-cart-down.md) | P1       | Open   |
| Add restore fallback to game-day 03 guide (DRYRUN or signed image)                                      | P2       | Open   |
| Re-run scenario 03 with PagerDuty ack and `redis-cart-down` alert validation                            | P2       | Open   |

## Commands reference

```bash
# Inject
CONFIRM=yes ./scripts/game-days/inject-redis-down.sh

# Restore (requires signed image OR temporary BA DRYRUN)
kubectl scale deployment redis-cart -n boutique --replicas=1
kubectl rollout restart deployment/redis-cart -n boutique

# BA temporary DRYRUN (emergency only — used 2026-07-04)
cd terraform/environments/boutique
terraform apply -var='binary_authorization_enforcement_mode=DRYRUN_AUDIT_LOG_ONLY' \
  -target=module.binary_authorization
# ... restore pods ...
terraform apply -target=module.binary_authorization   # re-enforce from tfvars
```

## Related

- [Game day 03 guide](../03-redis-cart-down.md)
- [redis-cart-down runbook](../../runbooks/redis-cart-down.md)
- [edge-hardening.md](../../../security/edge-hardening.md) — Binary Authorization enforce mode
- **Postmortem:** [../../postmortems/2026-07-04-redis-cart-down.md](../../postmortems/2026-07-04-redis-cart-down.md)
