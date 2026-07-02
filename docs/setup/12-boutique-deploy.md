# Online Boutique deploy

## Goal

Deploy Google Online Boutique to the `boutique` namespace via Argo CD **manual sync**, using digest-pinned images from `gitops/apps/boutique/values-images.yaml`, and confirm the storefront responds at **https://boutique.biroltilki.art**. All Kyverno policies and Binary Authorization checks must pass during sync.

## Why this step is required

This is the first full application workload on the production-ready platform (Phase 4 gate complete). It validates the entire supply chain built in topics 07–11:

- CI promotes image **digests** (not tags) into `values-images.yaml`
- Argo CD renders the Helm chart in `gitops/apps/boutique/`
- Kyverno enforces probes, resources, digests, and labels
- Binary Authorization verifies signed images at deploy time
- ESO pattern is ready for any application secrets

Manual sync ensures a human explicitly promotes each revision after PR review.

## Prerequisites

- Prior guides through [11-kyverno-policies.md](11-kyverno-policies.md) — **Phase 4 gate complete**
- **Scaffold gate:** `gitops/apps/boutique/templates/` must contain Helm templates and `values-images.yaml` must have uncommented digest pins before sync succeeds
- Artifact Registry images built and signed (topic 08); digests recorded in `values-images.yaml`
- Argo CD CLI logged in or UI access at https://argocd.boutique.biroltilki.art
- `boutique` namespace labeled: `network-policy.biroltilki.art/tier=application`
- NetworkPolicies applied including `boutique-frontend-ingress` (frontend pods must have label `app: frontend`)
- Tools: `kubectl`, `argocd` CLI, `curl`, `dig`, `helm` (optional for local template)

## Commands

### 1. Verify digest-only image values

Open `gitops/apps/boutique/values-images.yaml`. Every image must use a digest pin — never `:latest`:

```yaml
# Example structure (replace digests with values from CI / Artifact Registry)
images:
  frontend:
    repository: europe-west1-docker.pkg.dev/boutique-gke/boutique/frontend
    digest: sha256:abc123...
```

Confirm no floating tags:

```bash
grep -E ':latest|tag:' gitops/apps/boutique/values-images.yaml && echo "FAIL: floating tag found" || echo "OK: digest-only"
```

### 2. Local render check (optional, before sync)

```bash
helm template boutique gitops/apps/boutique/ \
  -f gitops/apps/boutique/values.yaml \
  -f gitops/apps/boutique/values-images.yaml \
  | head -50
```

Dry-run against the API server to catch Kyverno denials early:

```bash
helm template boutique gitops/apps/boutique/ \
  -f gitops/apps/boutique/values.yaml \
  -f gitops/apps/boutique/values-images.yaml \
  | kubectl apply --dry-run=server -f -
```

### 3. Ensure the Argo CD Application exists

Sync the root app-of-apps if the `boutique` Application is not yet visible:

```bash
argocd app sync boutique-root
argocd app list | grep boutique
```

The Application manifest is `gitops/apps/argocd-apps/boutique-application.yaml`.

### 4. Manual sync the Boutique application

```bash
argocd app diff boutique
argocd app sync boutique --prune
argocd app wait boutique --health --timeout 600
```

In the Argo CD UI: Applications → `boutique` → **Sync** → select resources → **Synchronize** (no auto-sync).

### 5. Watch rollout

```bash
kubectl -n boutique get pods -w
```

Wait until all pods are `Running` and readiness probes pass.

### 6. Verify Ingress for the storefront

```bash
kubectl -n boutique get ingress
kubectl -n boutique describe ingress
```

The boutique Ingress should use the same global static IP (`boutique-ingress-ip`) and a Google-managed certificate for `boutique.biroltilki.art` (configured in Helm templates or overlay — see `gitops/apps/boutique/templates/`).

## Expected output

- `argocd app sync boutique` completes with `Sync Status: Synced`, `Health: Healthy`
- `kubectl -n boutique get pods` — all microservice pods `Running`, `READY` matches desired
- `kubectl -n boutique get svc,ingress` — frontend Service and Ingress present
- `curl -I https://boutique.biroltilki.art` returns `HTTP/2 200`
- Browsing the URL in a browser shows the Online Boutique storefront

## Validation

```bash
# DNS points at the static ingress IP
dig +short boutique.biroltilki.art

# Storefront HTTPS healthy
curl -I https://boutique.biroltilki.art

# Argo CD application healthy
argocd app get boutique

# All pods ready
kubectl -n boutique get pods

# Images use digests (spot-check frontend)
kubectl -n boutique get pod -l app=frontend -o jsonpath='{.items[0].spec.containers[0].image}'
# Expected: ...@sha256:...

# Kyverno did not audit-fail (optional)
kubectl get policyreport -n boutique
```

**Pass criteria:** Storefront loads over HTTPS; all pods Running; Argo CD `boutique` app Synced/Healthy; images show `@sha256:` digests.

## Common problems

| Symptom                         | Cause                                 | Fix                                                                                   |
| ------------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------- |
| Sync failed — Kyverno denied    | Missing probes, resources, or digest  | Fix Helm templates or values; re-run dry-run                                          |
| `ImagePullBackOff`              | Wrong digest or missing AR permission | Verify digest in AR; check node SA has `artifactregistry.reader`                      |
| Binary Authorization blocked    | Image not signed / attestor mismatch  | Re-run CI sign+attest; verify policy in topic 08                                      |
| `OutOfSync` loop                | Helm hooks or ignored differences     | Check `argocd app diff`; add ignoreDifferences if intentional                         |
| 502 / connection timeout on URL | Ingress or managed cert not ready     | Check `ManagedCertificate` status; verify DNS                                         |
| Cart/checkout errors            | NetworkPolicy too restrictive         | Confirm all NetPol files synced; `app.kubernetes.io/part-of: boutique` on all pods    |
| 502 on storefront URL           | Frontend ingress blocked              | Apply `boutique-frontend-ingress.yaml`; verify `app: frontend` on frontend Deployment |

## Recovery

- **Rollback via Git:** revert the digest PR in GitHub, merge, then `argocd app sync boutique`
- **Rollback via Argo CD history:** `argocd app rollback boutique <revision-id>`
- **Delete failed sync:** `argocd app sync boutique --force` only after fixing root cause
- **Full app removal:** `argocd app delete boutique` (does not remove namespace by default)

See runbook [bad-deploy-rollback.md](../sre/runbooks/bad-deploy-rollback.md) for incident-style rollback.

## Best practices

- Every image change flows: CI build → Trivy scan → cosign sign → digest PR → review → manual Argo sync
- Never hand-edit running deployments — change Git and sync
- Run `argocd app diff` before every production sync
- Keep `values.yaml` (config) and `values-images.yaml` (digests) separate for clean CI automation
- Smoke-test checkout path after deploy, not just the homepage

## Security notes

- Digest-only images prevent silent tag overwrites in the registry
- Binary Authorization is the last line of defense if a malicious digest is merged
- NetworkPolicies limit east-west traffic between microservices
- No application secrets in Helm values — use ESO `ExternalSecret` CRs
- Storefront is public by design; admin interfaces (Argo CD) should have additional access controls

## Next step

→ [Observability + SLOs](13-observability-slos.md)
