# Observability + SLOs

## Goal

Deploy the observability stack (OpenTelemetry Collector, Grafana, Managed Prometheus integration), define Cloud Monitoring **SLOs** for browse (**99.9%** availability) and checkout (**99.95%** availability), and configure multi-window **burn-rate alert policies** with runbook URLs. When complete, on-call can see SLI data, triage in Grafana, and receive burn alerts that link to `docs/sre/runbooks/`.

## Why this step is required

Running workloads without observability is operating blind. SRE practice requires measurable SLIs, error budgets, and alerting before declaring production readiness. This topic wires:

- **Traces** (OTel → Cloud Trace) for checkout latency debugging
- **Metrics** (OTel → Managed Prometheus) for golden signals and SLO queries
- **Dashboards** (Grafana) for on-call triage
- **SLOs** (Cloud Monitoring) aligned with [SLO catalog](../sre/slos/catalog.md)
- **Burn alerts** routed to PagerDuty (notification channel added in topic 14)

Without SLOs and burn alerts, incidents are discovered by users before the team — unacceptable for this reference architecture.

## Prerequisites

- Prior guide: [12-boutique-deploy.md](12-boutique-deploy.md)
- Boutique serving traffic at https://boutique.biroltilki.art
- APIs enabled: `monitoring.googleapis.com`, `cloudtrace.googleapis.com`
- Tools: `kubectl`, `argocd`, `gcloud`, `curl`
- Access: `roles/monitoring.admin` (or Editor) on `boutique-gke`
- Argo CD `observability` Application defined in `gitops/apps/argocd-apps/observability-application.yaml`
- OTel collector manifests live under `observability/otel/collector/` (synced via Kustomize root `observability/`)

## Commands

### 1. OTel Collector service account (if not in Terraform)

Verify manifests under `observability/otel/collector/` (`config.yaml`, `deployment.yaml`, `service.yaml`). Create the GCP service account if it does not exist:

```bash
export PROJECT_ID=boutique-gke
export GSA_EMAIL="otel-collector@${PROJECT_ID}.iam.gserviceaccount.com"

gcloud iam service-accounts create otel-collector \
  --project="${PROJECT_ID}" \
  --display-name="OpenTelemetry Collector"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${GSA_EMAIL}" \
  --role="roles/cloudtrace.agent"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${GSA_EMAIL}" \
  --role="roles/monitoring.metricWriter"

gcloud iam service-accounts add-iam-policy-binding "${GSA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[observability/otel-collector]"
```

Platform images (OTel, Grafana) are mirrored to Artifact Registry via [`.github/workflows/mirror-platform-images.yml`](../../.github/workflows/mirror-platform-images.yml). Run that workflow before first deploy if digests are not yet in AR.

### 2. Sync observability via Argo CD

```bash
argocd app sync observability --prune
argocd app wait observability --health --timeout 600
```

Fallback (bootstrap only — applies full Kustomize bundle including namespace tier label):

```bash
kubectl kustomize observability/ | kubectl apply -f -
```

Do **not** use `kubectl create namespace observability` alone — Kyverno requires `network-policy.biroltilki.art/tier: platform` on the namespace (set by Argo CD `managedNamespaceMetadata` or `observability/namespace.yaml`).

### 3. Wire Boutique tracing to the collector

Online Boutique v0.10.5 uses `ENABLE_TRACING`, `COLLECTOR_SERVICE_ADDR`, and `OTEL_SERVICE_NAME` (configured in `gitops/apps/boutique/values.yaml` under `global.tracing`). Sync the boutique app after observability is healthy:

```bash
argocd app sync boutique
argocd app wait boutique --health --timeout 300
kubectl -n boutique logs deploy/checkoutservice --tail=5 | grep -i tracing
# Expect: "Tracing enabled."
```

Collector endpoint: `otel-collector.observability.svc:4317` (NetworkPolicy `boutique-allow` permits OTLP egress).

### 4. Configure Grafana

Grafana deploys as part of `observability/` ([`observability/grafana/`](../../observability/grafana/)). Datasource provisioning in `observability/grafana/datasources.yaml` — **Google Managed Prometheus** and **Cloud Monitoring** (trace triage uses Cloud Console → Trace).

