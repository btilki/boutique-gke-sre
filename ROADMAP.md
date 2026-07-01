# Roadmap

Implementation status for **boutique-gke-sre**. Detail: [docs/implementation/roadmap.md](docs/implementation/roadmap.md).

| Phase | Focus | Size | Status |
|-------|-------|------|--------|
| **1** | Repo scaffold + Terraform foundation | S | 🔄 In progress |
| **2** | GKE + DNS + ingress + TLS | L | ⬜ |
| **3** | WIF + Artifact Registry + CI | M | ⬜ |
| **4** | Argo CD + policies + ESO + NetworkPolicy (**gate**) | L | ⬜ |
| **5** | Online Boutique deploy | M | ⬜ |
| **6** | Observability + SLOs | L | ⬜ |
| **7** | SRE ops + game day | M | ⬜ |
| **8** | Teardown + backup/restore | M | ⬜ |

## Dependency graph

```
Phase 1 → 2 → 3 → 4 (gate) → 5 → 6 → 7 → 8
```

## Current phase

**Phase 1** — You are here. After validation and commit, proceed to Phase 2.

Setup guides: [docs/setup/README.md](docs/setup/README.md)
