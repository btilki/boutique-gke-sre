# Setup guides — boutique-gke-sre

Topic-based guides to bootstrap from an empty GCP project to production-ready URLs.

**Target URLs:**

- https://boutique.biroltilki.art
- https://argocd.boutique.biroltilki.art

## Execution order

| # | Topic | Guide | Est. | Phase |
|---|-------|-------|------|-------|
| 1 | GCP project and APIs | [01-gcp-project-apis.md](01-gcp-project-apis.md) | 30 min | 1 |
| 2 | Terraform remote state | [02-terraform-remote-state.md](02-terraform-remote-state.md) | 45 min | 1 |
| 3 | VPC, subnets, Cloud NAT | [03-vpc-nat.md](03-vpc-nat.md) | 1 h | 1 |
| 4 | GKE cluster | [04-gke-cluster.md](04-gke-cluster.md) | 1–2 h | 2 |
| 5 | Cloud DNS + NS delegation | [05-cloud-dns.md](05-cloud-dns.md) | 45 min | 2 |
| 6 | Static IP + TLS | [06-ingress-tls.md](06-ingress-tls.md) | 1 h | 2 |
| 7 | GitHub WIF | [07-github-wif.md](07-github-wif.md) | 1 h | 3 |
| 8 | Artifact Registry + Binary Auth | [08-artifact-registry-binary-auth.md](08-artifact-registry-binary-auth.md) | 1 h | 3 |
| 9 | Argo CD bootstrap | [09-argocd-bootstrap.md](09-argocd-bootstrap.md) | 1 h | 4 **gate** |
| 10 | ESO + Secret Manager | [10-external-secrets.md](10-external-secrets.md) | 45 min | 4 |
| 11 | Kyverno policies | [11-kyverno-policies.md](11-kyverno-policies.md) | 45 min | 4 |
| 12 | Boutique deploy | [12-boutique-deploy.md](12-boutique-deploy.md) | 1 h | 5 |
| 13 | Observability + SLOs | [13-observability-slos.md](13-observability-slos.md) | 2 h | 6 |
| 14 | PagerDuty | [14-pagerduty.md](14-pagerduty.md) | 1 h | 7 |
| 15 | Cloud Armor | [15-cloud-armor.md](15-cloud-armor.md) | 45 min | 7 |
| 16 | Smoke + SRE verification | [16-smoke-validation.md](16-smoke-validation.md) | 1 h | 7–8 |

All **16 guides** use the SETUP-GUIDE format: Goal, Why, Prerequisites, Commands, Expected output, Validation, Common problems, Recovery, Best practices, Security notes, Next step.

**Phase 4 gate:** Topics 09–11 (Argo CD, ESO, Kyverno) must complete before treating the cluster as production-ready or deploying Boutique (topic 12).

## Dependency graph

```
01 → 02 → 03 → 04 → 05 → 06
                ↓
07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15 → 16
```

Topics 7–8 can start after topic 4 completes (parallel with 5–6).

## Terraform phases

| Phase | Topics | Terraform modules applied |
|-------|--------|---------------------------|
| 1 | 01–03 | `project_apis`, `time_sleep` (API propagation), `networking` (use `-target` in topic 03) |
| 2 | 04–06 | `gke`, `ingress_edge`, `dns` |
| 3+ | 07–16 | WIF, AR, Binary Auth via Terraform when modules exist; remainder is GitOps / Console |

## Related docs

- [Bootstrap summary](../bootstrap.md)
- [DNS reference](../dns.md)
- [Teardown](../teardown.md)
- [Implementation roadmap](../implementation/roadmap.md)

## Collaboration

You execute each guide step by step. Confirm completion before moving to the next topic.

After topic 16, see [bootstrap.md](../bootstrap.md) for first deploy, game day, on-call, and teardown next steps.
