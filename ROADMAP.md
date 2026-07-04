# Roadmap

Phased delivery for **boutique-gke-sre** — one phase per session: validate → commit → next.

**Step-by-step guides:** [docs/setup/README.md](docs/setup/README.md) (topics 01–16)

| Phase | Focus                                               | Size | Status         | Setup topics                 |
| ----- | --------------------------------------------------- | ---- | -------------- | ---------------------------- |
| **1** | Repo scaffold + Terraform foundation                | S    | ✅ Complete    | 01–03                        |
| **2** | GKE + DNS + ingress + TLS                           | L    | ✅ Complete    | 04–06                        |
| **3** | WIF + Artifact Registry + CI                        | M    | ✅ Complete    | 07–08                        |
| **4** | Argo CD + policies + ESO + NetworkPolicy (**gate**) | L    | ✅ Complete    | 09–11                        |
| **5** | Online Boutique deploy                              | M    | ✅ Complete    | 12                           |
| **6** | Observability + SLOs                                | L    | ✅ Complete    | 13                           |
| **7** | SRE ops + smoke validation                          | M    | ✅ Complete    | 14–16                        |
| **8** | Teardown + backup/restore                           | M    | 🔄 In progress | [teardown](docs/teardown.md) |

## Dependency graph

```
Phase 1 → 2 → 3 → 4 (gate) → 5 → 6 → 7 → 8
```

## Critical gate

**Do not skip Phase 4** before treating the cluster as production-ready.

## Current phase

**Phase 8** — Teardown and backup/restore validation. See [docs/teardown.md](docs/teardown.md).

Portfolio review: [PORTFOLIO.md](PORTFOLIO.md)
