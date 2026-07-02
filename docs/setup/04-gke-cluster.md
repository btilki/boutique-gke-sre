# GKE cluster

## Goal

A regional **private** GKE cluster named `boutique-gke` runs in `europe-west1` with Workload Identity, autoscaling node pool `boutique-primary`, and private nodes on `boutique-gke-subnet`. You can authenticate with `kubectl` and see healthy nodes in `Ready` state.

## Why this step is required

The cluster is the runtime for Argo CD, Online Boutique, Kyverno, External Secrets, and observability agents. Networking from [03 — VPC and Cloud NAT](03-vpc-nat.md) allocated pod and service CIDRs; the GKE module consumes those secondary ranges. Without a live cluster, DNS, ingress TLS, GitOps bootstrap, and application deploys cannot proceed.

If you completed topic 03 when `terraform/environments/boutique/main.tf` contained only Phase 1 modules (`project_apis`, `networking`), pull the latest repository before this topic. Topic 04 adds the `gke` module (and may show `ingress_edge` and `dns` in plan if Phase 2 code is present but not yet applied).

## Prerequisites

- Prior guide: [03 — VPC, subnets, and Cloud NAT](03-vpc-nat.md) — Phase 1 Terraform applied successfully
- Tools: Terraform ≥ 1.5, Google Cloud SDK (`gcloud`), `kubectl` ≥ 1.28
- Access: `roles/container.admin` (or equivalent) on project `boutique-gke`, ability to run `terraform apply` against the remote state bucket from [02 — Terraform remote state](02-terraform-remote-state.md)
- Repository includes `terraform/modules/gke` and `module "gke"` wired in `terraform/environments/boutique/main.tf`

## Commands

### 1. Confirm project and working directory

```bash
gcloud config set project boutique-gke
gcloud config set compute/region europe-west1
cd terraform/environments/boutique
```

### 2. Sync Terraform configuration (if upgrading from Phase 1-only state)

```bash
git pull
terraform init -upgrade
```

### 3. Review the plan (GKE and any unapplied Phase 2 modules)

```bash
terraform plan -out=tfplan
```

Review the plan output. You should see resources under `module.gke` (cluster `boutique-gke`, node pool `boutique-primary`). If `module.ingress_edge` or `module.dns` also appear and you prefer to apply infrastructure incrementally per topic, you may apply only GKE in this step:

```bash
terraform apply -target=module.gke
```

Otherwise, apply the full saved plan (creates GKE plus any other pending Phase 2 modules in the plan):

```bash
terraform apply tfplan
```

GKE cluster creation typically takes 10–15 minutes.

### 4. Capture cluster outputs

```bash
terraform output cluster_name
terraform output cluster_location
terraform output -raw cluster_name
```

### 5. Fetch kubeconfig credentials

```bash
gcloud container clusters get-credentials boutique-gke --region europe-west1 --project boutique-gke
```

### 6. Verify API connectivity and nodes

```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl get nodes --show-labels
```

### 7. Optional — confirm Workload Identity pool

```bash
gcloud container clusters describe boutique-gke \
  --region=europe-west1 \
  --project=boutique-gke \
  --format='value(workloadIdentityConfig.workloadPool)'
```

## Expected output

**`terraform apply`** (GKE portion) ends with:

```
module.gke.google_container_cluster.primary: Creation complete
module.gke.google_container_node_pool.primary: Creation complete

Apply complete! Resources: N added, 0 changed, 0 destroyed.
```

**`terraform output cluster_name`:**

```
"boutique-gke"
```

**`terraform output cluster_location`:**

```
"europe-west1"
```

**`gcloud container clusters get-credentials`:**

```
Fetching cluster endpoint and auth data.
kubeconfig entry generated for boutique-gke.
```

**`kubectl get nodes`:**

```
NAME                                        STATUS   ROLES    AGE   VERSION
gke-boutique-gke-boutique-primary-xxxxx     Ready    <none>   5m    v1.xx.x-gke.xxxx
gke-boutique-gke-boutique-primary-xxxxx     Ready    <none>   5m    v1.xx.x-gke.xxxx
gke-boutique-gke-boutique-primary-xxxxx     Ready    <none>   5m    v1.xx.x-gke.xxxx
```

