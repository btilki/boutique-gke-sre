# Kyverno policies

## Goal

Install the Kyverno admission controller, deploy the five minimum ClusterPolicies from `gitops/policies/kyverno/`, sync NetworkPolicies from `gitops/policies/network-policies/`, and prove enforcement by denying a `:latest` image fixture. When complete, non-compliant workloads cannot reach the cluster.

> **Phase 4 gate:** Topics **09–11** must complete before treating the cluster as production-ready. **Do not proceed to Boutique deploy (topic 12) until this guide passes validation.**

## Why this step is required

Kyverno is the policy enforcement layer between GitOps and running pods. It implements the production baseline from the project description:

| Policy file                  | Rule                                              |
| ---------------------------- | ------------------------------------------------- |
| `require-digest.yaml`        | Reject `:latest`; require `@sha256:` digest       |
| `require-probes.yaml`        | Liveness + readiness probes required              |
| `require-resources.yaml`     | CPU/memory requests and limits required           |
| `require-netpol-labels.yaml` | Namespace tier label for NetworkPolicy compliance |
| `block-plain-secrets.yaml`   | Block plain `Secret` resources (ESO-only)         |

NetworkPolicies in `gitops/policies/network-policies/` (`default-deny.yaml`, `boutique-allow.yaml`, `boutique-frontend-ingress.yaml`) restrict pod-to-pod traffic and allow storefront ingress. Together with ESO (topic 10) and Binary Authorization (topic 08), this gate ensures only hardened workloads deploy.

## Prerequisites

