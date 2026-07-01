# Troubleshooting

Symptom-oriented guides for boutique-gke-sre production issues.

## Purpose

Fast path from observable failure to documented fix without duplicating full runbooks.

## When to use

- Deploy or sync problems
- Policy admission failures
- Before opening SEV incidents

## Guides

| Guide | Symptoms |
|-------|----------|
| [argocd-sync-failures.md](argocd-sync-failures.md) | Argo CD OutOfSync, sync errors, degraded apps |
| [kyverno-denials.md](kyverno-denials.md) | Resource blocked by Kyverno admission |

## Public URLs

- Storefront: https://boutique.biroltilki.art
- Argo CD: https://argocd.boutique.biroltilki.art

## Escalation

If user-facing outage > 15 min, follow [sre/oncall/escalation.md](../sre/oncall/escalation.md) and matching runbook.

## Further reading

- [sre/runbooks/README.md](../sre/runbooks/README.md)
- [operations/README.md](../operations/README.md)
