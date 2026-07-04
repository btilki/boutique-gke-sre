# Roadmap

Implementation status for **boutique-gke-sre**. Detail: [docs/implementation/roadmap.md](docs/implementation/roadmap.md).

| Phase | Focus                                               | Size | Status         |
| ----- | --------------------------------------------------- | ---- | -------------- |
| **1** | Repo scaffold + Terraform foundation                | S    | ✅ Complete    |
| **2** | GKE + DNS + ingress + TLS                           | L    | ✅ Complete    |
| **3** | WIF + Artifact Registry + CI                        | M    | ✅ Complete    |
| **4** | Argo CD + policies + ESO + NetworkPolicy (**gate**) | L    | ✅ Complete    |
| **5** | Online Boutique deploy                              | M    | ✅ Complete    |
| **6** | Observability + SLOs                                | L    | ✅ Complete    |
| **7** | SRE ops + smoke validation                          | M    | ✅ Complete    |
| **8** | Teardown + backup/restore                           | M    | 🔄 In progress |

## Dependency graph

```
Phase 1 → 2 → 3 → 4 (gate) → 5 → 6 → 7 → 8
```

## Current phase

**Phase 8** — Teardown and backup/restore validation. See [docs/teardown.md](docs/teardown.md).

Setup guides: [docs/setup/README.md](docs/setup/README.md)
Portfolio review: [PORTFOLIO.md](PORTFOLIO.md)
