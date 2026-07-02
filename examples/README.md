# Examples

Minimal reference configurations for learning and copy-paste. **Not** production deploy paths.

## Purpose

Illustrate ESO, Kyverno testing, and GitHub Actions WIF without embedding secrets or replacing setup guides.

## Layout

| Directory                     | Topic                                   |
| ----------------------------- | --------------------------------------- |
| `external-secret/`            | ExternalSecret → Secret Manager pattern |
| `kyverno-policy-test/`        | Deny-test pod using `:latest`           |
| `wif-github-actions-snippet/` | WIF auth workflow fragment              |

## Conventions

- No real credentials or secret values
- Image references use digest in production; examples may show tags only where testing denial
- Follow [docs/setup/README.md](../docs/setup/README.md) for full implementation

## Further reading

- [CONTRIBUTING.md](../CONTRIBUTING.md)
- [gitops/README.md](../gitops/README.md)
