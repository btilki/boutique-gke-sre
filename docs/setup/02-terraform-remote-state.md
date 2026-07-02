# Terraform remote state (GCS)

## Goal

Versioned GCS bucket `boutique-gke-tfstate` exists for Terraform state with locking, and `backend.tf` in `terraform/environments/boutique/` is wired so `terraform init` succeeds.

## Why this step is required

Remote state enables team collaboration, state locking during applies, and recovery from local disk loss. All Phase 1+ Terraform depends on this backend. State is stored separately from workload infrastructure so teardown can destroy apps before the state bucket (see [teardown.md](../teardown.md)).

## Prerequisites

- [01 — GCP project and APIs](01-gcp-project-apis.md) completed
- `gcloud` authenticated with `storage.buckets.create` permission

## Commands

### 1. Set project

```bash
export PROJECT_ID=boutique-gke
export REGION=europe-west1
gcloud config set project "${PROJECT_ID}"
```

### 2. Create state bucket

Bucket names are globally unique — adjust if `boutique-gke-tfstate` is taken:

```bash
export TF_STATE_BUCKET=boutique-gke-tfstate

gcloud storage buckets create "gs://${TF_STATE_BUCKET}" \
  --project="${PROJECT_ID}" \
  --location="${REGION}" \
  --uniform-bucket-level-access

gcloud storage buckets update "gs://${TF_STATE_BUCKET}" \
  --versioning
```

### 3. Verify backend configuration

Repository file `terraform/environments/boutique/backend.tf` should reference:

```hcl
terraform {
  backend "gcs" {
    bucket = "boutique-gke-tfstate"
    prefix = "boutique"
  }
}
```

If you used a different bucket name, update `backend.tf` before `terraform init`.

### 4. Initialize Terraform

```bash
cd terraform/environments/boutique
terraform init
```

## Expected output

```
Successfully configured the backend "gcs"!
Terraform has been successfully initialized!
```

## Validation

```bash
gcloud storage ls gs://boutique-gke-tfstate/
cd terraform/environments/boutique && terraform validate
```

After first apply (topic 03), state object exists:

```bash
gcloud storage ls gs://boutique-gke-tfstate/boutique/
```

## Common problems

| Symptom                      | Cause                            | Fix                                     |
| ---------------------------- | -------------------------------- | --------------------------------------- |
| `bucket doesn't exist`       | Bucket not created or wrong name | Create bucket; match `backend.tf`       |
| `Error 409` on bucket create | Name globally taken              | Choose unique name; update backend      |
| `Access denied` on init      | ADC lacks storage access         | `gcloud auth application-default login` |
| Backend config change        | Bucket renamed                   | `terraform init -migrate-state`         |

## Recovery

- **Wrong bucket in backend:** Edit `backend.tf`, run `terraform init -migrate-state`
- **Corrupt state:** Restore previous GCS object version (versioning enabled)

## Best practices

- Enable uniform bucket-level access
- Restrict bucket IAM to operators and CI SA only
- Never commit `terraform.tfstate` to Git
- Commit `terraform/environments/boutique/.terraform.lock.hcl` after first successful `terraform init` (pins provider versions for reproducible plans)
- Use separate prefix per environment if extending later

## Security notes

- State may contain sensitive outputs — treat bucket as confidential
- CI read access only if terraform plan in GitHub Actions (Phase 3)
- Enable audit logs for bucket access

## Next step

→ [03 — VPC, subnets, Cloud NAT](03-vpc-nat.md)
