# Scripts

Operational helpers — **not** replacements for `docs/setup/` guides.

## Layout

- `bootstrap/` — prerequisite validation
- `game-days/` — failure injection (Phase 7)
- `teardown/` — pre-destroy and orphan scans (Phase 8)
- `media/` — regenerate operational PNG screenshots

## Media generation

| Script                                | Purpose                                                   |
| ------------------------------------- | --------------------------------------------------------- |
| `media/generate-media-screenshots.py` | SLO dashboard, runbook lint, PagerDuty test incident PNGs |

Outputs are written to `assets/diagrams/`.

## Observability / alerting (Phase 6–7)

| Script                                  | Purpose                                                            | Setup guide                                                        |
| --------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------ |
| `attach-pagerduty-channel.sh`           | Attach PagerDuty notification channel to all alert policies        | [14-pagerduty.md](../docs/setup/14-pagerduty.md) step 4            |
| `create-uptime-check.sh`                | Create storefront uptime check and alert policy                    | [13-observability-slos.md](../docs/setup/13-observability-slos.md) |
| `create-burn-rate-policies.sh`          | Create SLO burn-rate alert policies                                | [13-observability-slos.md](../docs/setup/13-observability-slos.md) |
| `create-supplemental-alert-policies.sh` | Create bad-deploy and redis-cart alert policies                    | [13-observability-slos.md](../docs/setup/13-observability-slos.md) |
| `validate-runbook-links.sh`             | Lint alert policy ↔ runbook registry consistency                   | `make runbook-lint`                                                |
| `lib/runbooks.sh`                       | Resolve runbook URLs from `observability/monitoring/runbooks.yaml` | —                                                                  |
| `attach-argocd-armor.sh`                | Attach Cloud Armor `argocd-edge` to Argo CD ingress backend        | [edge-hardening.md](../docs/security/edge-hardening.md)            |