Regional clusters spread nodes across zones in `europe-west1`; expect one or more `Ready` nodes per zone depending on autoscaling.

**Workload Identity pool:**

```
boutique-gke.svc.id.goog
```

## Validation

```bash
kubectl get nodes
kubectl get componentstatuses 2>/dev/null || true
kubectl get namespaces
gcloud container clusters describe boutique-gke \
  --region=europe-west1 \
  --project=boutique-gke \
  --format='table(name,location,status,currentMasterVersion,privateClusterConfig.enablePrivateNodes)'
```

Expected:

- All nodes `STATUS` is `Ready`
- Cluster `status` is `RUNNING`
- `enablePrivateNodes` is `True`
- `kubectl` commands succeed without certificate or permission errors

## Common problems

| Symptom                                              | Cause                                              | Fix                                                                                                                       |
| ---------------------------------------------------- | -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `Error 403: Kubernetes Engine API has not been used` | Container API disabled                             | Enable `container.googleapis.com` per [01 — GCP project and APIs](01-gcp-project-apis.md); re-run `terraform apply`       |
| `terraform plan` shows no `module.gke`               | Old `main.tf` or wrong branch                      | `git pull`; confirm `module "gke"` block exists in `terraform/environments/boutique/main.tf`                              |
| `Insufficient regional quotas`                       | CPU or cluster quota                               | Request quota increase in GCP Console → IAM & Admin → Quotas; reduce `max_node_count` in module variables temporarily     |
| `secondary range not found`                          | Phase 1 networking not applied                     | Complete topic 03; verify `boutique-pods` and `boutique-services` secondary ranges on subnet                              |
| `kubectl` timeout / connection refused               | Wrong context or private endpoint misconfiguration | Re-run `get-credentials`; confirm cluster has public control plane endpoint (`enable_private_endpoint = false` in module) |
| `terraform` state lock                               | Concurrent apply                                   | Wait for other session or use `terraform force-unlock <LOCK_ID>` only if you are certain no other apply is running        |
| Node pool stuck `PROVISIONING`                       | Transient GCP capacity                             | Wait 15–20 minutes; check Cloud Logging; delete failed pool via `terraform taint` only as last resort                     |

## Recovery

**Retry failed apply (safe):**

```bash
cd terraform/environments/boutique
terraform plan -out=tfplan
terraform apply tfplan
```

**Destroy only GKE (destructive — removes all workloads):**

```bash
cd terraform/environments/boutique
terraform destroy -target=module.gke
```

**Recreate cluster after destroy:**

```bash
terraform apply -target=module.gke
gcloud container clusters get-credentials boutique-gke --region europe-west1 --project boutique-gke
kubectl get nodes
```

Full teardown order: [teardown.md](../teardown.md).

## Best practices

- Apply GKE in a dedicated topic and validate `kubectl` before DNS or GitOps work
- Pin cluster changes through Terraform; avoid manual edits in Console that cause drift
- Use regional clusters for control-plane availability across zones
- Keep `deletion_protection = true` in production `terraform.tfvars` after bootstrap validation
- Document the Kubernetes version from `gcloud container clusters describe` when filing change records
- Commit Phase 2 Terraform code and a successful `terraform plan` review before `apply`

## Security notes

- Nodes are **private** (no external IPs); egress uses Cloud NAT from topic 03
- Workload Identity (`boutique-gke.svc.id.goog`) replaces long-lived GCP keys on pods — required for ESO and WI-bound service accounts later
- Node service account uses `cloud-platform` scope with IAM least privilege at the project level (not broad Owner)
- Control plane authorized networks are not configured in the reference module; restrict admin access via IAM and corporate network policies
- `cluster_endpoint` and CA cert outputs are sensitive — do not commit kubeconfig or raw credentials to Git
- Enable audit logging review after cluster creation (Admin Activity logs capture cluster operations)

## Next step

→ [05 — Cloud DNS and registrar NS delegation](05-cloud-dns.md)

Confirm `kubectl get nodes` shows `Ready` before proceeding. If `module.ingress_edge` and `module.dns` were deferred, topic 05 applies them before registrar delegation.
