# Implementation roadmap

Phased delivery for **boutique-gke-sre** — one phase per session: validate → commit → next.

**Architecture:** Canonical design published in [architecture/overview.md](../architecture/overview.md) (16 sections) with diagram sources in `diagrams/`.

## Phase status

| Phase | Focus                                    | Size | Status      | Setup topics |
| ----- | ---------------------------------------- | ---- | ----------- | ------------ |
| **1** | Repo scaffold + Terraform foundation     | S    | ✅ Complete | 01–03        |
| **2** | GKE + DNS + ingress + TLS                | L    | ✅ Complete | 04–06        |
| **3** | WIF + Artifact Registry + CI             | M    | ✅ Complete | 07–08        |
| **4** | Argo CD + policies + ESO + NetworkPolicy | L    | ✅ Complete | 09–11        |
| **5** | Online Boutique deploy                   | M    | ✅ Complete | 12           |
| **6** | Observability + SLOs                     | L    | ✅ Complete | 13           |
| **7** | SRE ops + smoke validation               | M    | ✅ Complete | 14–16        |
| **8** | Teardown + backup/restore                | M    | 🔄 Current  | teardown doc |

## Phase 1 — complete

### Objectives

Establish repository structure, tooling, Terraform APIs module, VPC/NAT networking.

### Tasks

- [x] Folder tree and root documentation
- [x] `project-apis` and `networking` Terraform modules
- [x] `terraform/environments/boutique` root module
- [x] Setup guides 01–03
- [x] User: execute guides 01–03 and `terraform apply`
- [x] User: `make validate` and commit

### Validation

```bash
make validate
cd terraform/environments/boutique && terraform plan \
  -target=module.project_apis \
  -target=module.networking   # expect no changes after Phase 1 apply
gcloud storage ls gs://boutique-gke-tfstate/boutique/
gcloud compute networks describe boutique-vpc --project=boutique-gke
gcloud compute networks subnets describe boutique-gke-subnet \
  --region=europe-west1 --project=boutique-gke
gcloud compute routers nats describe boutique-nat \
  --router=boutique-router --region=europe-west1 --project=boutique-gke
```

### Outputs

- Repo scaffold on disk
- GCS state bucket (user-created)
- VPC + NAT in GCP

**Optional post-review apply:** If the repo gained `sts.googleapis.com` or `time_sleep.wait_for_apis` after your first apply, run a small targeted plan/apply for `module.project_apis` and `time_sleep.wait_for_apis` before Phase 2.

## Phases 2–7 — complete

Bootstrap through setup topic 16 (smoke validation) is complete. See [16-smoke-validation.md](../setup/16-smoke-validation.md) and post-bootstrap [edge-hardening.md](../security/edge-hardening.md).

**Next:** Phase 8 — teardown and backup/restore validation ([teardown.md](../teardown.md)).

## Phase 2 — complete (historical)

## Dependency graph

```
Phase 1 → 2 → 3 → 4 (gate) → 5 → 6 → 7 → 8
```

## Critical gate

**Do not skip Phase 4** before treating the cluster as production-ready.

## Phase notes

Detailed notes per phase: [phases/](phases/)
