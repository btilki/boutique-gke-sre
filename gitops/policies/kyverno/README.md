# Kyverno admission policies

ClusterPolicies enforcing production baseline for workloads on boutique-gke.

## Purpose

Enforce digest-only images, health probes, resource limits, NetworkPolicy labels, and ESO-only secrets before workloads reach the cluster.

## Inputs

| Input         | File                         | Rule                                 |
| ------------- | ---------------------------- | ------------------------------------ |
| Image digests | `require-digest.yaml`        | Reject `:latest`; require `@sha256:` |
| Probes        | `require-probes.yaml`        | Liveness + readiness required        |
| Resources     | `require-resources.yaml`     | CPU/memory requests and limits       |
| NetPol labels | `require-netpol-labels.yaml` | Namespace tier label                 |
| Secrets       | `block-plain-secrets.yaml`   | Block plain `Secret` CRs             |

## Outputs

| Output            | Description                                   |
| ----------------- | --------------------------------------------- |
| Enforced policies | Admission denials for non-compliant manifests |
| Policy reports    | Kyverno background scan results               |

## Dependencies

- Phase 4: Kyverno controller installed on cluster
- ESO bootstrap: `../../bootstrap/external-secrets/`
- Tests: `../../../tests/kyverno/`

## Usage

Synced by Argo CD via `../../apps/argocd-apps/policies-application.yaml`. Validate locally:

```bash
kubectl apply --dry-run=server -f .
```

Policy tests: `make test-kyverno` (when wired in Phase 4).
