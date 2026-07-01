# Threat model — boutique-gke-sre

## Purpose

Document trust boundaries and primary threats for the single-cluster Online Boutique reference platform.

## Trust zones

| Zone | Trust level | Entry points |
|------|-------------|--------------|
| Internet | Untrusted | HTTPS to boutique and argocd hostnames |
| Edge (Cloud Armor + LB) | Semi-trusted | TLS termination, WAF |
| Cluster edge (Ingress) | Trusted platform | Host-based routing |
| `boutique` namespace | App trust | NetworkPolicy-segmented microservices |
| Platform namespaces | Elevated | Argo CD, Kyverno, ESO — restricted RBAC |
| GCP control plane | Cloud trust | Workload Identity scoped per K8s SA |
| CI (GitHub Actions) | Automation trust | WIF-bound; repo/ref conditions |

## Threat catalog

| Threat | Mitigation |
|--------|------------|
| Stolen GCP SA keys in GitHub | WIF only; gitleaks; no JSON keys |
| Secrets in Git | ESO + Secret Manager; Kyverno blocks plain Secrets |
| Malicious container image | Trivy scan; cosign; Binary Authorization; digest-only |
| Lateral movement in cluster | NetworkPolicy default-deny |
| DDoS / abuse at edge | Cloud Armor rate limits and OWASP CRS |
| Unauthorized deploy | Manual Argo sync; PR review; Kyverno |
| Data exfil via compromised pod | Egress NetworkPolicy; least-privilege WI |

## Out of scope

- Physical security of GCP data centers (GCP shared responsibility)
- GitHub org-wide compromise (document as residual risk)

## Further reading

- [Architecture §9 — Security boundaries](../architecture/overview.md#9-security-boundaries)
- [ADR 002 — WIF over SA keys](../adr/002-wif-over-sa-keys.md)
