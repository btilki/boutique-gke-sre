# GitHub Workload Identity Federation (WIF)

## Goal

GitHub Actions in repository `boutique-gke-sre` authenticates to GCP project `boutique-gke` using **Workload Identity Federation (OIDC)** — no downloaded service account JSON keys. A WIF pool and provider trust `token.actions.githubusercontent.com`, a dedicated CI service account receives least-privilege IAM, and workflows use `google-github-actions/auth@v2`.

## Why this step is required

The CI pipeline builds images, pushes to Artifact Registry, runs Trivy, signs with cosign, and updates digest manifests. Long-lived JSON keys in GitHub Secrets are a critical security risk (leak = full SA compromise). WIF issues **short-lived** credentials bound to a specific GitHub repository and ref pattern. This is mandatory for the production supply-chain bar documented in [ADR 002 — WIF over SA keys](../adr/002-wif-over-sa-keys.md).

## Prerequisites

- Prior guide: [04 — GKE cluster](04-gke-cluster.md) — cluster running (topics 05–06 may be in progress)
- Tools: Terraform ≥ 1.5, `gcloud`, GitHub admin access on `boutique-gke-sre`
- Access: `roles/iam.workloadIdentityPoolAdmin`, `roles/iam.serviceAccountAdmin` on `boutique-gke`
- APIs enabled: `iam.googleapis.com`, `iamcredentials.googleapis.com`, `sts.googleapis.com` (from topic 01)
- Terraform module: `terraform/modules/wif` (wired in `terraform/environments/boutique/main.tf`)

## Commands

### Part A — GitHub repository settings (graphical UI)

Configure OIDC and workflow permissions **before** or immediately after Terraform WIF apply.

1. Open your GitHub repository: `https://github.com/<GITHUB_ORG>/boutique-gke-sre`
2. Click **Settings** (repository settings, not account settings).
3. In the left sidebar, expand **Actions** → click **General**.
4. Scroll to **Workflow permissions**:
   - Select **Read and write permissions** (required for CI jobs that open PRs or push digest updates).
   - Check **Allow GitHub Actions to create and approve pull requests** if your pipeline opens manifest PRs.
5. Scroll to **Access** (same page) — leave **Not accessible** or restrict per your org policy; workflows in this repo must run.
6. Still under **Actions** → **General**, find **Workflow permissions** → ensure **Read and write permissions** is saved.
7. In the left sidebar, click **Actions** → **General** (confirm saved), then navigate **Code and automation** → **Actions** → **General** on newer GitHub UI — same settings.
8. For OIDC: no separate “enable OIDC” toggle is required on modern GitHub — granting `id-token: write` in workflow `permissions` (below) enables it per job.
9. Click **Save** if any changes were made.

**Org-level note:** If your organization blocks write permissions, an org owner must allow **Read and write** for this repository under **Organization Settings** → **Actions** → **General** → **Workflow permissions**.

### Part B — Terraform WIF module

Set `github_org` in `terraform/environments/boutique/terraform.tfvars` (copy from `terraform.tfvars.example` if needed):

```hcl
github_org  = "btilki"   # your GitHub username or org
github_repo = "boutique-gke-sre"
```

The `wif` module at `terraform/modules/wif/` is wired in `terraform/environments/boutique/main.tf`:

```hcl
module "wif" {
  source = "../../modules/wif"

  project_id  = var.project_id
  github_org  = var.github_org
  github_repo = var.github_repo
}
```

Plan and apply (target WIF only if you prefer a smaller blast radius):

```bash
gcloud config set project boutique-gke
cd terraform/environments/boutique
terraform init
terraform plan -target=module.wif -out=tfplan
terraform apply tfplan
```

Capture outputs (exact output names follow module `outputs.tf` when implemented):

```bash
terraform output wif_provider_name
terraform output ci_service_account_email
```

Example expected provider resource name format:

```
projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider
```

Verify in GCP Console (optional):

1. **IAM & Admin** → **Workload Identity Federation**
2. Open pool (e.g. `github-pool`) → provider `github-provider`
3. Confirm issuer `https://token.actions.githubusercontent.com`
4. Attribute mapping includes `google.subject` and `attribute.repository`

### Part C — GitHub repository secrets

In GitHub: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret name | Value |
|-------------|-------|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Full provider resource name from `terraform output wif_provider_name` |
| `GCP_SERVICE_ACCOUNT` | CI service account email from `terraform output ci_service_account_email` (e.g. `github-ci@boutique-gke.iam.gserviceaccount.com`) |

**Do not** create `GCP_SA_KEY`, `GOOGLE_CREDENTIALS`, or any JSON key secret.

### Part D — Workflow authentication snippet

Add to `.github/workflows/build-scan-sign.yml` (or use [examples/wif-github-actions-snippet/wif-auth.yml.example](../../examples/wif-github-actions-snippet/wif-auth.yml.example)):

```yaml
permissions:
  contents: read
  id-token: write

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Authenticate to Google Cloud (WIF)
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}

      - name: Set up Cloud SDK
        uses: google-github-actions/setup-gcloud@v2

      - name: Set gcloud project
        run: gcloud config set project boutique-gke

      - name: Verify caller identity
        env:
          EXPECTED_SA: ${{ secrets.GCP_SERVICE_ACCOUNT }}
        run: |
          gcloud auth print-access-token > /dev/null
          ACTIVE="$(gcloud config get-value account 2>/dev/null)"
          echo "Active account: ${ACTIVE}"
          test "${ACTIVE}" = "${EXPECTED_SA}"
```

