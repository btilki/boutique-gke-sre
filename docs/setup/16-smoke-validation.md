# Smoke validation + SRE verification

## Goal

Run the full **production bar** checklist: confirm HTTPS on both public URLs, GitOps and policy enforcement, observability and SLOs, PagerDuty routing, Cloud Armor, and SRE artifacts (runbooks, on-call docs). When this topic passes, bootstrap is complete and the cluster meets the definition of done in the project description.

## Why this step is required

Individual topics validate their own layer. This topic proves the **system** works as a production SRE reference — not a collection of partially configured components. It is the formal gate before game days, on-call rotation, and treating `boutique-gke` as the canonical demo environment.

Failing smoke validation here means deferring production-ready status until gaps are closed — even if topics 01–15 were marked complete individually.

## Prerequisites

- Prior guides through [15-cloud-armor.md](15-cloud-armor.md)
- All Phase 4 gate topics complete (09–11)
- Tools: `kubectl`, `argocd`, `gcloud`, `curl`, `dig`, `helm` (optional)
- Access: cluster admin, Cloud Monitoring viewer, PagerDuty (for alert test confirmation)
- [test-alerts.md](../sre/oncall/test-alerts.md) executed successfully in topic 14

## Commands

Work through this checklist in order. Record pass/fail for each item.

### 1. Infrastructure and HTTPS

```bash
# DNS — both hostnames resolve to the Terraform static IP
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art

# Compare to Terraform
cd terraform/environments/boutique && terraform output ingress_static_ip

# HTTPS — no TLS errors
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
```

**Pass:** Both `dig` results match static IP; both `curl` return `HTTP/2 200` or `302`.

### 2. GKE cluster health

```bash
kubectl get nodes
kubectl get pods -A | grep -v Running | grep -v Completed
```

**Pass:** All nodes Ready; no unexpected non-Running pods in platform namespaces.

### 3. Phase 4 gate — GitOps platform

```bash
# Argo CD
kubectl -n argocd get pods
argocd app list

# Manual sync only — no automated block on root app
kubectl -n argocd get application boutique-root -o yaml | grep -c 'automated:' || true
# Expected: 0 (no automated sync)

# ESO
kubectl -n external-secrets get pods
kubectl get clustersecretstore gcp-secret-manager

# Kyverno — five policies
kubectl get clusterpolicy | grep -E 'require-digest|require-probes|require-resources|require-netpol-labels|block-plain-secrets' | wc -l
# Expected: 5

# Deny :latest still works
kubectl apply --dry-run=server -f examples/kyverno-policy-test/bad-latest-pod.yaml 2>&1 | grep -i denied
```

**Pass:** Argo CD, ESO, Kyverno healthy; five policies; `:latest` denied.

### 4. Application — Online Boutique

```bash
argocd app get boutique
kubectl -n boutique get pods
kubectl -n boutique get ingress

# Digest-only images
kubectl -n boutique get pods -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' | grep -v '@sha256:' && echo "FAIL" || echo "OK: all digests"
```

**Pass:** Boutique Synced/Healthy; storefront `curl` returns 200; images use `@sha256:`.

### 5. Supply chain

```bash
# Binary Authorization policy exists (topic 08)
gcloud container binauthz policy export --project=boutique-gke 2>/dev/null | head -20

# Artifact Registry repository
gcloud artifacts repositories list --project=boutique-gke --location=europe-west1
```

**Pass:** Binary Auth policy requires attestation; AR repository exists.

### 6. Observability and SLOs

```bash
kubectl -n observability get pods
gcloud monitoring services list --project=boutique-gke
# Verify browse-availability and checkout-availability SLOs in Console (Monitoring → Services)

# Runbooks on disk
ls docs/sre/runbooks/*.md | wc -l
```

**Pass:** OTel/Grafana running; browse **99.9%** and checkout **99.95%** SLOs exist; runbooks present for each alert policy.

Verify SLO targets against [catalog.md](../sre/slos/catalog.md):

| SLO                   | Target |
| --------------------- | ------ |
| Browse availability   | 99.9%  |
| Checkout availability | 99.95% |

### 7. Alerting and on-call

Confirm from topic 14:

- [ ] PagerDuty notification channel configured
- [ ] Burn-rate policies attached to PagerDuty
- [ ] Test incident fired and resolved per [test-alerts.md](../sre/oncall/test-alerts.md)
- [ ] Runbook URLs visible in alert policy documentation

```bash
gcloud alpha monitoring channels list --project=boutique-gke --filter='displayName:"pagerduty"'
```

### 8. Edge security — Cloud Armor

```bash
gcloud compute security-policies describe boutique-owasp-crs --project=boutique-gke --format='value(name)'
```

**Pass:** Policy exists; boutique backend service has policy attached; storefront still reachable.

### 9. SRE artifact verification

