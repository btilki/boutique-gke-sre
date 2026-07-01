# Kyverno policy test example

Negative test manifest for `require-digest` policy.

## Purpose

Show a pod spec that **must be denied** because it uses a tag (`:latest`) instead of an image digest.

## Files

| File | Expected result |
|------|-----------------|
| `bad-latest-pod.yaml` | Deny by `require-digest` policy |

## Usage

```bash
# Kyverno CLI (when policy exists in gitops/policies/kyverno/)
kyverno apply gitops/policies/kyverno/require-digest.yaml \
  --resource bad-latest-pod.yaml

# Or via tests/kyverno/require-digest-test.yaml in CI
```

## Further reading

- [examples/README.md](../README.md)
- [tests/kyverno/require-digest-test.yaml](../../tests/kyverno/require-digest-test.yaml)
