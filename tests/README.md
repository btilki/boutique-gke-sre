# Tests

Policy and manifest validation for boutique-gke-sre.

## Purpose

Automated gates in CI and local pre-commit. Expanded in Phase 3 (Terraform) and Phase 4 (Kyverno).

## Layout

```
tests/
├── kyverno/
│   └── kyverno-test.yaml          # Kyverno CLI test manifest (default filename)
├── terraform/
│   └── validate.tftest.hcl        # Terraform test framework scaffold
├── manifest/
│   ├── kubeconform.sh             # Schema validation for gitops/ YAML + rendered Boutique chart
│   ├── boutique-kyverno.sh        # Kyverno apply against rendered Boutique chart
│   └── digest-only.sh             # Fail if values-images.yaml uses floating tags
└── README.md
```

## Usage

```bash
# Terraform validate (root Makefile)
make validate

# Kyverno policy tests (when policies exist)
kyverno test tests/kyverno/

# Manifest schemas
./tests/manifest/kubeconform.sh
./tests/manifest/digest-only.sh
./tests/manifest/boutique-kyverno.sh
```

## CI integration

- `.github/workflows/ci.yml` — `validate` (Terraform), `kyverno` (policy tests + Boutique chart apply), `manifests` (digest-only, kubeconform)
- `.github/workflows/terraform-plan.yml` — plan on PR

## Phase coverage

| Phase | Tests                                                               |
| ----- | ------------------------------------------------------------------- |
| 1     | `make validate`, terraform fmt/validate                             |
| 3     | `tests/terraform/validate.tftest.hcl`                               |
| 4     | `tests/kyverno/`, `examples/kyverno-policy-test/`                   |
| 5     | `digest-only.sh`, `boutique-kyverno.sh`, Boutique chart kubeconform |
| 6     | Observability manifest kubeconform                                  |

## Further reading

- [CONTRIBUTING.md](../CONTRIBUTING.md)
- [examples/README.md](../examples/README.md)
