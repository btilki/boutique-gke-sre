# Kyverno policy denials

## Purpose

Resolve admission failures when Kyverno blocks Kubernetes resources during apply or Argo CD sync.

## When to use

- `admission webhook denied` errors
- CI Kyverno tests failing
- New manifest rejected after PR merge

## Prerequisites

- Policies in `gitops/policies/kyverno/`
- `kubectl` access to read PolicyReports
- Example deny manifest: [examples/kyverno-policy-test/](../../examples/kyverno-policy-test/)

## Architecture

Kyverno validates on API server admission. Minimum policies: digest-only images, probes, resources, NetworkPolicy labels, block plain Secrets.

## Step-by-step implementation

1. Capture denial message from `kubectl apply` or Argo CD sync log
2. Map to policy name (e.g. `require-digest`, `block-plain-secrets`)
3. Inspect resource against policy README in `gitops/policies/kyverno/`
4. Fix manifest in Git (digest pin, probes, labels, ExternalSecret)
5. Re-run policy test: `kyverno test tests/kyverno/`
6. Merge fix → manual Argo CD sync

## Validation

```bash
kubectl get policyreport -A
kyverno apply gitops/policies/kyverno/require-digest.yaml \
  --resource examples/kyverno-policy-test/bad-latest-pod.yaml
```

Expected: bad example fails; production manifests pass.

## Troubleshooting

| Symptom              | Cause                 | Fix                                     |
| -------------------- | --------------------- | --------------------------------------- |
| `:latest` rejected   | require-digest        | Pin `@sha256:...` in values-images.yaml |
| Missing probes       | require-probes        | Add liveness/readiness HTTP probes      |
| Plain Secret         | block-plain-secrets   | Use ExternalSecret pattern              |
| NetPol label missing | require-netpol-labels | Add compliance label                    |

## Common mistakes

- Bypassing with `kyverno.io/ignore` annotations in production
- Pushing tags instead of digests from CI

## Best practices

- Run Kyverno tests in CI before merge
- Keep deny examples in `examples/kyverno-policy-test/`

## Production considerations

- Policies enforce production bar; exceptions need ADR
- Policy changes sync via `policies` Argo CD Application

## Security considerations

- Block plain Secrets forces Secret Manager + ESO
- Digest-only reduces supply-chain drift

## Further reading

- [setup/11-kyverno-policies.md](../setup/11-kyverno-policies.md)
- [tests/kyverno/kyverno-test.yaml](../../tests/kyverno/kyverno-test.yaml)
