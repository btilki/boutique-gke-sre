# Cloud Armor module

WAF security policy for the ingress load balancer.

## Purpose

Defines a **Cloud Armor security policy** with baseline WAF rules (OWASP CRS, rate limiting, geo restrictions as configured) and attaches it to the backend service behind the GKE ingress. Protects `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art` at the Google Cloud load balancer edge. Tuned during SRE ops after observability baselines exist.

## Inputs

| Name  | Description                       | Type  | Default |
| ----- | --------------------------------- | ----- | ------- |
| _TBD_ | _To be defined in `variables.tf`_ | _TBD_ | _TBD_   |

## Outputs

| Name  | Description                     |
| ----- | ------------------------------- |
| _TBD_ | _To be defined in `outputs.tf`_ |

## Dependencies

- `project-apis` module (Compute API enabled)
- `ingress-edge` module (load balancer / backend service to attach policy)
- `gke` module (ingress controller and backend services running)
- `monitoring` module (alerting on blocked requests, Phase 6–7)

## Usage

```hcl
module "armor" {
  source = "../../modules/armor"

  project_id          = var.project_id
  policy_name         = "boutique-ingress-waf"
  backend_service_id  = var.ingress_backend_service_id
  enable_owasp_rules  = true
}
```

## Implementation phase

**Phase 7** — Cloud Armor on storefront ([docs/setup/15-cloud-armor.md](../../../docs/setup/15-cloud-armor.md)). Baseline ingress may exist from Phase 2; hardened WAF policy lands in topic 15.
