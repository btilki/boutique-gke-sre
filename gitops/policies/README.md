# Platform policies

Kyverno admission policies and Kubernetes NetworkPolicies for production baseline.

## Purpose

Centralize security and compliance policies reconciled by Argo CD before application workloads deploy. Satisfies the Phase 4 production gate.

## Inputs

| Input            | Path                | Description                        |
| ---------------- | ------------------- | ---------------------------------- |
| Kyverno policies | `kyverno/`          | Five minimum ClusterPolicies       |
| Network policies | `network-policies/` | Default-deny + boutique allow-list |

## Outputs

| Output                | Description                                |
| --------------------- | ------------------------------------------ |
| Admission enforcement | Digest, probes, resources, labels, secrets |
| Network segmentation  | Default-deny with explicit allows          |

## Dependencies

- Phase 4: Kyverno installed on cluster
- Argo CD: `../apps/argocd-apps/policies-application.yaml`
- ESO: `../bootstrap/external-secrets/` (for block-plain-secrets)

## Usage

Synced via Argo CD `policies` Application (manual sync). Apply order:

```text
1. kyverno/           — ClusterPolicies
2. network-policies/  — after namespaces exist with tier labels
```

Policy tests: `tests/kyverno/`. Troubleshooting: `docs/troubleshooting/kyverno-denials.md`.
