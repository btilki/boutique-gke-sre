# Architecture

Full design: [docs/architecture/overview.md](docs/architecture/overview.md) (16 sections). Folder nav: [docs/architecture/README.md](docs/architecture/README.md).

This is a **closed production reference**: topics 01–16 ran end to end, then Phase 8 teardown removed the GCP resources. There is no live cluster or public DNS from that run. Rebuild via [docs/setup/](docs/setup/README.md).

**Shape:** one private-node regional GKE cluster (public Kubernetes API) in project `boutique-gke`. Git is the deploy source of truth; operators sync Argo CD by hand. The main security tradeoff kept for the closed run is the public API endpoint — nodes are private; the control plane is not.

## Stack flow

```
Git → GitHub Actions (WIF on supply-chain) → Artifact Registry → Argo CD → GKE (private-node, public API)
  → HTTPS (Cloud Armor, TLS) → OTel → Cloud Monitoring → PagerDuty
```

## Key decisions

| Topic     | Choice                                                                                                                 |
| --------- | ---------------------------------------------------------------------------------------------------------------------- |
| Isolation | One cluster; private-node; public API; namespaces `boutique`, `argocd`, `observability`, `kyverno`, `external-secrets` |
| Deploy    | GitOps; manual Argo CD sync; digest-only images                                                                        |
| Security  | WIF (supply-chain), ESO, Kyverno, NetworkPolicy, Binary Authorization, Cloud Armor                                     |
| SRE       | Browse/checkout availability SLOs; burn alerts; runbooks; Game day 03 executed (alert path not verified)               |

## Diagrams

- [assets/diagrams/architecture.mmd](assets/diagrams/architecture.mmd)
- [assets/diagrams/network-flow.mmd](assets/diagrams/network-flow.mmd)
- [assets/diagrams/deployment-pipeline.mmd](assets/diagrams/deployment-pipeline.mmd)

## ADRs

- [001 — Single cluster](docs/adr/001-single-cluster.md)
- [002 — WIF over SA keys](docs/adr/002-wif-over-sa-keys.md)
- [003 — Manual Argo CD sync](docs/adr/003-manual-argocd-sync.md)

## Related

- [docs/ci.md](docs/ci.md) · [docs/operations/rollback.md](docs/operations/rollback.md)
- [docs/reference-claims.md](docs/reference-claims.md)
- [docs/setup/README.md](docs/setup/README.md) (topics 01–16)
