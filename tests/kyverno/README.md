# Kyverno policy tests

Run with Kyverno CLI (Phase 4+):

```bash
kyverno test tests/kyverno/
# or: make kyverno-test
```

The CLI looks for `kyverno-test.yaml` by default (Kyverno 1.6+). Fixtures live in `examples/kyverno-policy-test/` and cover `require-digest`, `require-probes`, and `require-resources`.
