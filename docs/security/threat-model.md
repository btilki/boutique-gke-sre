# Threat model — boutique-gke-sre

## Purpose

Document trust boundaries and primary threats for the single-cluster Online Boutique reference platform.

## Trust zones

| Zone                    | Trust level      | Entry points                            |
| ----------------------- | ---------------- | --------------------------------------- |
| Internet                | Untrusted        | HTTPS to boutique and argocd hostnames  |
| Edge (Cloud Armor + LB) | Semi-trusted     | TLS termination, WAF                    |
| Cluster edge (Ingress)  | Trusted platform | Host-based routing                      |
| `boutique` namespace    | App trust        | NetworkPolicy-segmented microservices   |
| Platform namespaces     | Elevated         | Argo CD, Kyverno, ESO — restricted RBAC |
| GCP control plane       | Cloud trust      | Workload Identity scoped per K8s SA     |
| CI (GitHub Actions)     | Automation trust | WIF-bound; repo/ref conditions          |

## Threat catalog

The mitigation column is the intended control. Residual gaps are listed in the next section.

| Threat                         | Mitigation                                            |
| ------------------------------ | ----------------------------------------------------- |
| Stolen GCP SA keys in GitHub   | WIF only; gitleaks; no JSON keys                      |
| Secrets in Git                 | ESO + Secret Manager; Kyverno blocks plain Secrets    |
| Malicious container image      | Trivy scan; cosign; Binary Authorization; digest-only |
| Lateral movement in cluster    | NetworkPolicy default-deny                            |
| DDoS / abuse at edge           | Cloud Armor rate limits and OWASP CRS                 |
| Unauthorized deploy            | Manual Argo sync; PR review; Kyverno                  |
| Data exfil via compromised pod | Egress NetworkPolicy; least-privilege WI              |

## Residual risks

These are in scope and not fully closed. Details and file pointers: [SECURITY.md](../../SECURITY.md).

| Risk                              | What is true in this repo                                                                                                                               |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Public Kubernetes API             | `enable_private_endpoint = false`. No master authorized networks.                                                                                       |
| Broad node identity               | Node OAuth scope is `cloud-platform`.                                                                                                                   |
| Attestation is cluster-scoped     | Project Binary Authorization default is allow plus dry-run. Only this cluster requires an attestation.                                                  |
| Unsigned `redis-cart` on recreate | The 2026-07-04 game day hit this. Postmortem actions are still open. Cosign uses a long-lived GitHub secret.                                            |
| Partial edge WAF                  | Storefront Armor is a console procedure (topic 15): SQLi, XSS, and a rate limit. Terraform Armor is the Argo CD policy, gated by `enable_argocd_armor`. |
| NetworkPolicy may not be enforced | The GKE module sets neither Dataplane V2 nor the Calico addon.                                                                                          |

## Out of scope

- Physical security of GCP data centers (GCP shared responsibility)
- GitHub org-wide compromise (document as residual risk)

## Further reading

- [Architecture §9 — Security boundaries](../architecture/overview.md#9-security-boundaries)
- [ADR 002 — WIF over SA keys](../adr/002-wif-over-sa-keys.md)
