# SRE practices — error budget, capacity, toil

## Goal

Adopt the operating rhythm: weekly error-budget reviews, capacity decisions from the documented baseline, orphan-scan hygiene, and CI runbook-lint. Artifacts are already in Git — this guide is how to **run** them after a rebuild (and how to practice them while the project is offline).

**Repo status:** Checklists, freeze log, capacity baseline, load stub, orphan cadence, and CI lint are ready. No live GCP required to keep the repo complete.

## Why this step is required

Policies without rituals drift. Topic 20 turns [error-budget-policy.md](../sre/error-budget-policy.md), HA defaults, and teardown scripts into a repeatable cadence so the platform stays operable — not documentation-only.

## Prerequisites

- Preferred live: topics **13–14** (SLOs + PagerDuty) so budget % is real
- Repo-only practice: fill weekly review with “N/A — cluster down” notes
- Tools: browser (GitHub issues), optional `gcloud` / `kubectl` / `curl` when live
- Artifacts present:
  - `docs/sre/error-budget/weekly-review.md`, `freeze-log.md`
  - `.github/ISSUE_TEMPLATE/error_budget_freeze.md`
  - `docs/sre/capacity/baseline.md`
  - `scripts/load/smoke-browse.sh`
  - `docs/operations/orphan-scan-cadence.md`
  - `make runbook-lint` (also in `.github/workflows/ci.yml`)

## Commands

### 1. Weekly error-budget review

1. Copy or edit [weekly-review.md](../sre/error-budget/weekly-review.md) for the current week
2. If live: Cloud Monitoring → SLOs → record remaining %
3. Map to band (normal / cautious / freeze / exhausted)
4. If &lt; 25%: open issue from **Error budget freeze** template; append [freeze-log.md](../sre/error-budget/freeze-log.md)
5. Send comms if cautious/freeze ([error-budget-policy.md](../sre/error-budget-policy.md))

### 2. Capacity check (as needed)

```bash
# Live cluster
kubectl get hpa,pdb,deploy -n boutique
kubectl top nodes
kubectl top pods -n boutique
```

Decide using [capacity/baseline.md](../sre/capacity/baseline.md). Prefer GitOps HPA / Terraform node pool over ad-hoc `kubectl scale`.

Optional signal generation (agreed window only):

```bash
./scripts/load/smoke-browse.sh
# STOREFRONT_URL=https://boutique.biroltilki.art REQUESTS=50 ./scripts/load/smoke-browse.sh
```

### 3. Orphan scan (weekly if live; always around teardown)

```bash
export PROJECT_ID=boutique-gke
./scripts/teardown/orphan-resource-scan.sh
# or: make orphan-scan-help
```

Follow [orphan-scan-cadence.md](../operations/orphan-scan-cadence.md) — **report only**, no auto-delete.

### 4. Repo toil gate (always)

```bash
make runbook-lint
```

CI runs the same check on PRs to `main`.

## Expected output

- Weekly review filled (or explicitly deferred with reason)
- Freeze issues + freeze-log rows when budget requires it
- Capacity changes via PR, aligned with baseline
- Orphan scan notes when the project is live
- Green `make runbook-lint` / CI

## Validation

**Repo (always):**

```bash
test -f docs/sre/error-budget/weekly-review.md
test -f docs/sre/capacity/baseline.md
test -f docs/operations/orphan-scan-cadence.md
make runbook-lint
```

**Live (after rebuild):**

```bash
# Budget UI has data
# kubectl get hpa -n boutique
# ./scripts/teardown/orphan-resource-scan.sh
curl -I https://boutique.biroltilki.art
```

## Common problems

| Symptom                              | Cause                             | Fix                                    |
| ------------------------------------ | --------------------------------- | -------------------------------------- |
| Budget N/A                           | No SLI traffic / SLOs not created | Topics 13 / 17; generate traffic       |
| Freeze declared in chat only         | Process skip                      | Open freeze issue + freeze-log row     |
| Pending pods ignored                 | No capacity review                | Use baseline “when to scale” table     |
| Orphan scan empty while still billed | Wrong project / filters           | Confirm `PROJECT_ID`; re-read teardown |
| CI runbook-lint fails                | Registry/YAML/runbook drift       | Fix before merge                       |

## Recovery

- Exit freeze: budget &gt; 25% + platform lead sign-off → freeze-log **Exited** + close issue
- Bad capacity change: revert GitOps/Terraform PR; sync / apply
- False orphan alarm: document exception in weekly notes

## Best practices

- Keep freeze-log append-only
- Do not run load scripts during freeze without approval
- Prefer detection automation over mutation (ADR-003 manual Argo sync)
- Schedule quarterly game days separately (topic 18)

## Security notes

- Freeze exceptions for security patches must be documented
- Orphan scan output may list resource names — treat as internal
- Never commit PagerDuty keys or load-test credentials

## Next step

| Step                                     | Guide                                                                                                               |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Latency / operability / IaC (if rebuild) | [17](17-latency-slos-dashboards.md), [18](18-sre-operability-game-days.md), [19](19-monitoring-backup-terraform.md) |
| Day-2 cadence                            | [day-2-ops.md](../operations/day-2-ops.md)                                                                          |
| On-call                                  | [oncall/README.md](../sre/oncall/README.md)                                                                         |
| Optional C2                              | SLO burn policies in Terraform — [ROADMAP.md](../../ROADMAP.md)                                                     |

Phases **9-A–9-D** are complete in-repo. Remaining optional work is tracked on the roadmap (C2, Chaos Mesh, etc.).