**Before first sync:** complete Grafana GCP SA + admin secret per [`observability/grafana/README.md`](../../observability/grafana/README.md) (GSM secret `grafana-admin` → ESO `ExternalSecret`; Kyverno blocks plain `kubectl create secret`).

```bash
kubectl -n observability get pods -l app.kubernetes.io/name=grafana
kubectl -n observability get externalsecret grafana-admin
kubectl -n observability port-forward svc/grafana 3000:80
# Open http://localhost:3000 — credentials from GSM via ESO (not in Git)
```

### 5. Create Cloud Monitoring SLOs (Console)

Navigate: **GCP Console → Monitoring → Services → Create SLO**

#### Browse availability — 99.9%

| Field    | Value                                                                                                                |
| -------- | -------------------------------------------------------------------------------------------------------------------- |
| Service  | `boutique-frontend` (custom Monitoring service)                                                                      |
| SLI type | Availability — good requests / total requests                                                                        |
| Filter   | HTTPS LB `url_map_name` for boutique frontend ingress (see `observability/monitoring/slos/browse-availability.yaml`) |
| Goal     | **99.9%** over rolling **30 days**                                                                                   |
| Name     | `browse-availability`                                                                                                |

#### Checkout availability — 99.95%

| Field    | Value                                                                                                          |
| -------- | -------------------------------------------------------------------------------------------------------------- |
| Service  | `boutique-checkout`                                                                                            |
| SLI type | Availability — log-based good / total ratio                                                                    |
| Metric   | `boutique/checkout_success` / `boutique/checkout_attempts` (see `observability/monitoring/log-based-metrics/`) |
| Goal     | **99.95%** over rolling **30 days**                                                                            |
| Name     | `checkout-availability`                                                                                        |

Reference definitions: `observability/monitoring/slos/` and [catalog.md](../sre/slos/catalog.md).

Verify SLOs in Console (**Monitoring → Services → SLOs**) or:

```bash
gcloud monitoring services list --project=boutique-gke
# Then open each service in Console to confirm browse-availability and checkout-availability SLOs
```

> **Note:** Stable `gcloud` has no `monitoring slos list` subcommand. Use Console or the Monitoring REST API.

### 6. Create burn-rate alert policies

Navigate: **GCP Console → Monitoring → Alerting → Create policy**, or run:

```bash
./scripts/create-burn-rate-policies.sh
```

For each SLO, add **SLO burn rate** conditions per [burn-rate-alerting.md](../sre/slos/burn-rate-alerting.md):

| Window | Burn multiplier | Response |
| ------ | --------------- | -------- |
| 1 h    | 14.4×           | Page     |
| 6 h    | 6×              | Page     |
| 1 d    | 3×              | Ticket   |
| 3 d    | 1×              | Ticket   |

> **API limit:** Cloud Monitoring supports max **24 h** lookback for burn-rate conditions. Use **24 h / 1×** as the slow-burn ticket window instead of 3 d (see `scripts/create-burn-rate-policies.sh`).

**Browse availability burn** policy (`browse-availability-burn`):

- Condition: SLO burn rate on `browse-availability`
- Notification channel: add in topic 14 (PagerDuty)
- Documentation runbook URL:
  `https://github.com/btilki/boutique-gke-sre/blob/main/docs/sre/runbooks/browse-availability-burn.md`

**Checkout availability burn** policy (`checkout-availability-burn`):

- Condition: SLO burn rate on `checkout-availability`
- Runbook URL: `.../docs/sre/runbooks/checkout-availability-burn.md`

Reference YAML: `observability/monitoring/alert-policies/`

### 7. Create uptime check (external probe)

Navigate: **Monitoring → Uptime checks → Create**, or run:

```bash
./scripts/create-uptime-check.sh
```

| Field    | Value                     |
| -------- | ------------------------- |
| Protocol | HTTPS                     |
| Host     | `boutique.biroltilki.art` |
| Path     | `/`                       |
| Period   | 1 min                     |
| Regions  | 3+                        |

Alert policy: `uptime-check-failed` → runbook `docs/sre/runbooks/uptime-check-failed.md`

## Expected output

