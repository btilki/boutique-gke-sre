# Tests

Policy and manifest validation for boutique-gke-sre.

## Purpose

Automated gates in CI and local pre-commit. Expanded in Phase 3 (Terraform) and Phase 4 (Kyverno).

## Layout

```
tests/
├── kyverno/
│   └── require-digest-test.yaml   # Kyverno CLI test manifest
├── terraform/
│   └── validate.tftest.hcl        # Terraform test framework scaffold
├── manifest/
│   └── kubeconform.sh             # Schema validation for gitops/ YAML
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
```

## CI integration

- `.github/workflows/ci.yml` — lint, terraform validate, policy tests
- `.github/workflows/terraform-plan.yml` — plan on PR

## Phase coverage

| Phase | Tests |
|-------|-------|
| 1 | `make validate`, terraform fmt/validate |
| 3 | `tests/terraform/validate.tftest.hcl` |
| 4 | `tests/kyverno/`, `examples/kyverno-policy-test/` |
| 6 | Observability manifest kubeconform |

## Further reading

- [CONTRIBUTING.md](../CONTRIBUTING.md)
- [examples/README.md](../examples/README.md)
