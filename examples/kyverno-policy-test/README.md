# Kyverno policy test examples

Negative test manifests for Kyverno ClusterPolicies. Each file **must be denied** by at least one policy.

## Purpose

Provide fixtures for `kyverno test tests/kyverno/` and local `kubectl apply --dry-run=server` checks.

## Files

| File                             | Policy              | Rule                                  | Violation                     |
| -------------------------------- | ------------------- | ------------------------------------- | ----------------------------- |
| `bad-latest-pod.yaml`            | `require-digest`    | `reject-latest-tag`, `require-digest` | App container uses `:latest`  |
| `bad-init-latest-pod.yaml`       | `require-digest`    | `reject-latest-tag`, `require-digest` | Init container uses `:latest` |
| `bad-missing-probes-pod.yaml`    | `require-probes`    | `require-liveness-readiness`          | No liveness/readiness probes  |
| `bad-missing-resources-pod.yaml` | `require-resources` | `require-requests-limits`             | No CPU/memory requests/limits |

Digest placeholders (`sha256:000…`) are synthetic — valid for policy syntax tests only.

## Usage

```bash
# Full suite (CI + local)
kyverno test tests/kyverno/

# Single fixture against cluster admission
kubectl apply --dry-run=server -f bad-latest-pod.yaml
```

## Further reading

- [examples/README.md](../README.md)
- [tests/kyverno/kyverno-test.yaml](../../tests/kyverno/kyverno-test.yaml)
- [docs/setup/11-kyverno-policies.md](../../docs/setup/11-kyverno-policies.md)
