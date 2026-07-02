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
- **Scaffold gate:** OTel collector manifests in `observability/otel/collector/` are commented out until Phase 6 implementation; uncomment before Argo CD sync or `kubectl apply`
- Argo CD `observability` Application defined in `gitops/apps/argocd-apps/observability-application.yaml`

## Commands

### 1. Prepare OTel Collector manifests

Uncomment and tune manifests under `observability/otel/collector/`:

- `config.yaml` — OTLP receivers, `googlecloud` trace exporter, `googlemanagedprometheus` metrics exporter
- `deployment.yaml` — Deployment, ServiceAccount with Workload Identity annotation

Create the GCP service account for the collector (if not in Terraform):

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

### 2. Sync observability via Argo CD

```bash
argocd app sync observability --prune
argocd app wait observability --health --timeout 600
```

Or apply directly during bootstrap:

```bash
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f observability/otel/collector/
```

### 3. Configure Grafana

Grafana is deployed as part of `observability/` (see `observability/grafana/`). Datasource provisioning is in `observability/grafana/datasources.yaml` — Prometheus/Managed Prometheus, Cloud Monitoring, Cloud Trace.

```bash
kubectl -n observability get pods -l app.kubernetes.io/name=grafana
kubectl -n observability port-forward svc/grafana 3000:80
# Open http://localhost:3000 (credentials from Kubernetes Secret / Helm values)
```

### 4. Create Cloud Monitoring SLOs (Console)

Navigate: **GCP Console → Monitoring → SLOs → Create SLO**

#### Browse availability — 99.9%

| Field    | Value                                                               |
| -------- | ------------------------------------------------------------------- |
| Service  | Online Boutique / HTTPS LB or custom service                        |
| SLI type | Availability — good requests / total requests                       |
| Filter   | Request host = `boutique.biroltilki.art` (or frontend metric label) |
| Goal     | **99.9%** over rolling **30 days**                                  |
| Name     | `browse-availability`                                               |

#### Checkout availability — 99.95%

| Field    | Value                                                                                                 |
| -------- | ----------------------------------------------------------------------------------------------------- |
| SLI type | Availability — successful checkouts / attempts                                                        |
| Metric   | Custom or log-based metric from `checkoutservice` (see `observability/monitoring/log-based-metrics/`) |
| Goal     | **99.95%** over rolling **30 days**                                                                   |
| Name     | `checkout-availability`                                                                               |

Reference definitions: `observability/monitoring/slos/` and [catalog.md](../sre/slos/catalog.md).

List SLOs via CLI:

```bash
gcloud monitoring slos list --project=boutique-gke
```

### 5. Create burn-rate alert policies

Navigate: **GCP Console → Monitoring → Alerting → Create policy**

For each SLO, add **SLO burn rate** conditions per [burn-rate-alerting.md](../sre/slos/burn-rate-alerting.md):

| Window | Burn multiplier | Response |
| ------ | --------------- | -------- |
| 1 h    | 14.4×           | Page     |
| 6 h    | 6×              | Page     |
| 1 d    | 3×              | Ticket   |
| 3 d    | 1×              | Ticket   |

**Browse availability burn** policy:

- Condition: SLO burn rate on `browse-availability`
- Notification channel: add in topic 14 (PagerDuty)
- Documentation / user label `runbook_url`:
  `https://github.com/biroltilki/boutique-gke-sre/blob/main/docs/sre/runbooks/browse-availability-burn.md`

**Checkout latency burn** policy:

- Condition: SLO burn rate on checkout latency SLO
- Runbook URL: `.../docs/sre/runbooks/checkout-latency-burn.md`

Planned policy manifests: `observability/monitoring/alert-policies/`

### 6. Create uptime check (external probe)

Navigate: **Monitoring → Uptime checks → Create**

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
- Traces visible in **Cloud Console → Trace** after generating storefront traffic
- Metrics visible in **Monitoring → Metrics explorer** (OTel / LB metrics)
- `gcloud monitoring slos list` shows browse and checkout SLOs
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

# SLOs exist
gcloud monitoring slos list --project=boutique-gke

# Storefront still healthy
dig +short boutique.biroltilki.art
curl -I https://boutique.biroltilki.art

# Alert policies present (names may vary)
gcloud alpha monitoring policies list --project=boutique-gke --format='table(displayName)' | grep -i burn

# Runbooks exist on disk
ls docs/sre/runbooks/browse-availability-burn.md \
   docs/sre/runbooks/checkout-latency-burn.md \
   docs/sre/runbooks/uptime-check-failed.md
```

**Pass criteria:** OTel and Grafana running; browse 99.9% and checkout 99.95% SLOs created; burn alert policies reference runbook URLs.

## Common problems

| Symptom                  | Cause                             | Fix                                              |
| ------------------------ | --------------------------------- | ------------------------------------------------ |
| No traces in Cloud Trace | WI not configured on collector SA | Verify annotation and IAM roles                  |
| SLO shows "no data"      | Insufficient metric traffic       | Generate requests; verify LB/OTel metrics        |
| Grafana datasource error | MP not linked or WI missing       | Check `datasources.yaml`; verify GMP permissions |
| Burn alert never fires   | Threshold too high                | Lower 1 h window multiplier for test             |
| High cardinality costs   | Per-pod labels on SLI             | Aggregate at service level per catalog guidance  |

## Recovery

- **Argo CD rollback:** `argocd app rollback observability`
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

- Grafana admin credentials are Kubernetes Secrets — not in Git
- OTel collector SA has minimal roles: `cloudtrace.agent`, `monitoring.metricWriter`
- Avoid logging PII in access logs used for SLI metrics
- Runbook URLs are public GitHub links — no secrets in alert documentation fields

## Next step

→ [PagerDuty integration](14-pagerduty.md)
