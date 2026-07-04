# Production operations runbook — boutique-gke-sre

Canonical day-2 operations guide for Online Boutique on the private GKE cluster in GCP project `boutique-gke`.

| Item           | Value                                                             |
| -------------- | ----------------------------------------------------------------- |
| **Storefront** | https://boutique.biroltilki.art                                   |
| **Argo CD**    | https://argocd.boutique.biroltilki.art                            |
| **Cluster**    | `boutique-gke` (`europe-west1`)                                   |
| **GitOps**     | Manual Argo CD sync ([ADR-003](../adr/003-manual-argocd-sync.md)) |
| **On-call**    | [docs/sre/oncall/README.md](../sre/oncall/README.md)              |

**Related docs:** [architecture/overview.md](../architecture/overview.md) · [rollback.md](rollback.md) · [teardown.md](../teardown.md) · [sre/runbooks/](../sre/runbooks/)

---

## Overview

### Purpose

Provide a single reference for platform engineers and on-call responders to operate, recover, and maintain the production SRE reference environment. This runbook covers routine operations (deploy, scale, rotate) and incident response (rollback, DR, postmortems).

### Commands

```bash
# Baseline context — run at shift start
export PROJECT_ID=boutique-gke
export REGION=europe-west1
export CLUSTER_NAME=boutique-gke

gcloud config set project "${PROJECT_ID}"
gcloud container clusters get-credentials "${CLUSTER_NAME}" \
  --region="${REGION}" --project="${PROJECT_ID}"

kubectl cluster-info
argocd app list 2>/dev/null || kubectl -n argocd get applications
```

### Validation

```bash
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
kubectl get nodes
```

### Expected outcome

- Both URLs return `HTTP/2 200` or `302` with valid TLS
- All nodes `Ready`
- Argo CD Applications show `Healthy` / `Synced` (or `OutOfSync` awaiting manual sync)

### Recovery steps

If baseline validation fails, open the matching section below (Health Checks → Troubleshooting → Common incidents) before making changes.

### Best practices

- Treat Git as source of truth; avoid ad-hoc `kubectl edit` without a follow-up PR
- Manual Argo CD sync only — never enable auto-sync on production Applications
- Link every production change to a PR and, when applicable, a runbook or postmortem
- Review error budget before risky deploys ([error-budget-policy.md](../sre/error-budget-policy.md))

---

## Deployment

### Purpose

Promote a new application revision from Git to the cluster via the documented CI → digest PR → manual Argo CD sync pipeline. Ensures signed, scanned, digest-pinned images pass Kyverno and Binary Authorization.

### Commands

```bash
# 1. Trigger image build (when upstream version changes)
# GitHub → Actions → build-scan-sign → Run workflow
#   upstream_version: v0.10.5
#   redis_tag: 7.2-alpine

# 2. After green CI, review and merge digest PR (updates values-images.yaml)
grep '@sha256:' gitops/apps/boutique/values-images.yaml

# 3. Review Argo CD diff before sync
argocd app diff boutique
# Or UI: https://argocd.boutique.biroltilki.art → boutique → Diff

# 4. Manual sync (CLI or UI)
argocd app sync boutique --prune
# UI: Sync → Synchronize

# 5. Watch rollout
kubectl rollout status deployment/frontend -n boutique --timeout=300s
kubectl get pods -n boutique
```

**Terraform / platform changes** follow a separate path:

```bash
cd terraform/environments/boutique
terraform plan -out=tfplan
# Review plan; apply after PR merge
terraform apply tfplan
```

### Validation

```bash
# Digest pins only (no :latest)
kubectl get deploy -n boutique -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.template.spec.containers[0].image}{"\n"}{end}' \
  | grep -v '@sha256:' && echo "FAIL: mutable tag found" || echo "OK: digest-only"

# Storefront smoke
curl -sS -o /dev/null -w "%{http_code}\n" https://boutique.biroltilki.art

# Argo CD health
kubectl -n argocd get application boutique -o jsonpath='{.status.health.status}{" "}{.status.sync.status}{"\n"}'
```

### Expected outcome

- All Boutique deployments use `@sha256:` image references
- Pods reach `Running` / `Ready`
- Argo CD Application: `Healthy` + `Synced`
- Storefront returns HTTP 200
- No Kyverno admission denials in sync events

### Recovery steps

