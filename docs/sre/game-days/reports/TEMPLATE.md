# Game day report — [SCENARIO TITLE]

**Date:** YYYY-MM-DD
**Scenario:** e.g. [01 — Bad deploy rollback](../01-bad-deploy-rollback.md) (link the scenario you ran)
**Environment:** `boutique-gke` (production reference) | tabletop / deferred
**Facilitator:**
**Participants:**
**Severity (exercise):** Simulated SEV[1-4]

## Objective

_What this exercise validates (alerts, runbook, rollback, recovery)._

## Baseline (pre-inject)

| Check                           | Result |
| ------------------------------- | ------ |
| Storefront `curl -I`            |        |
| Argo CD / key workloads         |        |
| Relevant alert policies enabled |        |

## Inject

```bash
# Exact command or PR + sync steps used
```

_Describe what changed (replicas, digest, test alert, etc.)._

## Observed impact

| Signal                              | Result |
| ----------------------------------- | ------ |
| User-facing (storefront / checkout) |        |
| Kubernetes / Argo CD                |        |
| Alert / PagerDuty                   |        |
| SLO / burn (if relevant)            |        |

**User impact:** _One sentence._

## Timeline (UTC)

| Time | Event              |
| ---- | ------------------ |
|      | Baseline           |
|      | Inject             |
|      | Detection          |
|      | Mitigation started |
|      | Resolved / cleanup |

**Time to detect (TTD):**
**Time to restore (TTR):**

## Root cause (failure inject)

_Expected failure mode for this scenario._

## What went well

-

## What went poorly

-

## Action items

| Action | Owner | Priority | Status |
| ------ | ----- | -------- | ------ |
|        |       | P1/P2/P3 | Open   |

## Commands reference

```bash
# Inject / restore / validation commands actually used
```

## Related

- Scenario guide: `../NN-slug.md`
- Runbook(s):
- Postmortem (if gaps warrant): `../../postmortems/`

---

Copy this file to `YYYY-MM-DD-<scenario-slug>.md` after each live or tabletop run. Update [STATUS.md](STATUS.md) and the reports index.
