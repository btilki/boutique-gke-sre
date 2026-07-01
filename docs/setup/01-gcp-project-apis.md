# GCP project and APIs

## Goal

GCP project `boutique-gke` exists with billing linked, default region/zone configured, and all required service APIs enabled for GKE, DNS, IAM, Artifact Registry, monitoring, and security services.

## Why this step is required

Every subsequent Terraform resource and console operation depends on an existing project with billing and enabled service APIs. Applying Terraform against disabled APIs produces opaque `SERVICE_DISABLED` errors. This project is the GCP tenancy boundary for all resources: VPC, GKE, DNS, IAM, WIF, and monitoring.

## Prerequisites

- Google account with permission to create projects or access existing `boutique-gke`
- Billing account ID (if creating a new project)
- Tools installed: [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

## Commands

### GCP Console (optional — verify project, billing, and APIs)

1. Open [Google Cloud Console](https://console.cloud.google.com/).
2. **Project selector** (top bar, next to “Google Cloud”): click the project name → select **boutique-gke**, or click **New Project** to create it with ID `boutique-gke`.
3. **Billing:** **Navigation menu (☰) → Billing**, or use the billing link in the project selector dropdown when billing is not linked. Confirm **boutique-gke** is linked to an active billing account.
4. **APIs & Services:** **Navigation menu (☰) → APIs & Services → Enabled APIs & services**. Confirm `Kubernetes Engine API`, `Compute Engine API`, and `Cloud DNS API` appear in the list (full CLI list below enables the rest).

### CLI — authenticate and set defaults

```bash
gcloud auth login
gcloud auth application-default login
```

### CLI — create or select the project

If the project already exists:

```bash
gcloud config set project boutique-gke
```

If creating a new project (replace `BILLING_ACCOUNT_ID`):

```bash
gcloud projects create boutique-gke --name="Boutique GKE SRE"
gcloud billing projects link boutique-gke --billing-account=BILLING_ACCOUNT_ID
gcloud config set project boutique-gke
```

### CLI — set default region and zone

```bash
gcloud config set compute/region europe-west1
gcloud config set compute/zone europe-west1-b
```

### CLI — enable APIs (Terraform will also manage these)

```bash
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  dns.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  sts.googleapis.com \
  cloudresourcemanager.googleapis.com \
  serviceusage.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com \
  cloudtrace.googleapis.com \
  binaryauthorization.googleapis.com \
  gkebackup.googleapis.com \
  certificatemanager.googleapis.com \
  --project=boutique-gke
```

Topic 03 Terraform (`module.project_apis`) manages the same API set idempotently. CLI enable above is optional if you apply Terraform in topic 03 soon; it reduces `SERVICE_DISABLED` errors during the first apply.

### CLI — verify project configuration

```bash
gcloud config list
gcloud services list --enabled --project=boutique-gke | head -20
```

## Expected output

- `gcloud config list` shows `project = boutique-gke` and region `europe-west1`
- `gcloud services list` includes `container.googleapis.com`, `compute.googleapis.com`, `dns.googleapis.com`, and `sts.googleapis.com` (WIF, topic 07)

## Validation

```bash
gcloud projects describe boutique-gke --format='value(projectId,lifecycleState)'
```

Expected: `boutique-gke` and `ACTIVE`.

## Common problems

| Symptom                     | Cause                        | Fix                                                |
| --------------------------- | ---------------------------- | -------------------------------------------------- |
| `PERMISSION_DENIED`         | Wrong account or missing IAM | Use owner/editor account; check `gcloud auth list` |
| `Billing account not found` | Invalid billing ID           | `gcloud billing accounts list`                     |
| API enable hangs            | Org policy blocking APIs     | Request exception or use permitted project         |
| Project ID taken            | Global uniqueness            | Choose alternate ID; update `terraform.tfvars`     |

## Recovery

- Wrong project selected: `gcloud config set project boutique-gke`
- Accidentally created wrong project: delete empty project in Console → IAM & Admin → Settings

## Best practices

- Use one dedicated project for this reference (`boutique-gke`)
- Enable Cloud Audit Logs for admin activity (default for many orgs)
- Document project number: `gcloud projects describe boutique-gke --format='value(projectNumber)'`

## Security notes

- Grant least privilege; avoid using owner SA keys locally
- Prefer `gcloud auth application-default login` over downloaded JSON keys
- Enable OS Login for human SSH if needed later

## Next step

→ [02 — Terraform remote state](02-terraform-remote-state.md)