| Failure                     | Action                                                                                                                          |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Binary Authorization denial | Verify cosign signature on image in AR; see [08-artifact-registry-binary-auth.md](../setup/08-artifact-registry-binary-auth.md) |
| Kyverno denial              | Fix manifest in Git; re-sync — [kyverno-denials.md](../troubleshooting/kyverno-denials.md)                                      |
| Image pull error            | Confirm digest exists in `europe-west1-docker.pkg.dev/boutique-gke/boutique/`                                                   |
| Bad rollout                 | [Rollback](#rollback)                                                                                                           |

### Best practices

- Merge digest PRs only after CI green (Trivy, cosign, attest)
- Sync during low-traffic windows for checkout-path changes
- Check error budget remaining before deploy ([slos/catalog.md](../sre/slos/catalog.md))
- One Application sync at a time; verify before syncing dependent apps

**Further reading:** [12-boutique-deploy.md](../setup/12-boutique-deploy.md) · [ADR-003](../adr/003-manual-argocd-sync.md)

---

## Rollback

### Purpose

Restore the last known-good state after a faulty deploy, config change, or Terraform apply. Git revert is the preferred rollback mechanism.

### Commands

**GitOps rollback (preferred):**

```bash
# Identify last good commit
git log --oneline -10 -- gitops/apps/boutique/values-images.yaml

# Revert bad merge on main (via PR or locally)
git revert <bad-commit-sha>
git push origin main

# Manual Argo CD sync
argocd app sync boutique --prune

# Verify
kubectl get pods -n boutique
curl -I https://boutique.biroltilki.art
```

**Argo CD history rollback (emergency only):**

```bash
# List revisions
argocd app history boutique

# Roll back to revision N (temporary — still fix Git)
argocd app rollback boutique <revision-id>
```

**Terraform rollback:**

```bash
git revert <terraform-commit>
cd terraform/environments/boutique
terraform plan
terraform apply
```

### Validation

```bash
kubectl rollout status deployment/frontend -n boutique
curl -sS -o /dev/null -w "%{http_code}\n" https://boutique.biroltilki.art
# Exercise checkout path manually or via smoke script
```

### Expected outcome

- Error rate returns to baseline within one rollout cycle
- SLO burn stops within alert window
- Git `main` matches cluster desired state (no drift from Argo history rollback)

### Recovery steps

1. If Git revert is insufficient, scale problematic deployment to zero and restore previous digest in `values-images.yaml`
2. SEV2 if checkout unavailable > 15 min → [severity.md](../sre/incident-response/severity.md)
3. Open postmortem for SEV1–SEV2

### Best practices

- Always follow Argo history rollback with a Git revert PR
- Document rollback in PagerDuty incident timeline
- Run game day 01 quarterly to practice rollback muscle memory

**Further reading:** [rollback.md](rollback.md) · [bad-deploy-rollback.md](../sre/runbooks/bad-deploy-rollback.md)

---

## Scaling

### Purpose

Adjust capacity for traffic spikes, zone loss, or cost optimization using HPA (workload), Cluster Autoscaler (nodes), and Terraform node pool settings.

### Commands

**Check current capacity:**

```bash
kubectl get hpa -n boutique
kubectl top nodes
kubectl top pods -n boutique
kubectl get pods -n boutique -o wide
```

**Tune HPA (via Helm values PR):**

```bash
# Edit gitops/apps/boutique/values.yaml — hpa min/max replicas
# Merge PR → manual Argo CD sync
argocd app sync boutique
```

**Scale a single deployment (temporary — prefer Git):**

```bash
kubectl scale deployment/frontend -n boutique --replicas=3
```

**Node pool scaling (Terraform):**

```bash
# Edit terraform/environments/boutique/terraform.tfvars or node pool module inputs
cd terraform/environments/boutique
terraform plan -target=module.gke
terraform apply
```

**Cluster Autoscaler status:**

```bash
kubectl -n kube-system logs -l app=cluster-autoscaler --tail=50
```

### Validation

```bash
kubectl get hpa -n boutique
kubectl get nodes
# Under load: pending pods should trigger node scale-up within ~2–5 min
```

### Expected outcome

- HPA maintains target CPU/utilization within min/max bounds
- No pods stuck `Pending` due to insufficient cluster capacity
- PDBs respected during scale-down (`kubectl get pdb -n boutique`)

### Recovery steps

| Symptom         | Action                                                         |
| --------------- | -------------------------------------------------------------- |
| Pods Pending    | Check node pool max; increase via Terraform or reduce requests |
| HPA not scaling | Verify metrics-server / custom metrics adapter                 |
| Zone imbalance  | Cordon/drain affected zone nodes; verify regional spread       |

### Best practices

- Prefer HPA over manual replica counts
- Set realistic requests/limits (Kyverno-enforced) so scheduling is predictable
- Test scale behavior in game day 02 (pod/zone failure)
- Do not scale below PDB `minAvailable` during incidents

**Further reading:** [architecture/overview.md §11](../architecture/overview.md#11-scalability)

---

## Disaster Recovery

### Purpose

Recover from catastrophic loss (cluster deletion, region impairment, corrupt state) using documented RPO/RTO targets and rebuild procedures.

### Commands

**Assess scope:**

```bash
gcloud container clusters describe boutique-gke \
  --region=europe-west1 --project=boutique-gke 2>&1

gsutil ls gs://boutique-gke-terraform-state/  # confirm state bucket exists
```

**Cluster rebuild (high level):**

```bash
# 1. Restore/re-apply infrastructure
cd terraform/environments/boutique
terraform init
terraform plan
terraform apply

# 2. Bootstrap Argo CD
# Follow docs/setup/09-argocd-bootstrap.md

# 3. Sync platform then apps
argocd app sync policies
argocd app sync boutique

# 4. Validate edge
dig +short boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
```

### Validation

```bash
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
kubectl get pods -A | grep -v Running | grep -v Completed
```

### Expected outcome

| Asset                    | RPO  | RTO     |
| ------------------------ | ---- | ------- |
| Git state                | 0    | minutes |
| Terraform state (GCS)    | 0    | hours   |
| Secrets (Secret Manager) | 0    | minutes |
| Redis (cart)             | < 1h | < 30m   |
| Full cluster             | N/A  | hours   |

### Recovery steps

1. Declare SEV1 if storefront is down
2. Confirm GCS Terraform state and GitHub repo are intact
3. Execute [cluster-rebuild.md](../sre/runbooks/cluster-rebuild.md)
4. Restore Redis if cart data required — [redis-restore.md](../sre/runbooks/redis-restore.md)
5. Run full smoke checklist — [16-smoke-validation.md](../setup/16-smoke-validation.md)

### Best practices

- Quarterly DR drill: rebuild from Terraform + Git only (non-prod window)
- Version Terraform state bucket; never delete without backup
- Keep bootstrap docs current with actual cluster names and hostnames
- Document DR decisions in postmortem after any real event

**Further reading:** [cluster-rebuild.md](../sre/runbooks/cluster-rebuild.md) · [architecture/overview.md §12](../architecture/overview.md#12-disaster-recovery)

---

## Backup

### Purpose

Protect persistent state (primarily Redis/cart data) and enable validated restore drills per Phase 8 requirements.

### Commands

**GKE Backup (when module applied):**

```bash
# List backup plans
gcloud beta container backup-restores backup-plans list \
  --location=europe-west1 --project=boutique-gke

# List recent backups
gcloud beta container backup-restores backups list \
  --location=europe-west1 \
  --backup-plan=boutique-daily \
  --project=boutique-gke

# On-demand backup (if supported by plan)
gcloud beta container backup-restores backups create on-demand-$(date +%Y%m%d) \
  --location=europe-west1 \
  --backup-plan=boutique-daily \
  --project=boutique-gke
```

**Pre-teardown backup check:**

```bash
./scripts/teardown/pre-destroy-checklist.sh
```

**Verify Redis PVC exists:**

```bash
kubectl get pvc -n boutique
kubectl get statefulset -n boutique | grep redis
```

### Validation

```bash
# Confirm backup completed in last 24h (adjust for your retention)
gcloud beta container backup-restores backups list \
  --location=europe-west1 \
  --backup-plan=boutique-daily \
  --project=boutique-gke \
  --format="table(name,state,createTime)" \
  --sort-by=~createTime \
  --limit=5
```

### Expected outcome

- Daily backup plan covers `boutique` namespace (including Redis PVC)
- Latest backup state: `SUCCEEDED`
- Retention matches policy (default: 7 days per backup module scaffold)

### Recovery steps

If backups are missing or failing:

1. Check GKE Backup API enabled: `gcloud services list --enabled | grep gkebackup`
2. Verify backup plan IAM and Workload Identity bindings
3. Review Cloud Logging for `gkebackup.googleapis.com` errors
4. Escalate SEV3 until RPO window is at risk

### Best practices

- Quarterly restore drill to non-production namespace or isolated cluster
- Include backup verification in on-call handoff after infrastructure changes
- Document backup scope in Terraform (`terraform/modules/backup/`)

**Further reading:** [terraform/modules/backup/README.md](../../terraform/modules/backup/README.md) · [teardown.md](../teardown.md)

---

## Restore

### Purpose

Restore application data or cluster resources from backup after data loss, corruption, or DR event.

### Commands

**Redis/cart restore (high level):**

```bash
# 1. Scale down writers
kubectl scale deployment/cartservice -n boutique --replicas=0

# 2. List available backups
gcloud beta container backup-restores backups list \
  --location=europe-west1 \
  --backup-plan=boutique-daily \
  --project=boutique-gke \
  --format="table(name,state,createTime)"

# 3. Create restore (replace BACKUP_NAME)
gcloud beta container backup-restores restores create redis-restore-$(date +%Y%m%d) \
  --location=europe-west1 \
  --backup=BACKUP_NAME \
  --project=boutique-gke

# 4. Monitor restore
gcloud beta container backup-restores restores describe RESTORE_NAME \
  --location=europe-west1 --project=boutique-gke

# 5. Scale cartservice back up
kubectl scale deployment/cartservice -n boutique --replicas=1
kubectl get pods -n boutique -l app=redis-cart
```

**Full cluster restore:** Follow [cluster-rebuild.md](../sre/runbooks/cluster-rebuild.md) then selective namespace restore from GKE Backup.

### Validation

```bash
kubectl get pods -n boutique -l app=redis-cart
kubectl exec -n boutique deploy/cartservice -- wget -qO- http://redis-cart:6379/ 2>&1 | head
# Manual: add item to cart, refresh, confirm persistence
curl -I https://boutique.biroltilki.art
```

### Expected outcome

- Redis pod healthy; cart operations succeed
- Restore job state: `SUCCEEDED`
- Acceptable session loss for in-flight users during maintenance window

### Recovery steps

1. If restore fails, try previous backup snapshot
2. If data unrecoverable, restart Redis empty (users get fresh carts) — document SEV2 if checkout impacted
3. Run [redis-cart-down.md](../sre/runbooks/redis-cart-down.md) triage steps

### Best practices

- Announce maintenance window before restore
- Scale down writers before restore to prevent split-brain writes
- Validate restore in game day / quarterly drill before relying on it in SEV1

**Further reading:** [redis-restore.md](../sre/runbooks/redis-restore.md)

---

## Incident Response

### Purpose

Standardize detection, classification, mitigation, communication, and closure for production incidents.

### Commands

```bash
# Acknowledge in PagerDuty (mobile/web)

# Classify severity — see table in severity.md
# Open matching runbook
ls docs/sre/runbooks/

# Initial triage
curl -I https://boutique.biroltilki.art
kubectl get pods -n boutique
kubectl -n argocd get applications
gcloud monitoring incidents list --project=boutique-gke --limit=5

# Timeline: record UTC timestamps in PagerDuty notes
```

**Severity quick reference:**

| SEV  | Definition                             | Response                 |
| ---- | -------------------------------------- | ------------------------ |
| SEV1 | Complete outage / data loss risk       | Immediate page; war room |
| SEV2 | Major degradation / budget exhausted   | Page; stakeholder comms  |
| SEV3 | Partial degradation; workaround exists | Ticket; business hours   |
| SEV4 | Minor; no user impact                  | Backlog                  |

### Validation

- Incident title includes `SEVn`
- Runbook URL opened from alert or `docs/sre/runbooks/`
- Stakeholder comms sent for SEV1–SEV2 ([comms.md](../sre/incident-response/comms.md))

### Expected outcome

- Acknowledge within 5 minutes (SEV1–SEV2)
- Mitigation started within 15 minutes (SEV1)
- Resolution documented with UTC timeline
- Postmortem scheduled for SEV1–SEV2 within 5 business days

### Recovery steps

1. Stabilize (rollback, scale, restart) before root-cause deep dive
2. Escalate per [escalation.md](../sre/oncall/escalation.md) if SLA breached
3. Resolve PagerDuty incident only after validation passes
4. File postmortem — [Postmortem checklist](#postmortem-checklist)

### Best practices

- Blameless culture; focus on systems and process
- One incident commander for SEV1
- Do not close incidents without smoke validation
- Error budget at 0% → minimum SEV2

**Further reading:** [severity.md](../sre/incident-response/severity.md) · [oncall/README.md](../sre/oncall/README.md) · [comms.md](../sre/incident-response/comms.md)

---

## Health Checks

### Purpose

Verify liveness of external endpoints, platform components, and application pods before and after changes.

### Commands

**External (synthetic):**

```bash
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
```

**Kubernetes:**

```bash
kubectl get nodes
kubectl get pods -n boutique
kubectl get pods -n argocd
kubectl get pods -n external-secrets
kubectl get pods -n kyverno
```

**Application probes (kubelet-enforced):**

```bash
kubectl describe pod -n boutique -l app=frontend | grep -A5 "Liveness\|Readiness"
```

**Uptime checks (GCP):**

```bash
gcloud monitoring uptime list-configs --project=boutique-gke
```

### Validation

```bash
# No failing pods in critical namespaces
kubectl get pods -A --field-selector=status.phase!=Running,status.phase!=Succeeded

# Managed cert active
kubectl get managedcertificate -A
```

### Expected outcome

- External URLs: HTTP 200/302, valid TLS
- All platform and app pods `Running` with ready containers
- ManagedCertificate status: `Active`
- Uptime checks: passing

### Recovery steps

| Check fails   | Next step                                                        |
| ------------- | ---------------------------------------------------------------- |
| DNS           | [dns.md](../dns.md)                                              |
| TLS / cert    | [Certificate rotation](#certificate-rotation)                    |
| Pod not ready | `kubectl describe pod`, logs, events                             |
| Uptime check  | [uptime-check-failed.md](../sre/runbooks/uptime-check-failed.md) |

### Best practices

- Run health checks after every deploy and sync
- Automate external checks in CI smoke job where possible
- Kyverno requires probes on all workloads — do not disable to "fix" alerts

**Further reading:** [16-smoke-validation.md](../setup/16-smoke-validation.md)

---

## Monitoring

### Purpose

Observe system health via SLOs, dashboards, metrics, and traces to detect degradation before users report it.

### Commands

```bash
# SLO status
gcloud monitoring slos list --project=boutique-gke

# List alert policies
gcloud alpha monitoring policies list --project=boutique-gke \
  --format="table(displayName,enabled)"

# Grafana (in-cluster — port-forward if needed)
kubectl -n observability get pods -l app.kubernetes.io/name=grafana
kubectl -n observability port-forward svc/grafana 3000:80

# Cloud Trace (checkout path)
gcloud trace list --project=boutique-gke --limit=10
```

**Key dashboards:**

| Dashboard          | Location                           |
| ------------------ | ---------------------------------- |
| SLO / error budget | Cloud Monitoring → SLOs            |
| On-call triage     | Grafana (`observability/grafana/`) |
| LB / ingress       | Cloud Monitoring → HTTPS LB        |

### Validation

```bash
# OTel collector exporting
kubectl logs -n observability -l app=otel-collector --tail=20

# Managed Prometheus targets (if applicable)
kubectl get servicemonitor -A 2>/dev/null || true
```

### Expected outcome

- SLO compliance visible for Browse and Checkout
- Metrics flowing to Managed Prometheus / Cloud Monitoring
- Traces available for checkout latency debugging
- No gaps > 5 min in critical metric ingestion

### Recovery steps

1. OTel collector down → restart deployment; check NetworkPolicy egress
2. SLO data missing → verify metric descriptors and SLI queries in [slos/catalog.md](../sre/slos/catalog.md)
3. Grafana unreachable → check pod health and datasource config

### Best practices

- SLOs owned by SRE; dashboards owned by Platform
- Avoid high-cardinality labels in custom metrics
- Correlate metrics + traces + logs during incidents

**Further reading:** [13-observability-slos.md](../setup/13-observability-slos.md) · [slos/catalog.md](../sre/slos/catalog.md)

---

## Alerting

### Purpose

Route actionable signals to PagerDuty with runbook links; minimize false positives via multi-window burn-rate alerting.

### Commands

```bash
# List notification channels
gcloud alpha monitoring channels list --project=boutique-gke

# List burn-rate policies
gcloud alpha monitoring policies list --project=boutique-gke \
  --filter='displayName~"burn"' --format="table(displayName,enabled)"

# Test alert path
# Follow docs/sre/oncall/test-alerts.md
./scripts/create-uptime-check.sh   # if re-creating checks
./scripts/create-burn-rate-policies.sh
```

**Alert → runbook mapping:**

| Alert policy               | Runbook                                                                    |
| -------------------------- | -------------------------------------------------------------------------- |
| `browse-availability-burn` | [browse-availability-burn.md](../sre/runbooks/browse-availability-burn.md) |
| `checkout-latency-burn`    | [checkout-latency-burn.md](../sre/runbooks/checkout-latency-burn.md)       |
| `uptime-check-failed`      | [uptime-check-failed.md](../sre/runbooks/uptime-check-failed.md)           |
| Deploy failure spike       | [bad-deploy-rollback.md](../sre/runbooks/bad-deploy-rollback.md)           |
| Redis/cart down            | [redis-cart-down.md](../sre/runbooks/redis-cart-down.md)                   |

### Validation

```bash
# Confirm runbook URL in policy documentation field
gcloud alpha monitoring policies describe POLICY_ID --project=boutique-gke \
  --format="yaml(documentation)"
```

Fire test alert per [test-alerts.md](../sre/oncall/test-alerts.md); confirm PagerDuty incident with runbook link.

### Expected outcome

- Fast-burn (1h) pages on 14.4× budget consumption
- Slow-burn (3d) creates ticket at 1× consumption
- Every page includes link to matching runbook
- Test alert resolves end-to-end < 5 min

### Recovery steps

| Issue            | Action                                                                           |
| ---------------- | -------------------------------------------------------------------------------- |
| Alert storm      | Silence with documented reason; tune thresholds                                  |
| No page received | Verify PagerDuty integration channel                                             |
| Wrong severity   | Adjust burn windows — [burn-rate-alerting.md](../sre/slos/burn-rate-alerting.md) |

### Best practices

- Every alert must be actionable
- Tune thresholds after false positives — do not disable permanently
- Game day 04 validates alert routing quarterly

**Further reading:** [14-pagerduty.md](../setup/14-pagerduty.md) · [burn-rate-alerting.md](../sre/slos/burn-rate-alerting.md)

---

## Logging

### Purpose

Triage incidents, build log-based metrics, and support audit/compliance via centralized Cloud Logging.

### Commands

```bash
# Recent errors — frontend
gcloud logging read \
  'resource.type="k8s_container"
   resource.labels.namespace_name="boutique"
   resource.labels.container_name="server"
   severity>=ERROR' \
  --project=boutique-gke --limit=20 --format=json

# Argo CD sync failures
gcloud logging read \
  'resource.type="k8s_container"
   resource.labels.namespace_name="argocd"
   textPayload:"sync"' \
  --project=boutique-gke --limit=20

# kubectl fallback
kubectl logs -n boutique -l app=frontend --tail=100
kubectl logs -n boutique -l app=checkoutservice --tail=100

# Kyverno denials
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno --tail=50 | grep deny
```

### Validation

```bash
# Confirm logs arriving (last 5 min)
gcloud logging read \
  'resource.type="k8s_container"
   resource.labels.cluster_name="boutique-gke"' \
  --project=boutique-gke --freshness=5m --limit=1
```

### Expected outcome

- Container logs visible in Cloud Logging within ~1–2 min
- Structured JSON logs parseable for log-based metrics
- Audit logs enabled for admin activity

### Recovery steps

1. Missing logs → verify Fluent Bit / GKE logging agent pods in `kube-system`
2. NetworkPolicy blocking egress → allow logging.googleapis.com
3. Log volume spike → adjust retention filters; investigate error loop

### Best practices

- Use correlation IDs across checkout path (OTel trace ID in logs)
- Never log secrets or PII
- Create log-based metrics for checkout failure rate

**Further reading:** [architecture/overview.md §13](../architecture/overview.md#13-observability--signal-ownership)

---

## Maintenance

### Purpose

Perform planned hygiene tasks without impacting SLOs: certificate checks, policy reviews, backup drills, and platform housekeeping.

### Commands

**Weekly:**

```bash
gcloud monitoring slos list --project=boutique-gke
kubectl -n argocd get applications
curl -I https://boutique.biroltilki.art
```

**Monthly:**

```bash
# Kyverno policy reports
kubectl get policyreport -A 2>/dev/null || kubectl get clusterpolicyreport

# Failed admissions
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno --since=720h | grep -c deny || true

# Orphan resource scan (non-destructive)
./scripts/teardown/orphan-resource-scan.sh
```

**Quarterly:**

```bash
# Backup restore drill — see Restore section
# Secret rotation drill — see Secret rotation section
# Game day — docs/sre/game-days/
```

### Validation

Document pass/fail for each maintenance item in team tracker or PR.

### Expected outcome

- No undetected SLO burn > 24h
- Kyverno deny rate stable and explained
- Backup drill successful within RTO
- No orphan GCP resources accumulating cost

### Recovery steps

Defer non-critical maintenance if error budget < 25%; reschedule after reliability work.

### Best practices

- Maintenance windows announced for checkout-path changes
- Pair monthly reviews with error budget review
- Track maintenance in shared calendar

**Further reading:** [day-2-ops.md](day-2-ops.md)

---

## Upgrades

### Purpose

Safely upgrade cluster, platform components, and application dependencies with rollback plans.

### Commands

**GKE control plane / node upgrade (Terraform or gcloud):**

```bash
# Check available versions
gcloud container get-server-config \
  --region=europe-west1 --project=boutique-gke

# Terraform: update GKE module version / release channel
cd terraform/environments/boutique
terraform plan -target=module.gke
terraform apply

# Verify nodes
kubectl get nodes -o wide
```

**Platform Helm upgrades (Argo CD, Kyverno, ESO):**

```bash
# Update chart version in gitops/ → PR → manual sync
argocd app diff argocd
argocd app sync argocd
```

**Application image upgrade:**

```bash
# Trigger build-scan-sign with new upstream_version
# Merge digest PR → sync boutique
```

**Cosign / Binary Auth key rotation:**

```bash
# Update COSIGN keys in GitHub Secrets
# Update cosign_public_key_pem in terraform.tfvars
terraform apply -target=module.binary_authorization
```

### Validation

```bash
kubectl get nodes
kubectl get pods -A | grep -v Running | grep -v Completed
curl -I https://boutique.biroltilki.art
make validate  # local manifest/policy checks
```

### Expected outcome

- All nodes on target version
- Platform pods healthy post-upgrade
- Smoke validation passes — [16-smoke-validation.md](../setup/16-smoke-validation.md)
- No new Kyverno or Binary Auth denials

### Recovery steps

1. GKE upgrade failure → pause upgrade; consult GKE release notes
2. Platform regression → Git revert + Argo sync
3. Node pool issues → cordon/drain problematic nodes

### Best practices

- Upgrade control plane before node pools
- One major upgrade per change window
- Run game day after GKE minor version bump
- Pin Helm chart versions in Git — no floating tags

---

## Certificate Rotation

### Purpose

Maintain valid TLS for public hostnames. This environment uses **Google-managed certificates** on GKE Ingress — rotation is automatic when DNS and ManagedCertificate CRs are correct.

### Commands

```bash
# Check ManagedCertificate status
kubectl get managedcertificate -A
kubectl describe managedcertificate boutique-managed-cert -n argocd
kubectl describe managedcertificate -n boutique  # storefront cert

# DNS must point at correct static IPs
gcloud compute addresses list --global --project=boutique-gke \
  --filter="name:(boutique-ingress-ip OR argocd-ingress-ip)"

dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art

# TLS verification
curl -vI https://boutique.biroltilki.art 2>&1 | grep -E 'expire|issuer|SSL'
echo | openssl s_client -connect boutique.biroltilki.art:443 -servername boutique.biroltilki.art 2>/dev/null | openssl x509 -noout -dates
```

**If cert stuck in Provisioning:**

```bash
kubectl describe ingress -n boutique
kubectl describe ingress -n argocd
# Confirm managed-cert annotation and correct domain list
```

### Validation

```bash
kubectl get managedcertificate -A -o custom-columns=\
NAME:.metadata.name,NS:.metadata.namespace,STATUS:.status.certificateStatus,DOMAINS:.spec.domains
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
```

### Expected outcome

- ManagedCertificate `certificateStatus`: `Active`
- `curl` shows valid Google-managed cert; no expiry warnings within 30 days
- Auto-renewal handled by Google before expiry

### Recovery steps

1. DNS mismatch → fix A records per [dns.md](../dns.md)
2. Wrong static IP on Ingress → fix `kubernetes.io/ingress.global-static-ip-name` annotation
3. Domain removed from cert CR → update ManagedCertificate domains in Git; sync
4. Persistent failure > 1h → SEV3; open incident

### Best practices

- Monitor cert expiry externally even with managed certs (uptime check)
- Never manually import TLS secrets unless architecture changes
- Keep both hostnames on correct dedicated static IPs

**Further reading:** [06-ingress-tls.md](../setup/06-ingress-tls.md) · [managed-certificate.yaml](../../gitops/bootstrap/argocd/managed-certificate.yaml)

---

## Secret Rotation

### Purpose

Rotate secrets in Secret Manager and propagate to workloads via External Secrets Operator without committing values to Git.

### Commands

```bash
# List secrets (metadata only)
gcloud secrets list --project=boutique-gke

# Add new secret version (interactive — do not echo secret in shell history)
read -s NEW_VALUE
echo -n "${NEW_VALUE}" | gcloud secrets versions add SECRET_NAME \
  --project=boutique-gke --data-file=-

# Force ESO refresh (if not waiting for refreshInterval)
kubectl annotate externalsecret SECRET_NAME -n boutique \
  force-sync=$(date +%s) --overwrite

# Verify Kubernetes Secret updated
kubectl get externalsecret -n boutique
kubectl get secret -n boutique -o jsonpath='{.items[*].metadata.name}'
```

**Rotate ESO / Workload Identity (rare):**

```bash
# Verify WI binding intact
gcloud iam service-accounts get-iam-policy \
  external-secrets@boutique-gke.iam.gserviceaccount.com
kubectl get sa external-secrets -n external-secrets -o yaml | grep iam.gke.io
```

### Validation

```bash
kubectl get externalsecret -n boutique -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'
# Restart workloads if they cache secrets at startup
kubectl rollout restart deployment -n boutique -l app=frontend
```

### Expected outcome

- New Secret Manager version active
- ExternalSecret `Ready=True`
- Workloads pick up new values after rollout (if required)
- No plain Secrets created outside ESO

### Recovery steps

1. Bad secret version → disable version in Secret Manager; re-add correct value
2. ESO not syncing → check ClusterSecretStore, WI, Kyverno `block-plain-secrets`
3. App still failing → rolling restart affected deployments

### Best practices

- Rotate on schedule (quarterly minimum for long-lived tokens)
- Test rotation in maintenance window
- Never commit secret values; use Secret Manager audit logs
- Kyverno blocks plain Secret resources — use ExternalSecret only

**Further reading:** [10-external-secrets.md](../setup/10-external-secrets.md) · [iam-matrix.md](../security/iam-matrix.md)

---

## Troubleshooting

### Purpose

Systematic diagnosis for common failure modes across edge, GitOps, policy, and application layers.

### Commands

```bash
# Layer 1 — Edge
dig +short boutique.biroltilki.art
curl -vI https://boutique.biroltilki.art 2>&1 | head -30
kubectl get ingress -A
kubectl get managedcertificate -A

# Layer 2 — GitOps
kubectl -n argocd get applications
argocd app get boutique
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-server --tail=50

# Layer 3 — Policy / admission
kubectl get clusterpolicy
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno --tail=50

# Layer 4 — Workloads
kubectl get pods -n boutique
kubectl describe pod -n boutique <pod>
kubectl logs -n boutique <pod> --previous

# Layer 5 — Events
kubectl get events -n boutique --sort-by='.lastTimestamp' | tail -20
```

### Validation

Identify failing layer; apply targeted fix; re-run smoke checks.

### Expected outcome

Root cause identified within one layer; fix validated before incident closure.

### Recovery steps

See [Common incidents](#common-incidents) and cross-cutting guides:

- [argocd-sync-failures.md](../troubleshooting/argocd-sync-failures.md)
- [kyverno-denials.md](../troubleshooting/kyverno-denials.md)

### Best practices

- Top-down triage: DNS → TLS → Ingress → GitOps → Pods
- Capture `kubectl describe` and logs before restarting pods
- Check recent merges and Argo sync history first

---

## Common incidents

### Purpose

Quick reference for frequently encountered production issues with immediate actions.

| Incident                | Symptoms                        | First commands                                                | Runbook                                                                     |
| ----------------------- | ------------------------------- | ------------------------------------------------------------- | --------------------------------------------------------------------------- |
| Storefront down         | Uptime check fail; curl timeout | `curl -I`, `kubectl get ingress -n boutique`                  | [uptime-check-failed](../sre/runbooks/uptime-check-failed.md)               |
| Bad deploy              | CrashLoopBackOff; SLO burn      | `kubectl get pods -n boutique`, `argocd app history boutique` | [bad-deploy-rollback](../sre/runbooks/bad-deploy-rollback.md)               |
| Checkout errors         | Checkout SLO burn               | `kubectl logs -n boutique -l app=checkoutservice`             | [checkout-availability-burn](../sre/runbooks/checkout-availability-burn.md) |
| Cart empty / Redis down | Cart API 5xx                    | `kubectl get pods -n boutique -l app=redis-cart`              | [redis-cart-down](../sre/runbooks/redis-cart-down.md)                       |
| Argo sync fail          | App Degraded                    | `argocd app get boutique`                                     | [argocd-sync-failures](../troubleshooting/argocd-sync-failures.md)          |
| Kyverno block           | Sync denied                     | `kubectl logs -n kyverno --tail=20`                           | [kyverno-denials](../troubleshooting/kyverno-denials.md)                    |
| Cert provisioning       | TLS errors                      | `kubectl describe managedcertificate -A`                      | [Certificate rotation](#certificate-rotation)                               |
| CI / WIF failure        | Actions red; no digest PR       | GitHub Actions logs                                           | [07-github-wif.md](../setup/07-github-wif.md)                               |
| Zone / node loss        | Pods Pending                    | `kubectl get nodes`, `kubectl get pdb -n boutique`            | [02-zone-pod-failure](../sre/game-days/02-zone-pod-failure.md)              |

### Commands

```bash
# Universal triage bundle
export PROJECT_ID=boutique-gke
curl -sS -o /dev/null -w "boutique: %{http_code}\n" https://boutique.biroltilki.art
kubectl get pods -n boutique --no-headers | awk '$3!="Running"{print}'
kubectl -n argocd get application boutique -o jsonpath='{.status.health.status}{"\n"}'
```

### Validation

Incident-specific validation in linked runbook; minimum: storefront HTTP 200 and checkout manual test.

### Expected outcome

Service restored within RTO for incident class; timeline documented.

### Recovery steps

1. Match symptom to table
2. Execute runbook steps in order
3. Escalate if not mitigated within severity SLA

### Best practices

- Do not skip runbooks during stress
- Update table after each postmortem with new patterns
- Practice top 3 scenarios in game days

---

## Recovery procedures

### Purpose

Consolidated recovery playbooks by failure domain.

| Domain                 | Procedure                                   | Doc                                                      |
| ---------------------- | ------------------------------------------- | -------------------------------------------------------- |
| Application deploy     | Git revert → Argo sync → smoke              | [Rollback](#rollback)                                    |
| Redis data             | Scale down → GKE Backup restore → scale up  | [redis-restore](../sre/runbooks/redis-restore.md)        |
| Full cluster           | Terraform apply → bootstrap → GitOps sync   | [cluster-rebuild](../sre/runbooks/cluster-rebuild.md)    |
| Ingress / TLS          | Fix DNS/IP/cert CR                          | [Certificate rotation](#certificate-rotation)            |
| Secrets                | Secret Manager version → ESO sync → rollout | [Secret rotation](#secret-rotation)                      |
| Monitoring blind       | Restart OTel; verify NetworkPolicy          | [Monitoring](#monitoring)                                |
| Policy blocking deploy | Fix Git manifest; never `--skip-validation` | [kyverno-denials](../troubleshooting/kyverno-denials.md) |

### Commands

```bash
# Post-recovery validation bundle (run after any recovery)
./scripts/bootstrap/validate-prereqs.sh 2>/dev/null || true
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
kubectl get pods -n boutique
kubectl -n argocd get applications
```

### Validation

Full smoke checklist: [16-smoke-validation.md](../setup/16-smoke-validation.md)

### Expected outcome

All recovery procedures end with passing smoke validation and resolved PagerDuty incident.

### Recovery steps

If smoke fails after recovery, roll back recovery change and escalate SEV2.

### Best practices

- Document which procedure was executed in incident notes
- Prefer Git-declared state over imperative fixes
- Schedule follow-up to remove temporary measures

---

## Postmortem checklist

### Purpose

Ensure blameless, actionable learning from SEV1–SEV2 incidents (and repeated SEV3s).

### Commands

```bash
# Create from template
cp docs/sre/postmortems/TEMPLATE.md \
   docs/sre/postmortems/$(date +%Y-%m-%d)-short-title.md
```

### Checklist

- [ ] **Title, date, severity, authors** filled in
- [ ] **Summary** — one paragraph, customer impact focused
- [ ] **Impact** — duration, users affected, SLO/error budget consumed
- [ ] **Timeline (UTC)** — detection → mitigation → resolution
- [ ] **Root cause** — 5 whys; no blame on individuals
- [ ] **What went well / poorly**
- [ ] **Action items** — owner, due date, priority for each
- [ ] **Lessons learned**
- [ ] Runbook updated if steps were wrong or missing
- [ ] Alert tuned if false positive/negative
- [ ] Game day scenario added if gap found
- [ ] Review meeting held within 5 business days (SEV1–SEV2)
- [ ] Action items tracked to completion in issue tracker

### Validation

Peer review by another engineer; SRE lead signs off on action item owners.

### Expected outcome

Published postmortem in `docs/sre/postmortems/`; action items in backlog with owners.

### Recovery steps

N/A — postmortems are retrospective.

### Best practices

- Blameless language throughout
- Focus on systemic improvements
- Share summary with stakeholders for SEV1–SEV2
- Link postmortem from PagerDuty incident

**Template:** [postmortems/TEMPLATE.md](../sre/postmortems/TEMPLATE.md)

---

## Automation opportunities

### Purpose

Identify safe automation candidates to reduce toil while preserving manual sync and change-control gates.

### Current automation (implemented)

| Area                | Automation           | Location                                   |
| ------------------- | -------------------- | ------------------------------------------ |
| CI build/scan/sign  | GitHub Actions + WIF | `.github/workflows/build-scan-sign.yml`    |
| Digest promotion    | PR from CI           | `.github/workflows/manifest-digest-pr.yml` |
| Policy validation   | pre-commit, CI       | `Makefile`, `.github/workflows/ci.yml`     |
| Terraform plan      | PR comment           | `.github/workflows/terraform-plan.yml`     |
| Alert policies      | Scripts              | `scripts/create-burn-rate-policies.sh`     |
| Game day injection  | Scripts              | `scripts/game-days/`                       |
| Teardown validation | Scripts              | `scripts/teardown/`                        |

### Recommended future automation

| Opportunity                   | Benefit                      | Guardrails                                          |
| ----------------------------- | ---------------------------- | --------------------------------------------------- |
| Post-sync smoke in CI         | Catch regressions early      | Manual Argo sync remains; smoke after operator sync |
| Scheduled backup verification | Prove RPO continuously       | Alert on failure; no auto-restore                   |
| Error budget dashboard bot    | Weekly Slack/email summary   | Read-only                                           |
| Certificate expiry synthetic  | Early warning                | Complement managed cert auto-renewal                |
| Orphan resource scan cron     | Cost control                 | Weekly report only; no auto-delete                  |
| Runbook link linter           | Alert policy drift detection | CI check on `observability/monitoring/`             |
| Automated game day scheduler  | Quarterly reminder           | Human executes inject steps                         |

### Commands

```bash
# Validate existing automation locally
make validate
make test
pre-commit run --all-files
```

### Validation

CI green on `main`; game day scripts run successfully in dry-run where supported.

### Expected outcome

Toil reduced without bypassing security gates (Binary Auth, Kyverno, manual sync).

### Recovery steps

Disable automation that causes false-positive rollbacks; fix and re-enable via PR.

### Best practices

- Automate detection, not production mutation (except approved CI paths)
- Never auto-sync Argo CD to production ([ADR-003](../adr/003-manual-argocd-sync.md))
- Every automation needs an owner and on-call runbook if it can page
- Test automation in PR before enabling scheduled runs

---

## Quick reference card

```
┌─────────────────────────────────────────────────────────────────┐
│ boutique-gke-sre — on-call quick reference                      │
├─────────────────────────────────────────────────────────────────┤
│ Storefront:  https://boutique.biroltilki.art                    │
│ Argo CD:     https://argocd.boutique.biroltilki.art             │
│ Rollback:    git revert → argocd app sync boutique              │
│ Severity:    docs/sre/incident-response/severity.md           │
│ Runbooks:    docs/sre/runbooks/                                 │
│ Quick ref:   docs/operations/quick-reference.md  (printable)  │
│ Smoke:       docs/setup/16-smoke-validation.md                  │
│ Escalation:  docs/sre/oncall/escalation.md                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Document history

| Version | Date       | Author       | Notes                                    |
| ------- | ---------- | ------------ | ---------------------------------------- |
| 1.0     | 2026-07-04 | Platform/SRE | Initial comprehensive operations runbook |
