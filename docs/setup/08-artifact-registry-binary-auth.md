# Artifact Registry and Binary Authorization

## Goal

A regional Docker **Artifact Registry** repository in `europe-west1` stores Online Boutique images (digest-only promotion). **Binary Authorization** enforces that only cosign-attested images from that registry deploy to GKE. An attestor trusts signatures produced by the CI pipeline (topic 07 WIF). Local and CI pushes target `europe-west1-docker.pkg.dev/boutique-gke/boutique`.

## Why this step is required

Production deploys require immutable, scanned, and signed artifacts. Artifact Registry is the single source of truth for container images. Binary Authorization is the admission-control gate at GKE deploy time — unsigned or un attested images are rejected before pods run. Together with Trivy (CI), cosign (CI), and Kyverno digest policies (topic 11), this closes the supply-chain loop.

## Prerequisites

- Prior guide: [07 — GitHub WIF](07-github-wif.md) — CI can authenticate to GCP without JSON keys
- Tools: `gcloud`, Terraform ≥ 1.5, `cosign` (optional local test), `docker` or `crane`
- Access: `roles/artifactregistry.admin`, `roles/binaryauthorization.admin` on `boutique-gke`
- GKE cluster `boutique-gke` running (topic 04)
- Terraform modules wired in `terraform/environments/boutique/main.tf`: `artifact-registry`, `binary-authorization` (requires `cosign_public_key_pem` in `terraform.tfvars` for Binary Auth)

## Commands

### Part A — Artifact Registry (Alternative — GCP Console UI)

