# Monitoring module

Cloud Monitoring uptime checks, notification channels, and alert foundations.

## Purpose

Provisions **Cloud Monitoring** resources for boutique-gke-sre: HTTPS **uptime checks** for `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art`, **notification channels** (email, PagerDuty), log-based metrics, and alert policy scaffolding. SLO definitions and burn-rate alerts are extended in `observability/`; this module owns GCP-native monitoring primitives wired from Terraform.

## Inputs

| Name  | Description                       | Type  | Default |
| ----- | --------------------------------- | ----- | ------- |
| _TBD_ | _To be defined in `variables.tf`_ | _TBD_ | _TBD_   |

## Outputs

| Name  | Description                     |
| ----- | ------------------------------- |
| _TBD_ | _To be defined in `outputs.tf`_ |

## Dependencies

- `project-apis` module (Monitoring API enabled)
- `dns` module (hostnames resolvable for uptime checks)
- `ingress-edge` module (HTTPS endpoints live)
- `secret-manager` module (PagerDuty integration key, Phase 7)

## Usage

```hcl
module "monitoring" {
  source = "../../modules/monitoring"

  project_id = var.project_id

  uptime_hosts = [
    "boutique.biroltilki.art",
    "argocd.boutique.biroltilki.art",
  ]

  notification_channels = {
    pagerduty = {
      type        = "pagerduty"
      display_name = "boutique-gke-oncall"
    }
  }
}
```

## Implementation phase

**Phase 6–7** — Observability and SLOs in Phase 6 ([docs/setup/13-observability-slos.md](../../../docs/setup/13-observability-slos.md)); PagerDuty routing and alert tests in Phase 7 ([docs/setup/14-pagerduty.md](../../../docs/setup/14-pagerduty.md)).
