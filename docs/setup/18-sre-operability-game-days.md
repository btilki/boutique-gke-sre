# SRE operability — HA sync, Argo uptime, game days

## Goal

On a rebuilt cluster, sync Boutique **HPA/PDB/replica** defaults, add the **Argo CD uptime check**, and run (or schedule) remaining **game days** with dated reports. When complete, operability claims match the live system — not docs-only HA.

**Repo status:** GitOps HA, uptime YAML, postmortem, and report templates already exist. This guide is the **future apply / execution** path.

## Why this step is required

Topic 17 closed the latency SLO catalog. Topic 18 closes operability gaps:

| Gap                          | Artifact                                             |
| ---------------------------- | ---------------------------------------------------- |
| HA claimed but `replicas: 1` | HPA/PDB + multi-replica critical paths               |
| Only GD03 executed           | STATUS + TEMPLATE for 01/02/04; postmortem from GD03 |
| Argo CD edge unmonitored     | `argocd-ui` uptime check                             |

Without this step, game day 02 is theater and Argo CD outages are invisible to synthetic probes.

## Prerequisites

- Prior guides: [12-boutique-deploy.md](12-boutique-deploy.md), [13-observability-slos.md](13-observability-slos.md), [14-pagerduty.md](14-pagerduty.md)
- Recommended: [17-latency-slos-dashboards.md](17-latency-slos-dashboards.md) (can run before or after this topic)
- Storefront + Argo CD HTTPS healthy
- Tools: `kubectl`, `argocd`, `gcloud`, `curl`, `helm` (optional)
- Access: cluster admin, Monitoring editor, PagerDuty for GD04
- Repo artifacts:
  - `gitops/apps/boutique/templates/hpa.yaml`, `pdb.yaml`, updated `values.yaml`
  - `observability/monitoring/uptime-checks/argocd-ui.yaml`
  - `scripts/create-argocd-uptime-check.sh`
  - `docs/sre/game-days/reports/{TEMPLATE,STATUS}.md`
  - `docs/sre/postmortems/2026-07-04-redis-cart-down.md`

## Commands

### 1. Sync Boutique HA defaults

Confirm chart renders HPA/PDB locally, then sync via Argo CD:

```bash
cd gitops/apps/boutique
helm template boutique . -f values.yaml -f values-images.yaml | rg -n "kind: (HorizontalPodAutoscaler|PodDisruptionBudget)"

argocd app sync boutique --prune
# or refresh + sync from UI (manual sync — ADR 003)

kubectl get hpa,pdb,deploy -n boutique
kubectl get deploy -n boutique -o custom-columns=NAME:.metadata.name,READY:.status.readyReplicas,DESIRED:.spec.replicas
```

**Expect:** `frontend` and `checkoutservice` HPA (min 2); PDBs on frontend, checkout, cart, redis-cart; `cartservice` Ready 2; `redis-cart` Ready **1** (single-instance Redis — do not scale to 2).

### 2. Create Argo CD uptime check

```bash
./scripts/create-argocd-uptime-check.sh
```

Then add an **OR** condition on alert policy `uptime-check-failed` for the new `argocd-ui` check ID (Console → Monitoring → Alerting), matching storefront thresholds (see [uptime-check-failed.yaml](../../observability/monitoring/alert-policies/uptime-check-failed.yaml)).

```bash
./scripts/attach-pagerduty-channel.sh   # if channel not already on the policy
make runbook-lint
```

### 3. Validate edges

```bash
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art/healthz
gcloud monitoring uptime list-configs --project=boutique-gke \
  --format='table(displayName,httpCheck.path,period)'
```

### 4. Game-day cadence (execute when scheduled)

| Order | Scenario                | Guide                                                                   | Notes                                                                                |
| ----- | ----------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| 1     | Alert routing           | [04-alert-routing.md](../sre/game-days/04-alert-routing.md)             | Proves PD before chaotic injects                                                     |
| 2     | Bad deploy rollback     | [01-bad-deploy-rollback.md](../sre/game-days/01-bad-deploy-rollback.md) |                                                                                      |
| 3     | Zone / pod failure      | [02-zone-pod-failure.md](../sre/game-days/02-zone-pod-failure.md)       | Needs step 1 HA sync first                                                           |
| 4     | Redis re-run (optional) | [03-redis-cart-down.md](../sre/game-days/03-redis-cart-down.md)         | Close PD/BA gaps from [postmortem](../sre/postmortems/2026-07-04-redis-cart-down.md) |

