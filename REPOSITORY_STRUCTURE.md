# Repository structure — boutique-gke-sre

Enterprise layout: **infrastructure** · **platform** · **applications** · **SRE operations** · **cross-cutting**

Full rule: [.cursor/rules/repository-structure.mdc](.cursor/rules/repository-structure.mdc)

## Layer map

| Layer | Paths |
|-------|--------|
| **Infrastructure** | `terraform/` |
| **Platform** | `gitops/bootstrap/`, `gitops/policies/`, `observability/` |
| **Applications** | `gitops/apps/` |
| **SRE operations** | `docs/sre/`, `scripts/game-days/`, `observability/monitoring/` |
| **Cross-cutting** | `.github/`, `tests/`, `scripts/bootstrap|teardown/`, root docs |

## Top-level tree

```
boutique-gke-sre/
├── .github/              # CI/CD, templates, CODEOWNERS
├── terraform/            # GCP IaC (modules + environments/boutique)
├── gitops/               # Argo CD bootstrap, apps, policies
├── observability/        # OTel, Prometheus, Grafana, Cloud Monitoring defs
├── docs/                 # Architecture, setup, SRE, security, operations
├── scripts/              # Bootstrap validation, game-days, teardown
├── examples/             # Reference snippets
├── tests/                # Kyverno, Terraform, manifest validation
├── assets/diagrams/      # Mermaid diagram sources
├── README.md             # Portfolio front page
├── PROJECT.md            # Charter and production bar
├── ARCHITECTURE.md       # Executive architecture index
├── ROADMAP.md            # Phase status
├── CONTRIBUTING.md
├── SECURITY.md
├── Makefile
└── LICENSE
```

## Terraform modules

| Module | Phase | Status |
|--------|-------|--------|
| `project-apis` | 1 | Implemented |
| `networking` | 1 | Implemented |
| `gke` | 2 | Implemented |
| `dns` | 2 | Implemented |
| `ingress-edge` | 2 | Implemented |
| `wif` | 3 | Scaffold |
| `artifact-registry` | 3 | Scaffold |
| `binary-authorization` | 3 | Scaffold |
| `iam` | 3–4 | Scaffold |
| `armor` | 7 | Scaffold |
| `secret-manager` | 4 | Scaffold |
| `monitoring` | 6–7 | Scaffold |
| `backup` | 8 | Scaffold |

Each module includes `README.md` with purpose, inputs, outputs, dependencies, usage.

## GitOps layout

```
gitops/
├── bootstrap/       # Argo CD, ESO, root-app.yaml
├── apps/            # Boutique Helm + Argo Applications
└── policies/        # Kyverno + NetworkPolicy
```

## Extension path

Add `terraform/environments/staging/` and Helm value overlays without restructuring. See ADR [001](docs/adr/001-single-cluster.md).

## Per-directory README rule

Every folder has `README.md` describing purpose, inputs, outputs, dependencies, and usage.
