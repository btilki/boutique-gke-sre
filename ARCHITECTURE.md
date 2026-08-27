# Architecture

Executive summary for **boutique-gke-sre**. Full design: **[docs/architecture/overview.md](docs/architecture/overview.md)** (16 sections).

## Stack flow

```
Git → GitHub Actions (WIF) → Artifact Registry → Argo CD → Private GKE
  → HTTPS (Cloud Armor, TLS) → OTel → Cloud Monitoring → PagerDuty
```

## Key decisions

| Topic     | Choice                                                                                       |
| --------- | -------------------------------------------------------------------------------------------- |
| Isolation | One cluster; namespaces `boutique`, `argocd`, `observability`, `kyverno`, `external-secrets` |
| Deploy    | GitOps; manual Argo CD sync; digest-only images                                              |
| Security  | WIF, ESO, Kyverno, NetworkPolicy, Binary Authorization, Cloud Armor                          |
| SRE       | Browse 99.9%, checkout 99.95%; burn alerts; runbooks per alert                               |

## Diagrams

- [assets/diagrams/architecture.mmd](assets/diagrams/architecture.mmd)
- [assets/diagrams/network-flow.mmd](assets/diagrams/network-flow.mmd)
- [assets/diagrams/deployment-pipeline.mmd](assets/diagrams/deployment-pipeline.mmd)

## ADRs

- [001 — Single cluster](docs/adr/001-single-cluster.md)
- [002 — WIF over SA keys](docs/adr/002-wif-over-sa-keys.md)
- [003 — Manual Argo CD sync](docs/adr/003-manual-argocd-sync.md)
