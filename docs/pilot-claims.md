# What this pilot claims

For anyone defending this repository in a DevOps or SRE interview. Closed pilot: GCP was torn down after topics 01–16 (including Phase 8 teardown). Nothing here requires a live cluster to read. Screenshots: [`evidence/`](evidence/README.md).

GitHub Actions builds, scans, and signs images. Git stores digest pins. Argo CD reconciles. Cloud Monitoring holds the browse and checkout SLOs; burn alerts go to PagerDuty with runbook links. The pilot proved that path once, then the cloud resources were removed.

## Operated, then torn down (topics 01–16)

- Terraform foundation: VPC, NAT, private-node GKE, Cloud DNS, ingress TLS, WIF, Artifact Registry, Binary Authorization
- Argo CD (manual sync), ESO + Secret Manager, Kyverno Enforce, NetworkPolicy manifests
- Digest-only Boutique Helm in the `boutique` namespace; storefront and Argo CD over HTTPS when live
- Browse and checkout availability SLOs; burn-rate alerts with runbook URLs; PagerDuty test path
- Cloud Armor on the storefront (console path); one executed game day; ordered teardown

## Limits inside the operated path

These are deliberate pilot choices. Point at the file in an interview.

| Limit                                                                                              | Where to point                                                                                 |
| -------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Public Kubernetes API; no master authorized networks                                               | `terraform/modules/gke` · [`../SECURITY.md`](../SECURITY.md)                                   |
| Broad node OAuth scope (`cloud-platform`)                                                          | `terraform/modules/gke`                                                                        |
| Project Binary Authorization default is allow plus dry-run; only this cluster requires attestation | Binary Authorization module / Console · [`security/supply-chain.md`](security/supply-chain.md) |
| `redis-cart` was not attested; game-day restore hit a Binary Authorization deny                    | [`sre/game-days/`](sre/game-days/README.md) · `sre/postmortems/`                               |
| Cosign private key lives in GitHub secrets (long-lived)                                            | [`.github/workflows/`](../.github/workflows/README.md) · [`../SECURITY.md`](../SECURITY.md)    |
| Storefront Cloud Armor is console-only; Terraform Armor is optional for Argo CD                    | [`setup/15-cloud-armor.md`](setup/15-cloud-armor.md)                                           |
| NetworkPolicy may not be enforced by the CNI (no Dataplane V2 or Calico pin)                       | `terraform/modules/gke` · [`../SECURITY.md`](../SECURITY.md)                                   |

## Sentences to retire

- “This is production-ready.” It is a **production pilot** on one cluster. Say so first.
- “Reliability stops at deploy.” The lived story is reliability **after deployment** — SLOs, burn alerts, PagerDuty, runbooks.
- “CI syncs the cluster.” CI opens digest PRs. Operators sync Argo by hand.
- “Binary Authorization and Kyverno closed every gap.” See the limits table — especially unsigned `redis-cart` and NetworkPolicy enforcement.
- “The API is private because the nodes are private.” Nodes are private; the control plane endpoint is public.

## Related

- Evidence gallery: [`evidence/README.md`](evidence/README.md)
- Lessons learned: [`lessons-learned.md`](lessons-learned.md)
- Architecture summary: [`../ARCHITECTURE.md`](../ARCHITECTURE.md)
- Threat model: [`security/threat-model.md`](security/threat-model.md)
- CI contract: [`ci.md`](ci.md)
- Rollback: [`operations/rollback.md`](operations/rollback.md)
- Setup index: [`setup/README.md`](setup/README.md) (topics 01–16)
- Charter and checklist: [`../PROJECT.md`](../PROJECT.md)