- `kubectl -n observability get pods` — `otel-collector` and `grafana` Running
- `kubectl -n boutique logs deploy/frontend` — `Tracing enabled.`
- Traces visible in **Cloud Console → Trace** after generating storefront traffic
- Metrics visible in **Monitoring → Metrics explorer** (OTel / LB metrics)
- Browse and checkout SLOs visible under **Monitoring → Services** in Console
- Alert policies listed under **Monitoring → Alerting** with burn-rate conditions
- Each alert policy documentation includes a runbook URL

Generate traffic for signal:

```bash
for i in $(seq 1 20); do curl -s -o /dev/null -w "%{http_code}\n" https://boutique.biroltilki.art; done
```

## Validation

```bash
# OTel collector healthy
kubectl -n observability get pods -l app.kubernetes.io/name=otel-collector
kubectl -n observability logs deploy/otel-collector --tail=20

# Boutique tracing wired
kubectl -n boutique logs deploy/frontend --tail=20 | grep -i "Tracing enabled"

# SLOs — verify in Console (Monitoring → Services → boutique-frontend / boutique-checkout)
gcloud monitoring services list --project=boutique-gke

# Storefront still healthy
dig +short boutique.biroltilki.art
curl -I https://boutique.biroltilki.art

# Trace pipeline — generate traffic, then Cloud Console → Trace → filter service: frontend
for i in $(seq 1 10); do curl -s -o /dev/null https://boutique.biroltilki.art; done

# Alert policies present
gcloud monitoring policies list --project=boutique-gke --format='table(displayName)' | grep -i burn

# Runbooks exist on disk
ls docs/sre/runbooks/browse-availability-burn.md \
   docs/sre/runbooks/checkout-availability-burn.md \
   docs/sre/runbooks/uptime-check-failed.md
```

**Pass criteria:** OTel and Grafana running; boutique pods log `Tracing enabled.`; traces in Cloud Trace; browse 99.9% and checkout 99.95% SLOs created; burn alert policies reference runbook URLs.

## Common problems

| Symptom                         | Cause                                    | Fix                                                                  |
| ------------------------------- | ---------------------------------------- | -------------------------------------------------------------------- |
| No traces in Cloud Trace        | WI not configured on collector SA        | Verify annotation and IAM roles on `otel-collector` SA               |
| Pod logs say `Tracing disabled` | Boutique not synced after tracing change | `argocd app sync boutique`                                           |
| gRPC timeouts in traces (~10s)  | Rollout in progress                      | Wait for rollout; re-test after all pods Ready                       |
| SLO shows "no data"             | Insufficient metric traffic              | Generate requests; verify LB/log-based metrics                       |
| Grafana login fails             | GSM secret or ESO not synced             | See `observability/grafana/README.md`; check `externalsecret` status |
| Grafana datasource error        | WI missing on Grafana SA                 | Check `datasources.yaml`; verify `monitoring.viewer` on Grafana GSA  |
| Burn alert never fires          | Threshold too high                       | Lower 1 h window multiplier for test                                 |
| High cardinality costs          | Per-pod labels on SLI                    | Aggregate at service level per catalog guidance                      |

## Recovery

- **Argo CD rollback:** `argocd app rollback observability` or `argocd app rollback boutique`
- **Disable noisy alert:** Mute policy in Console or set `enabled: false` via gcloud
- **OTel crash loop:** `kubectl -n observability logs deploy/otel-collector`; fix config.yaml syntax
- **Delete test SLO:** Console → SLO → Delete (avoid orphan alert policies)

## Best practices

- Define SLIs from the user journey (browse vs checkout), not only infrastructure metrics
- Every alert policy must link a runbook — see [runbooks/README.md](../sre/runbooks/README.md)
- Use multi-window burn rates to reduce false pages ([burn-rate-alerting.md](../sre/slos/burn-rate-alerting.md))
- Keep Grafana dashboards in `observability/grafana/dashboards/` under GitOps
- Review SLO compliance monthly; tune thresholds after the first month of data

## Security notes

- Grafana admin credentials live in **Secret Manager** (`grafana-admin`), synced via **ExternalSecret** — never in Git
- OTel collector SA has minimal roles: `cloudtrace.agent`, `monitoring.metricWriter`
- Avoid logging PII in access logs used for SLI metrics ([log-based-metrics README](../../observability/monitoring/log-based-metrics/README.md))
- Runbook URLs are public GitHub links — no secrets in alert documentation fields

## Next step

→ [PagerDuty integration](14-pagerduty.md)
