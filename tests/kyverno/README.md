# Kyverno policy tests

Run with Kyverno CLI (Phase 4+):

```bash
kyverno test tests/kyverno/
# or: make kyverno-test
```

The CLI looks for `kyverno-test.yaml` by default (Kyverno 1.6+). Fixtures live in `examples/kyverno-policy-test/` and cover all five ClusterPolicies.

Rendered Boutique chart validation:

```bash
./tests/manifest/boutique-kyverno.sh
# or: make boutique-kyverno-test
```
