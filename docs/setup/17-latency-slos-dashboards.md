# Latency SLOs + Grafana dashboards

## Goal

On a rebuilt cluster (after topics 12–14), apply **browse** and **checkout latency SLOs**, create matching **multi-window burn-rate alerts**, confirm Grafana **golden signals** and **SLO overview** dashboards, and attach PagerDuty. When complete, the SLO catalog latency targets are operable — not documentation-only.

**Repo status:** All reference files already exist. This guide is the **future apply** path after infrastructure is rebuilt. Do not require a live cluster to keep the repo complete.

## Why this step is required

Topic 13 delivered availability SLOs only. The catalog and architecture require:

| Journey  | Latency target                       |
| -------- | ------------------------------------ |
| Browse   | p95 &lt; 500ms (goal 0.95 ≤ 500ms)   |
| Checkout | p95 &lt; 1000ms (goal 0.95 ≤ 1000ms) |

Without latency SLOs and burn alerts, slow degradation pages users before PagerDuty. Grafana dashboards give on-call a triage surface alongside Cloud Monitoring.

## Prerequisites

- Prior guides: [13-observability-slos.md](13-observability-slos.md), [14-pagerduty.md](14-pagerduty.md)
- Boutique serving `boutique.biroltilki.art` with HTTPS LB metrics
- Custom services `boutique-frontend` and `boutique-checkout` already exist (topic 13)
- Tools: `gcloud`, `kubectl`, `argocd`, `curl`, `python3`
- Access: `roles/monitoring.admin` (or Editor), cluster access for Grafana sync
- Repo artifacts present:
  - `observability/monitoring/slos/browse-latency.yaml`
  - `observability/monitoring/slos/checkout-latency.yaml`
  - `observability/monitoring/log-based-metrics/checkout-latency.yaml`
  - `observability/monitoring/alert-policies/*-latency-burn.yaml`
  - `scripts/create-latency-burn-rate-policies.sh`
  - `observability/grafana/dashboards/*.json`

## Commands

Export project context:

```bash
export PROJECT_ID=boutique-gke
export PROJECT_NUMBER="$(gcloud projects describe "${PROJECT_ID}" --format='value(projectNumber)')"
export TOKEN="$(gcloud auth print-access-token)"
```

### 1. Resolve frontend url_map (browse latency)

Browse latency uses the same HTTPS LB url_map as browse availability. After rebuild, replace the placeholder in `browse-latency.yaml` if needed:

```bash
gcloud compute url-maps list --global --project="${PROJECT_ID}" \
  --format="table(name)"
```

Use the Boutique frontend url_map name in the `distributionFilter` (same as `browse-availability.yaml`).

### 2. Create checkout latency log-based metric

Navigate: **GCP Console → Logging → Log-based metrics → Create metric**

| Field           | Value                                                                  |
| --------------- | ---------------------------------------------------------------------- |
| Name            | `boutique/checkout_latency`                                            |
| Type            | Distribution                                                           |
| Units           | `ms`                                                                   |
| Filter          | See `observability/monitoring/log-based-metrics/checkout-latency.yaml` |
| Field extractor | Numeric latency field if present (e.g. `jsonPayload.latency_ms`)       |

**Fallback:** If PlaceOrder logs lack a duration field, document Trace/OTel histogram as the temporary SLI in the team notes and keep the YAML as the preferred path once instrumentation exists. Do not invent an LB-only checkout latency SLI.

Reference: [log-based-metrics/checkout-latency.yaml](../../observability/monitoring/log-based-metrics/checkout-latency.yaml)

### 3. Create browse-latency SLO

Navigate: **Monitoring → Services → boutique-frontend → Create SLO**, or POST via Monitoring API using fields from:

[observability/monitoring/slos/browse-latency.yaml](../../observability/monitoring/slos/browse-latency.yaml)

| Field             | Value                                                |
| ----------------- | ---------------------------------------------------- |
| Display name / ID | `browse-latency`                                     |
| Goal              | `0.95` (95% of requests ≤ 500ms)                     |
| Rolling period    | 30 days                                              |
| SLI               | Request-based distribution cut, max 500 ms           |
| Metric            | `loadbalancing.googleapis.com/https/total_latencies` |

Verify:

```bash
curl -s -H "Authorization: Bearer ${TOKEN}" \
  "https://monitoring.googleapis.com/v3/projects/${PROJECT_ID}/services/boutique-frontend/serviceLevelObjectives/browse-latency" \
  | python3 -c "import sys,json; s=json.load(sys.stdin); print(s['displayName'], s['goal'])"
```

Expected: `browse-latency 0.95`

### 4. Create checkout-latency SLO

Same pattern for `boutique-checkout` using:

[observability/monitoring/slos/checkout-latency.yaml](../../observability/monitoring/slos/checkout-latency.yaml)

| Field             | Value                                                                                   |
| ----------------- | --------------------------------------------------------------------------------------- |
| Display name / ID | `checkout-latency`                                                                      |
| Goal              | `0.95` (95% of checkouts ≤ 1000ms)                                                      |
| SLI               | Distribution cut max 1000 ms on `logging.googleapis.com/user/boutique/checkout_latency` |

```bash
curl -s -H "Authorization: Bearer ${TOKEN}" \
  "https://monitoring.googleapis.com/v3/projects/${PROJECT_ID}/services/boutique-checkout/serviceLevelObjectives/checkout-latency" \
  | python3 -c "import sys,json; s=json.load(sys.stdin); print(s['displayName'], s['goal'])"
```

Expected: `checkout-latency 0.95`

### 5. Create latency burn-rate alert policies

```bash
./scripts/create-latency-burn-rate-policies.sh
```

