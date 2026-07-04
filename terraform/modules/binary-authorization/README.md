# Binary Authorization module

Attestor, note, and deploy-time image policy for GKE.

## Purpose

Enforces **Binary Authorization** on the private GKE cluster so only **cosign-signed and attested** images from the project Artifact Registry can run. Defines an attestor (linked to cosign key material or Cloud KMS), a policy note, and a cluster admission policy. Must be validated in Phase 3 before Boutique deploy in Phase 5.

## Inputs

| Name                                | Description               | Type           | Default                     |
| ----------------------------------- | ------------------------- | -------------- | --------------------------- |
| `project_id`                        | GCP project ID            | `string`       | —                           |
| `cluster_name`                      | GKE cluster name          | `string`       | —                           |
| `location`                          | Cluster region            | `string`       | `europe-west1`              |
| `attestor_id`                       | Attestor resource ID      | `string`       | `boutique-cosign-attestor`  |
| `cosign_public_key_pem`             | Cosign public key PEM     | `string`       | —                           |
| `cosign_signature_algorithm`        | PKIX algorithm            | `string`       | `ECDSA_P256_SHA256`         |
| `enforcement_mode`                  | Cluster enforcement       | `string`       | `DRYRUN_AUDIT_LOG_ONLY`     |
| `platform_image_whitelist_patterns` | Platform image exemptions | `list(string)` | Argo CD, Kyverno, ESO, etc. |

## Outputs

| Name                   | Description                                            |
| ---------------------- | ------------------------------------------------------ |
| `attestor_name`        | Attestor resource name                                 |
| `cluster_admission_id` | Policy cluster specifier (`europe-west1.boutique-gke`) |
| `enforcement_mode`     | Active enforcement mode                                |

## Dependencies

- `project-apis` module (Binary Authorization API enabled)
- `gke` module (cluster to attach policy)
- `artifact-registry` module (allowed image repository)
- `wif` module (CI cosign signing workflow produces attestations)

## Usage

In `terraform/environments/boutique/main.tf` (requires `cosign_public_key_pem` in `terraform.tfvars`):

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

## Implementation phase

**Phase 3** — WIF, Artifact Registry, CI pipeline ([docs/setup/08-artifact-registry-binary-auth.md](../../../docs/setup/08-artifact-registry-binary-auth.md)).

**Post topic 16** — set `binary_authorization_enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"` ([docs/security/edge-hardening.md](../../../docs/security/edge-hardening.md)).
