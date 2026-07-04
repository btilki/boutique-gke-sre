# Cloud Armor module

WAF security policy for GKE Ingress backend services.

## Purpose

Creates a **Cloud Armor security policy** with rate limiting, optional IP allowlist, and OWASP CRS baseline rules. Used for Argo CD edge hardening (`argocd-edge`) after topic 16 smoke validation.

Storefront policy `boutique-owasp-crs` may be created via Console (topic 15) or a second module instance.

## Inputs

| Name                      | Description                             | Type         | Default  |
| ------------------------- | --------------------------------------- | ------------ | -------- |
| `project_id`              | GCP project ID                          | string       | —        |
| `policy_name`             | Security policy resource name           | string       | —        |
| `description`             | Policy description                      | string       | `""`     |
| `allowed_source_cidrs`    | Admin IP allowlist (deny others if set) | list(string) | `[]`     |
| `rate_limit_count`        | Requests per IP per interval            | number       | `60`     |
| `rate_limit_interval_sec` | Rate limit window                       | number       | `60`     |
| `enable_owasp_crs`        | SQLi + XSS preconfigured rules          | bool         | `true`   |
| `log_level`               | `NORMAL` or `VERBOSE`                   | string       | `NORMAL` |

## Outputs

| Name               | Description      |
| ------------------ | ---------------- |
| `policy_name`      | Policy name      |
| `policy_self_link` | Policy self link |
| `policy_id`        | Policy ID        |

## Dependencies

- `project-apis` module (Compute API)
- GKE Ingress creates backend service (attach via `scripts/attach-argocd-armor.sh`)

## Usage

```hcl
module "armor_argocd" {
  source = "../../modules/armor"

  project_id           = var.project_id
  policy_name          = "argocd-edge"
  allowed_source_cidrs = var.argocd_armor_allowed_cidrs
  rate_limit_count     = 30
}
```

Attach to Argo CD backend after `terraform apply`:

```bash
./scripts/attach-argocd-armor.sh
```

## Implementation phase

**Post topic 16** — Argo CD edge hardening. See [docs/security/edge-hardening.md](../../../docs/security/edge-hardening.md).