### Part E — Validate WIF binding (local gcloud — optional dry run)

After Terraform apply, confirm the CI service account allows the GitHub principal set:

```bash
gcloud iam service-accounts get-iam-policy github-ci@boutique-gke.iam.gserviceaccount.com \
  --project=boutique-gke \
  --format=json
```

Look for `roles/iam.workloadIdentityUser` binding with principal like:

```
principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-pool/attribute.repository/<GITHUB_ORG>/boutique-gke-sre
```

### Part F — Trigger test workflow

```bash
gh workflow run build-scan-sign.yml --repo <GITHUB_ORG>/boutique-gke-sre
gh run list --repo <GITHUB_ORG>/boutique-gke-sre --limit 5
```

Replace `<GITHUB_ORG>` with your GitHub username or organization.

## Expected output

**`terraform apply` (WIF module):**

```
module.wif.google_iam_workload_identity_pool.github: Creation complete
module.wif.google_iam_workload_identity_pool_provider.github: Creation complete
module.wif.google_service_account.ci: Creation complete
Apply complete!
```

**`terraform output wif_provider_name`:**

```
"projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider"
```

**`terraform output ci_service_account_email`:**

```
"github-ci@boutique-gke.iam.gserviceaccount.com"
```

**GitHub Actions log (`Authenticate to Google Cloud`):**

```
Successfully authenticated to Google Cloud
```

**Verify caller identity step:**

```
Active account: github-ci@boutique-gke.iam.gserviceaccount.com
```

## Validation

```bash
cd terraform/environments/boutique
terraform output wif_provider_name
terraform output ci_service_account_email

gcloud iam workload-identity-pools list --location=global --project=boutique-gke
gcloud iam workload-identity-pools providers list \
  --workload-identity-pool=github-pool \
  --location=global \
  --project=boutique-gke
```

In GitHub:

1. **Actions** tab → latest workflow run → **Authenticate to Google Cloud** step → green check
2. Confirm no step downloads or references JSON key material

## Common problems

| Symptom | Cause | Fix |
|---------|-------|-----|
| `invalid_grant` / `unable to acquire impersonated credentials` | Wrong provider name or SA email in secrets | Re-copy from `terraform output`; no typos |
| `Permission 'iam.serviceAccounts.getAccessToken' denied` | Missing `workloadIdentityUser` on CI SA | Re-apply `wif` module; check attribute.repository matches org/repo |
| `id-token: write` missing | Workflow permissions | Add `permissions: id-token: write` at job or workflow level |
| `denied: Permission "artifactregistry.repositories.uploadArtifacts"` | SA lacks AR writer | Grant `roles/artifactregistry.writer` (topic 08) |
| Org policy blocks WIF | Restrictive org constraint | Org admin allows WIF for `boutique-gke` |
| Workflow read-only | GitHub **Workflow permissions** set to read | UI: Settings → Actions → General → Read and write |

## Recovery

**Re-apply Terraform WIF module:**

```bash
cd terraform/environments/boutique
terraform apply -target=module.wif
```

**Rotate / fix GitHub secrets:**

1. GitHub → **Settings** → **Secrets and variables** → **Actions**
2. Update `GCP_WORKLOAD_IDENTITY_PROVIDER` and `GCP_SERVICE_ACCOUNT`
3. Re-run failed workflow

**Remove compromised JSON key (if one was ever created — anti-pattern):**

```bash
gcloud iam service-accounts keys list \
  --iam-account=github-ci@boutique-gke.iam.gserviceaccount.com \
  --project=boutique-gke
gcloud iam service-accounts keys delete KEY_ID \
  --iam-account=github-ci@boutique-gke.iam.gserviceaccount.com \
  --project=boutique-gke
```

Delete corresponding GitHub secret; use WIF only going forward.

## Best practices

- Scope WIF provider attribute condition to `attribute.repository/<org>/boutique-gke-sre` and optionally `ref:refs/heads/main`
- CI service account: `artifactregistry.writer` + signing roles only — not `owner` or `editor`
- Use separate SAs for CI vs Terraform vs human break-glass
- Audit WIF token exchanges in Cloud Logging
- Pin `google-github-actions/auth@v2` to a digest or minor version tag in production workflows

## Security notes

- **Never** download or store GCP service account JSON keys in GitHub Secrets, repo files, or laptops
- `id-token: write` exposes OIDC tokens only to GitHub Actions runtime — still restrict which workflows run on `pull_request_target`
- WIF trust relationship is cross-cloud — review provider attribute mappings on every Terraform change
- Disable unused SA keys project-wide: `gcloud org-policies` / regular key audits
- See [supply-chain.md](../security/supply-chain.md) and [ADR 002](../adr/002-wif-over-sa-keys.md)

## Next step

→ [08 — Artifact Registry and Binary Authorization](08-artifact-registry-binary-auth.md)

WIF must be in place before CI can push signed images to Artifact Registry.