After each run:

```bash
# 1. Copy docs/sre/game-days/reports/TEMPLATE.md → YYYY-MM-DD-<slug>.md
# 2. Update docs/sre/game-days/reports/STATUS.md
# 3. Update docs/sre/game-days/reports/README.md
# 4. Postmortem if restore surprises (see TEMPLATE in postmortems/)
```

Status matrix: [STATUS.md](../sre/game-days/reports/STATUS.md)

### 5. Smoke HA + uptime (quick)

```bash
kubectl get hpa -n boutique
kubectl get pdb -n boutique
curl -I https://argocd.boutique.biroltilki.art/healthz
```

## Expected output

- HPA objects for `frontend` and `checkoutservice`
- PDB objects for frontend, checkoutservice, cartservice, redis-cart
- Uptime configs include `boutique-storefront` and `argocd-ui`
- `uptime-check-failed` documents both targets; runbook covers both branches
- GD 01/02/04 marked **Executed** in STATUS only after dated reports exist (do not fabricate)

## Validation

**Repo (always):**

```bash
make runbook-lint
helm template boutique gitops/apps/boutique -f gitops/apps/boutique/values.yaml -f gitops/apps/boutique/values-images.yaml >/dev/null
test -f docs/sre/postmortems/2026-07-04-redis-cart-down.md
test -f docs/sre/game-days/reports/STATUS.md
```

**Live (after apply):**

```bash
kubectl get hpa,pdb -n boutique
gcloud monitoring uptime list-configs --project=boutique-gke
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art/healthz
```

## Common problems

| Symptom                             | Cause                                | Fix                                             |
| ----------------------------------- | ------------------------------------ | ----------------------------------------------- |
| HPA missing after sync              | Chart not synced / wrong Application | `argocd app get boutique`; sync boutique chart  |
| Frontend stuck at 1 replica         | HPA metrics unavailable              | Metrics server / resource requests present      |
| Redis scaled to 2                   | Misread HA table                     | Keep `replicas: 1` — split cart state otherwise |
| Argo uptime 401/403                 | Armor / auth on `/healthz`           | Allow health path or probe CIDRs (topic 15)     |
| GD02 meaningless                    | Still single-replica frontend        | Complete step 1 before inject                   |
| STATUS says Executed without report | Process drift                        | Require dated file under `reports/`             |

## Recovery

- Roll back Boutique HA: revert GitOps PR → Argo sync
- Delete bad uptime check in Console; re-run `create-argocd-uptime-check.sh`
- Abort game day: restore from scenario guide; update STATUS as Partial if incomplete

## Best practices

- Run GD04 before chaotic injects so paging is proven
- Keep STATUS.md honest — Deferred until a report exists
- Re-read GD03 postmortem before re-running Redis (BA + signing)
- Prefer GitOps scale over `kubectl scale` for lasting HA changes

## Security notes

- Game-day inject scripts require `CONFIRM=yes`
- Temporary BA DRYRUN is break-glass only — re-enforce in the same exercise ([postmortem](../sre/postmortems/2026-07-04-redis-cart-down.md))
- Uptime probes must not require secrets in check config
- No production data destruction in Redis inject (scale only)

## Next step

| Step                                     | Guide                                                                  |
| ---------------------------------------- | ---------------------------------------------------------------------- |
| Topic 19 (monitoring + backup Terraform) | [19-monitoring-backup-terraform.md](19-monitoring-backup-terraform.md) |
| Smoke re-check                           | [16-smoke-validation.md](16-smoke-validation.md)                       |
| On-call                                  | [oncall/README.md](../sre/oncall/README.md)                            |
| Teardown                                 | [teardown.md](../teardown.md)                                          |
| SRE practices (topic 20)                 | [20-sre-practices-capacity-toil.md](20-sre-practices-capacity-toil.md) |