1. Open [Google Cloud Console](https://console.cloud.google.com/) → select project **`boutique-gke`**.
2. Navigate **Artifacts** → **Artifact Registry** (or search “Artifact Registry”).
3. Click **+ Create repository**.
4. **Name:** `boutique`
5. **Format:** Docker
6. **Mode:** Standard
7. **Location type:** Region
8. **Region:** `europe-west1`
9. **Description:** `Online Boutique images — digest-only promotion`
10. **Encryption:** Google-managed key (default)
11. **Immutable image tags:** Optional — enable if you want tag immutability (digests are always immutable)
12. Click **Create**
13. On the repository page, copy the **Repository path**:
    ```
    europe-west1-docker.pkg.dev/boutique-gke/boutique
    ```

**Cleanup policy (Console — recommended):**

1. Open repository **`boutique`** → **Edit repository** or **Cleanup policies**
2. Add rule: delete **untagged** images older than **30** days
3. Save

### Part B — Artifact Registry (Terraform — recommended)

`module "artifact_registry"` is wired in `terraform/environments/boutique/main.tf`. IAM for CI push and node pull is included in the module — skip Part C if you use this path.

```bash
gcloud config set project boutique-gke
cd terraform/environments/boutique
terraform init
terraform plan -target=module.artifact_registry -out=tfplan
terraform apply tfplan
terraform output artifact_registry_repository
```

Example module block (as in `main.tf`):

```hcl
module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id               = var.project_id
  location                 = var.region
  repository_id            = "boutique"
  description              = "Online Boutique images — digest-only promotion"
  ci_service_account_email = module.wif.ci_service_account_email
}
```

### Part C — Grant CI service account push access (Alternative — Console or manual)

**Skip this part** if you applied `module.artifact_registry` via Terraform — the module grants `artifactregistry.writer` (CI SA) and `artifactregistry.reader` (default Compute SA for node pulls).

Replace `github-ci@boutique-gke.iam.gserviceaccount.com` if your CI SA name differs:

```bash
gcloud artifacts repositories add-iam-policy-binding boutique \
  --location=europe-west1 \
  --project=boutique-gke \
  --member="serviceAccount:github-ci@boutique-gke.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

Grant GKE node / Workload Identity pull access (example for default node SA — adjust per your module):

```bash
PROJECT_NUMBER="$(gcloud projects describe boutique-gke --format='value(projectNumber)')"
gcloud artifacts repositories add-iam-policy-binding boutique \
  --location=europe-west1 \
  --project=boutique-gke \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

### Part D — Binary Authorization (Alternative — GCP Console UI)

1. Console → **Security** → **Binary Authorization** (search “Binary Authorization”).
2. If prompted, click **Enable Binary Authorization API** / **Get started**.
3. **Policy** tab → edit **Kubernetes Engine policy** (project default).
4. Set **Policy mode** to **Enforce** (use **Dry run** initially if you want shadow mode during bootstrap).
5. Under **Rules** → **Add rule** (or edit default):
   - **Rule type:** Allow
   - **Pod specification:** Require attestations
   - **Attestors:** (create below, then attach)
   - **Scope:** Cluster `boutique-gke` in `europe-west1` when UI offers cluster scope; otherwise project-wide for single-cluster reference
6. Click **Attestors** in left nav → **Create attestor**.
7. **Name:** `boutique-cosign-attestor`
8. **Description:** `Trust cosign signatures from CI pipeline`
9. **Public key (manual):** Paste cosign **public** key PEM from your CI signing setup (generate with `cosign generate-key-pair` in a secure environment — store private key in GitHub Secrets as `COSIGN_PRIVATE_KEY`, never in Git).
10. **Signature algorithm:** ECDSA P-256 (default from `cosign generate-key-pair`) — or match your cosign key type if you used non-default options
11. Click **Create**
12. Return to **Policy** → attach attestor `boutique-cosign-attestor` to the admission rule.
13. **Save** policy.

**Dry-run validation first (recommended):**

1. Set policy to **Dry run** for 24h
2. Deploy a test pod — check **Binary Authorization** logs in Cloud Logging
3. Switch to **Enforce** before topic 12 production Boutique deploy

### Part E — Binary Authorization (Terraform — recommended)

**Before apply:** generate a cosign key pair (Part F) and add `cosign_public_key_pem` to `terraform/environments/boutique/terraform.tfvars` (see `terraform.tfvars.example`). Binary Authorization is created only when `cosign_public_key_pem` is non-empty.

```bash
cd terraform/environments/boutique
terraform plan \
  -target='module.binary_authorization[0]' \
  -target=module.gke \
  -out=tfplan
terraform apply tfplan
terraform output binary_authorization_attestor
terraform output binary_authorization_enforcement_mode
```

> **zsh:** Quote the `binary_authorization[0]` target — unquoted `[0]` is treated as a glob and fails with `no matches found`.

Example module block (as in `main.tf`):

```hcl
module "binary_authorization" {
  count  = local.binary_authorization_enabled ? 1 : 0
  source = "../../modules/binary-authorization"

  project_id                 = var.project_id
  cluster_name               = var.cluster_name
  location                   = var.region
  cosign_public_key_pem      = var.cosign_public_key_pem
  enforcement_mode           = var.binary_authorization_enforcement_mode
  cosign_signature_algorithm = "ECDSA_P256_SHA256"

  depends_on = [module.project_apis, module.gke]
}
```

### Part F — cosign attestor overview (how pieces connect)

```
GitHub Actions (WIF → CI SA)
  → docker build
  → Trivy scan (fail on critical/high)
  → push europe-west1-docker.pkg.dev/boutique-gke/boutique/SERVICE:TAG
  → cosign sign --key env://COSIGN_PRIVATE_KEY IMAGE_DIGEST
  → cosign attest --key env://COSIGN_PRIVATE_KEY --predicate-type slsaprovenance IMAGE_DIGEST
       ↓
Binary Authorization attestor (public key in GCP)
  → On pod admit: image digest must have valid signature from trusted attestor
       ↓
GKE schedules pod (or rejects if unsigned)
```

Key concepts:

| Term            | Meaning                                                                                  |
| --------------- | ---------------------------------------------------------------------------------------- |
| **Attestor**    | GCP resource holding trusted cosign **public** keys                                      |
| **Attestation** | Cryptographic statement that an image met a policy (signature + optional SLSA predicate) |
| **Note**        | Container Analysis note linking attestations to images in AR                             |
| **Policy**      | Which images require which attestors at deploy time                                      |

Generate cosign key pair (run locally in a secure session — **do not commit private key**):

```bash
cosign generate-key-pair
```

This creates `cosign.key` (private — GitHub Secret only) and `cosign.pub` (public — Terraform or Console attestor).

### Part G — Test repository access (authenticated)

After WIF or `gcloud auth application-default login`:

```bash
gcloud auth configure-docker europe-west1-docker.pkg.dev --quiet
docker pull hello-world:latest
docker tag hello-world:latest europe-west1-docker.pkg.dev/boutique-gke/boutique/hello-world:test
docker push europe-west1-docker.pkg.dev/boutique-gke/boutique/hello-world:test
gcloud artifacts docker images list europe-west1-docker.pkg.dev/boutique-gke/boutique
```

Sign test image (optional — requires `cosign.key`):

```bash
IMAGE="europe-west1-docker.pkg.dev/boutique-gke/boutique/hello-world:test"
DIGEST="$(gcloud artifacts docker images describe "${IMAGE}" --format='value(image_summary.digest)')"
cosign sign --key cosign.key "${IMAGE}@${DIGEST}"
cosign verify --key cosign.pub "${IMAGE}@${DIGEST}"
```

## Expected output

**Artifact Registry create (Console):** Repository `boutique` in `europe-west1` with path `europe-west1-docker.pkg.dev/boutique-gke/boutique`.

**`gcloud artifacts repositories describe boutique`:**

```yaml
name: projects/boutique-gke/locations/europe-west1/repositories/boutique
format: DOCKER
```

**`docker push`:**

```
latest: digest: sha256:abc123... size: 1234
```

**`gcloud artifacts docker images list`:**

```
IMAGE                                                          DIGEST
europe-west1-docker.pkg.dev/boutique-gke/boutique/hello-world  sha256:abc123...
```

**Binary Authorization policy:** `ENFORCED_BLOCK_AND_AUDIT_LOG` (or `DRYRUN_AUDIT_LOG_ONLY` during bootstrap) with attestor `boutique-cosign-attestor` attached to cluster `europe-west1.boutique-gke`.

**`cosign verify`:**

```
Verification for europe-west1-docker.pkg.dev/boutique-gke/boutique/hello-world@sha256:abc123...
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
```

## Validation

```bash
gcloud artifacts repositories describe boutique \
  --location=europe-west1 \
  --project=boutique-gke

gcloud artifacts docker images list \
  europe-west1-docker.pkg.dev/boutique-gke/boutique \
  --include-tags

gcloud container binauthz policy export \
  --project=boutique-gke

gcloud container binauthz attestors list \
  --project=boutique-gke
```

Expected:

- Repository `boutique` exists in `europe-west1`
- Policy export shows attestor reference and `clusterAdmissionRules` or global admission rule for GKE
- CI workflow (topic 07) can push without JSON keys when AR IAM is correct

## Common problems

| Symptom                                                              | Cause                                    | Fix                                                                               |
| -------------------------------------------------------------------- | ---------------------------------------- | --------------------------------------------------------------------------------- |
| `denied: Permission "artifactregistry.repositories.uploadArtifacts"` | CI SA missing writer                     | Re-apply `module.artifact_registry` or Part C IAM binding                         |
| `ImagePullBackOff` on cluster                                        | Nodes cannot pull from AR                | Re-apply `module.artifact_registry` or grant `artifactregistry.reader` to node SA |
| Pod denied by Binary Authorization                                   | Unsigned image or enforce without attest | Sign with cosign in CI; or use dry-run until pipeline signs                       |
| `attestor not found`                                                 | Name mismatch in policy vs attestor      | Align names in Console and Terraform                                              |
| cosign verify fails                                                  | Wrong key or tag used instead of digest  | Always reference `@sha256:...` digest in GitOps                                   |
| `zsh: no matches found: -target=module.binary_authorization[0]`      | Unquoted `[0]` glob in zsh               | Quote target: `-target='module.binary_authorization[0]'`                          |
| Binary Authorization module not created                              | Empty `cosign_public_key_pem` in tfvars  | Add public key PEM from `cosign.pub` to `terraform.tfvars`                        |

## Recovery

**Disable enforcement temporarily (incident only):**

```bash
gcloud container binauthz policy export > /tmp/binauth-policy.yaml
# Edit globalPolicyEvaluationMode or per-cluster rule to DISABLE / dry-run
gcloud container binauthz policy import /tmp/binauth-policy.yaml \
  --project=boutique-gke
```

Revert to **Enforce** after fixing signing pipeline.

**Delete test image:**

```bash
gcloud artifacts docker images delete \
  europe-west1-docker.pkg.dev/boutique-gke/boutique/hello-world:test \
  --delete-tags --quiet
```

**Terraform destroy AR (teardown only):**

```bash
cd terraform/environments/boutique
terraform destroy -target='module.binary_authorization[0]'
terraform destroy -target=module.artifact_registry
```

## Best practices

- Reference images by **digest** in GitOps (`image@sha256:...`) — tags are human hints only
- Enable AR cleanup for untagged manifests to control cost
- Start Binary Authorization in **dry run** (`DRYRUN_AUDIT_LOG_ONLY`), then set `binary_authorization_enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"` before topic 12
- Store cosign private key in GitHub Encrypted Secrets; public key in Terraform or Console attestor
- Pair with Trivy CI gate (fail critical/high) before push
- One repository per application family; separate dev/prod only if you add environments later

## Security notes

- Artifact Registry is private by default — no anonymous pulls
- Binary Authorization is the last line of defense if CI or Git is compromised but signing keys are intact
- Restrict `artifactregistry.admin` and `binaryauthorization.admin` to platform team
- Audit AR push and Binary Auth deny events in Cloud Logging
- Never commit `cosign.key`, SA JSON, or registry passwords to Git (gitleaks enforces)
- See [supply-chain.md](../security/supply-chain.md)

## Next step

→ [09 — Argo CD bootstrap](09-argocd-bootstrap.md)

**Phase 4 gate:** Topics 09–11 (Argo CD, ESO, Kyverno) must complete before treating the cluster as production-ready.
