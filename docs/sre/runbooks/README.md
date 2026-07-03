# Runbooks

One runbook per Cloud Monitoring alert policy. Alert notifications must include the runbook URL.

| Runbook                                                        | Alert policy                 | Phase |
| -------------------------------------------------------------- | ---------------------------- | ----- |
| [browse-availability-burn.md](browse-availability-burn.md)     | Browse SLO fast/slow burn    | 6–7   |
| [checkout-availability-burn.md](checkout-availability-burn.md) | Checkout availability burn   | 6–7   |
| [uptime-check-failed.md](uptime-check-failed.md)               | External uptime check        | 6–7   |
| [bad-deploy-rollback.md](bad-deploy-rollback.md)               | Deploy failure / error spike | 5–7   |
| [redis-cart-down.md](redis-cart-down.md)                       | Cart/checkout degradation    | 7     |
| [redis-restore.md](redis-restore.md)                           | DR — Redis restore           | 8     |
| [cluster-rebuild.md](cluster-rebuild.md)                       | DR — cluster rebuild         | 8     |

Template structure per [documentation rule](../../.cursor/rules/documentation.mdc).