```bash
# Runbooks
test -f docs/sre/runbooks/browse-availability-burn.md && echo OK browse runbook
test -f docs/sre/runbooks/checkout-availability-burn.md && echo OK checkout runbook
test -f docs/sre/runbooks/bad-deploy-rollback.md && echo OK rollback runbook

# On-call docs
test -f docs/sre/oncall/README.md && echo OK oncall
test -f docs/sre/oncall/test-alerts.md && echo OK test-alerts

# Game days
test -f docs/sre/game-days/01-bad-deploy-rollback.md && echo OK game-day-01

# Error budget policy
test -f docs/sre/error-budget-policy.md && echo OK error-budget

# Teardown path documented
test -f docs/teardown.md && echo OK teardown
```

### 10. Network policies

```bash
kubectl get networkpolicy -A
```

**Pass:** `default-deny` and `boutique-allow` policies exist.

## Expected output

When bootstrap is complete:

| Area          | Expected state                               |
| ------------- | -------------------------------------------- |
| DNS / TLS     | Both hostnames resolve; HTTPS 200/302        |
| Argo CD       | Synced apps; manual sync only                |
| ESO           | ClusterSecretStore Ready                     |
| Kyverno       | 5 ClusterPolicies enforcing                  |
| Boutique      | Healthy; digest-only images                  |
| Observability | OTel + Grafana Running; SLOs listed          |
| Alerting      | PagerDuty channel; test incident succeeded   |
| Cloud Armor   | CRS policy attached; storefront reachable    |
| SRE docs      | Runbooks, on-call, game days, teardown exist |

## Validation

Standard validation block (required for this topic):

```bash
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
```

**Production bar summary** — all must pass:

- [ ] One private GKE cluster (`boutique-gke`, regional, Workload Identity)
- [ ] Terraform + GCS remote state
- [ ] Valid HTTPS on `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art`
- [ ] GitOps via Argo CD; digest-only images; manual sync
- [ ] ESO + Secret Manager; Kyverno + NetworkPolicy
- [ ] Trivy + cosign + Binary Authorization (CI path from topic 07–08)
- [ ] SLOs + burn alerts + PagerDuty + OTel traces
- [ ] Cloud Armor on storefront
- [ ] Runbooks + on-call docs + alert test completed
- [ ] Teardown runbook validated (read-through)

## Common problems

| Symptom                  | Cause                          | Fix                                            |
| ------------------------ | ------------------------------ | ---------------------------------------------- |
| One checklist item fails | Skipped or partial prior topic | Return to the failing topic guide              |
| `curl` TLS error         | Cert or DNS regression         | Topics 05–06                                   |
| Kyverno deny count ≠ 5   | Policy not applied             | Topic 11                                       |
| SLO missing              | Topic 13 incomplete            | Create SLO in Console                          |
| No PagerDuty test record | Topic 14 skipped               | [test-alerts.md](../sre/oncall/test-alerts.md) |
| Images without digest    | CI not wired                   | Topic 08 + 12                                  |

## Recovery

If smoke validation fails:

1. Record which checklist item failed
2. Open the corresponding setup guide (topics 01–15)
3. Fix and re-validate that layer only
4. Re-run this checklist from the failed section

Do not proceed to game days until all items pass.

For environment teardown when the reference is no longer needed: [teardown.md](../teardown.md)

## Best practices

- Run this checklist after every major platform change
- Automate repeatable checks in CI (Kyverno tests, `helm template` dry-run) — keep this manual checklist for integration proof
- Store smoke test results in a change log or PR comment
- Schedule game day 01 within one week of passing smoke validation

## Security notes

- Smoke tests use read-only checks where possible; attack probes (Cloud Armor) only in controlled tests
- Do not expose Argo CD admin credentials during team walkthroughs
- Confirm no GCP JSON keys exist in GitHub or local repos: `gitleaks detect` (if pre-commit configured)
- Review IAM bindings quarterly after bootstrap

## Next step

Bootstrap is complete. Proceed to operational readiness:

| Step           | Action                          | Guide                                                                             |
| -------------- | ------------------------------- | --------------------------------------------------------------------------------- |
| First game day | Bad deploy rollback scenario    | [game-days/01-bad-deploy-rollback.md](../sre/game-days/01-bad-deploy-rollback.md) |
| On-call setup  | Rotation and playbook           | [oncall/README.md](../sre/oncall/README.md)                                       |
| Alert drill    | Re-test PagerDuty routing       | [oncall/test-alerts.md](../sre/oncall/test-alerts.md)                             |
| CI deploy path | Digest PR → review → Argo sync  | [12-boutique-deploy.md](12-boutique-deploy.md)                                    |
| Teardown       | Safe decommission when finished | [teardown.md](../teardown.md)                                                     |

Executive summary: [bootstrap.md](../bootstrap.md)