Creates `browse-latency-burn` and `checkout-latency-burn` with the same multi-window thresholds as availability (1h/14.4×, 6h/6×, 24h/3×, 24h/1×). Runbook URLs come from `observability/monitoring/runbooks.yaml`.

### 6. Attach PagerDuty notification channel

If channel already exists from topic 14:

```bash
./scripts/attach-pagerduty-channel.sh
```

Confirm both new policies list `pagerduty-boutique-production` (or your channel display name).

### 7. Sync Grafana dashboards

Dashboards are provisioned via ConfigMaps in `observability/grafana/` . Sync the observability Application:

```bash
argocd app sync observability --prune
# or: kubectl -n argocd annotate application observability \
#   argocd.argoproj.io/refresh=hard --overwrite

kubectl -n observability get configmap | grep grafana-dashboard
kubectl -n observability rollout status deploy/grafana
```

**Manual import fallback:** Grafana → Dashboards → Import → upload:

- `observability/grafana/dashboards/boutique-golden-signals.json`
- `observability/grafana/dashboards/slo-overview.json`

Folder: **Boutique SRE**. Datasource UIDs: `gmp`, `gcm` ([datasources.yaml](../../observability/grafana/datasources.yaml)).

### 8. Lint runbook linkage

```bash
make runbook-lint
```

## Expected output

- Four latency/availability SLOs under `boutique-frontend` and `boutique-checkout`
- Alert policies `browse-latency-burn` and `checkout-latency-burn` enabled with runbook URLs
- Grafana shows **Boutique — Golden Signals** and **Boutique — SLO Overview**
- `make runbook-lint` reports all links valid (7 PagerDuty policies)

Generate latency signal:

```bash
for i in $(seq 1 30); do
  curl -s -o /dev/null -w "%{time_total}\n" https://boutique.biroltilki.art
done
# Exercise checkout in the UI or via app API if available
```

## Validation

```bash
# Repo (always)
make runbook-lint
python3 -c "import json,pathlib; [json.load(open(p)) for p in pathlib.Path('observability/grafana/dashboards').glob('*.json')]; print('dashboards ok')"

# Live (after apply)
curl -s -H "Authorization: Bearer ${TOKEN}" \
  "https://monitoring.googleapis.com/v3/projects/${PROJECT_ID}/services/boutique-frontend/serviceLevelObjectives" \
  | python3 -c "import sys,json; print([s['displayName'] for s in json.load(sys.stdin).get('serviceLevelObjectives',[])])"

curl -I https://boutique.biroltilki.art
```

Expected live list includes `browse-availability`, `browse-latency` (and checkout pair on the checkout service).

Optional alert drill: [test-alerts.md](../sre/oncall/test-alerts.md) for a latency policy (or game day 04).

## Common problems

| Symptom                                    | Cause                                          | Fix                                                      |
| ------------------------------------------ | ---------------------------------------------- | -------------------------------------------------------- |
| Browse SLO no data                         | Wrong `url_map_name`                           | Update filter from `gcloud compute url-maps list`        |
| Checkout SLO empty                         | Distribution metric missing / no latency field | Fix log metric extractor or use Trace fallback           |
| `create-latency-burn-rate-policies.sh` 404 | SLO ID not created yet                         | Complete steps 3–4 first                                 |
| Policy already exists                      | Re-run after partial apply                     | Delete policy in Console, re-run script                  |
| Grafana dashboards missing                 | Observability not synced / old Deployment      | Sync Argo CD; confirm volume mounts in `deployment.yaml` |
| PromQL panels empty                        | GMP / kube-state-metrics not scraping          | Topic 13 observability; tune queries after rebuild       |

## Recovery

- Delete a bad SLO in **Monitoring → Services → SLO → Delete** (remove linked alert policies first)
- Re-create policies: delete in Console → `./scripts/create-latency-burn-rate-policies.sh`
- Grafana: `argocd app rollback observability` or re-import JSON from `dashboards/`
- Mute noisy latency pages temporarily in Alerting while tuning thresholds

## Best practices

- Treat Cloud Monitoring as source of truth for SLO burn; Grafana is triage UX
- Keep `url_map_name` and log filters in sync with availability artifacts
- After first week of latency data, review false pages and adjust only with catalog justification
- Prefer GitOps dashboard provisioning over one-off UI edits
- Link every new policy in `observability/monitoring/runbooks.yaml` before enabling pages

## Security notes

- Runbook URLs are public GitHub links — no secrets in alert documentation
- Log-based latency metrics must not promote `user_id` / email into labels ([log-based-metrics README](../../observability/monitoring/log-based-metrics/README.md))
- Grafana admin credentials remain in Secret Manager / ESO only
- Monitoring Admin is powerful — prefer least privilege for day-2 operators (`monitoring.editor` where enough)

## Next step

Latency SRE layer is complete for this rebuild. Continue with:

| Step                                         | Guide                                                                 |
| -------------------------------------------- | --------------------------------------------------------------------- |
| SRE operability (HA, Argo uptime, game days) | [18-sre-operability-game-days.md](18-sre-operability-game-days.md)    |
| Smoke re-check (include latency SLOs)        | [16-smoke-validation.md](16-smoke-validation.md)                      |
| Game day / alert routing                     | [game-days/04-alert-routing.md](../sre/game-days/04-alert-routing.md) |
| On-call                                      | [oncall/README.md](../sre/oncall/README.md)                           |
| Edge hardening (if not done)                 | [edge-hardening.md](../security/edge-hardening.md)                    |

Topic 19 (monitoring + backup Terraform): [19-monitoring-backup-terraform.md](19-monitoring-backup-terraform.md). Topic 20 tracked in [ROADMAP.md](../../ROADMAP.md).