- Prior guides: [09-argocd-bootstrap.md](09-argocd-bootstrap.md), [10-external-secrets.md](10-external-secrets.md) — including `eso-bootstrap-test` ExternalSecret synced
- Argo CD running; `boutique-root` Application registered
- Tools: `kubectl`, `helm`, `kyverno` CLI (optional, for policy tests)
- Install Kyverno CLI: `brew install kyverno` or see [Kyverno docs](https://kyverno.io/docs/kyverno-cli/)

## Commands

### 1. Install Kyverno via Helm

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --version 3.3.4 \
  --wait \
  --timeout 10m
```

### 2. Apply the five Kyverno ClusterPolicies

```bash
kubectl apply -f gitops/policies/kyverno/require-digest.yaml
kubectl apply -f gitops/policies/kyverno/require-probes.yaml
kubectl apply -f gitops/policies/kyverno/require-resources.yaml
kubectl apply -f gitops/policies/kyverno/require-netpol-labels.yaml
kubectl apply -f gitops/policies/kyverno/block-plain-secrets.yaml
```

Verify policies are active:

```bash
kubectl get clusterpolicy
```

### 3. Apply NetworkPolicies

```bash
kubectl apply -f gitops/policies/network-policies/default-deny.yaml
kubectl apply -f gitops/policies/network-policies/boutique-allow.yaml
kubectl apply -f gitops/policies/network-policies/boutique-frontend-ingress.yaml
```

Label the `boutique` namespace for NetworkPolicy compliance (required by `require-netpol-labels`):

```bash
kubectl label namespace boutique \
  network-policy.biroltilki.art/tier=application \
  --overwrite
```

### 4. Sync policies via Argo CD (GitOps path)

Alternatively, sync the `policies` Application defined in `gitops/apps/argocd-apps/policies-application.yaml`:

```bash
# Ensure root app is synced first so the policies Application exists
argocd app sync boutique-root --prune
argocd app sync policies --prune
```

Manual sync only — confirm in the Argo CD UI that `policies` shows `Synced`.

### 5. Run Kyverno CLI policy tests

The test manifest is `tests/kyverno/kyverno-test.yaml` (Kyverno CLI 1.6+ default filename). It runs **6 assertions** across `require-digest`, `require-probes`, and `require-resources` using fixtures in `examples/kyverno-policy-test/`.

```bash
# From repository root
kyverno test tests/kyverno/
# or: make kyverno-test
```

Expected: `Test Summary: 6 tests passed and 0 tests failed` — each row shows **Pass** because policies correctly rejected invalid fixtures (expected `fail` outcome).

### 6. Live cluster deny test (`:latest` fixture)

Apply the intentionally invalid pod from `examples/kyverno-policy-test/bad-latest-pod.yaml` with server-side dry-run:

```bash
kubectl apply --dry-run=server -f examples/kyverno-policy-test/bad-latest-pod.yaml
```

This must be **rejected** by Kyverno with a message about digest or `:latest`.

### 7. Confirm plain Secret is blocked

```bash
cat <<'EOF' | kubectl apply --dry-run=server -f -
apiVersion: v1
kind: Secret
metadata:
  name: plain-secret-test
  namespace: boutique
type: Opaque
stringData:
  key: value
EOF
```

Kyverno should deny this — use ESO `ExternalSecret` instead.

## Expected output

- `kubectl get pods -n kyverno` — Kyverno admission and background controllers `Running`
- `kubectl get clusterpolicy` — five policies listed, `Ready: true`
- `kyverno test tests/kyverno/` — 6 tests passed (digest, probes, resources fixtures)
- `kubectl apply --dry-run=server` on `bad-latest-pod.yaml` — `Error from server: admission webhook ... denied`
- Plain Secret dry-run — denied by `block-plain-secrets`

Example denial message (wording may vary):

```
admission webhook "validate.kyverno.svc" denied the request:
Images must use digest (@sha256:...) not :latest or floating tags.
```

## Validation

```bash
# Kyverno healthy
kubectl -n kyverno get pods
kubectl get clusterpolicy -o wide

# All five policies present
kubectl get clusterpolicy | grep -E 'require-digest|require-probes|require-resources|require-netpol-labels|block-plain-secrets'

# NetworkPolicies applied (boutique namespace)
kubectl get networkpolicy -n boutique

# ESO still allowed to materialize Secrets (topic 10)
kubectl -n boutique get externalsecret eso-bootstrap-test

# CLI test suite
kyverno test tests/kyverno/

# Live deny on :latest
kubectl apply --dry-run=server -f examples/kyverno-policy-test/bad-latest-pod.yaml 2>&1 | grep -i denied
```

**Pass criteria:** All five ClusterPolicies Ready; three NetworkPolicies in `boutique`; `kyverno test` passes (6 assertions); `:latest` pod and plain Secret denied at admission; `eso-bootstrap-test` ExternalSecret synced.

## Common problems

| Symptom                                   | Cause                                           | Fix                                                                                           |
| ----------------------------------------- | ----------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Policies not enforcing                    | Wrong webhook configuration / Kyverno not Ready | `kubectl -n kyverno logs deploy/kyverno-admission-controller`                                 |
| `kyverno test` fails — policy not found   | Wrong test filename or path                     | Use `tests/kyverno/kyverno-test.yaml` (default for Kyverno CLI 1.6+)                          |
| Valid pod denied                          | Missing probes, resources, or namespace label   | Compare manifest against each ClusterPolicy                                                   |
| Argo CD sync conflict                     | Helm-installed Kyverno + GitOps overlap         | Choose one install path; prefer GitOps for policies only                                      |
| NetworkPolicy blocks traffic unexpectedly | Missing allow rules or frontend label           | Apply all three NetPol files; frontend pods need `app: frontend`                              |
| `block-plain-secrets` blocks ESO secrets  | Policy match too broad                          | ESO creates Secrets via controller — ensure policy exempts ESO SA or uses correct match rules |

## Recovery

- **Disable a policy temporarily (break-glass only):** `kubectl patch clusterpolicy require-digest -p '{"spec":{"validationFailureAction":"Audit"}}' --type=merge`
- **Helm uninstall Kyverno:** removes webhooks — only during teardown; workloads lose enforcement immediately
- **Re-apply policies:** `kubectl apply -f gitops/policies/kyverno/`
- **Argo CD drift:** `argocd app sync policies --force`

Re-enable `Enforce` after debugging:

```bash
kubectl patch clusterpolicy require-digest -p '{"spec":{"validationFailureAction":"Enforce"}}' --type=merge
```

## Best practices

- Run `kyverno test tests/kyverno/` and `./tests/manifest/kubeconform.sh` in CI on every PR (`kyverno` and `manifests` jobs in `.github/workflows/ci.yml`)
- Use `validationFailureAction: Enforce` in production; `Audit` only during policy development
- Sync policies via Argo CD (`policies` Application) so cluster state matches Git
- Document any policy exceptions in an ADR — avoid cluster-wide `exclude` blocks without review
- Pair Kyverno with Binary Authorization for defense in depth (image signature + admission policy)

## Security notes

- Kyverno admission webhooks are a critical control plane component — restrict who can modify `ClusterPolicy` resources (RBAC)
- Policy changes should go through PR review like application code
- `block-plain-secrets` prevents credential leakage via Git-managed Secret manifests
- NetworkPolicies reduce lateral movement if a pod is compromised
- Audit Kyverno policy reports: `kubectl get policyreport -A`

## Next step

→ [Online Boutique deploy](12-boutique-deploy.md)
