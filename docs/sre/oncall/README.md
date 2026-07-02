# On-call guide

## Purpose

Orient engineers holding the boutique-gke-sre production on-call rotation.

## When to use

- Start of on-call shift
- Handoff from previous primary
- After game day or incident

## Prerequisites

- PagerDuty mobile app configured
- `kubectl` and `gcloud` access to project `boutique-gke`
- Bookmarks: https://boutique.biroltilki.art, https://argocd.boutique.biroltilki.art

## Architecture

On-call responds to Cloud Monitoring → PagerDuty pages. Runbooks in `docs/sre/runbooks/` are linked from alert policies. Severity taxonomy: [incident-response/severity.md](../incident-response/severity.md).

## Shift checklist

1. Read [playbook.md](playbook.md) and open incidents in PagerDuty
2. Verify test alert path ([test-alerts.md](test-alerts.md)) at shift start if first rotation
3. Check Argo CD app health and recent merges
4. Review open SLO burn in Cloud Monitoring
5. Hand off notes to next primary (open incidents, deploys in flight)

## Tooling

| Tool             | Use                            |
| ---------------- | ------------------------------ |
| PagerDuty        | Acknowledge, escalate, resolve |
| Cloud Monitoring | Alert detail, SLO dashboards   |
| Argo CD          | Deploy state, manual sync      |
| `kubectl`        | Pod logs, events, rollbacks    |
| GitHub           | Revert PRs, digest history     |

## Escalation

See [escalation.md](escalation.md). SEV1/SEV2 checkout outage → escalate within 15 minutes.

## Validation

```bash
gcloud config get-value project
kubectl cluster-info
curl -I https://boutique.biroltilki.art
```

## Troubleshooting

| Symptom              | Cause                        | Fix                                                 |
| -------------------- | ---------------------------- | --------------------------------------------------- |
| Cannot reach cluster | VPN/bastion or creds expired | Refresh `gcloud container clusters get-credentials` |
| PD app silent        | Notification rules           | [test-alerts.md](test-alerts.md)                    |

## Common mistakes

- Acknowledging without opening runbook
- Syncing Argo CD without understanding diff

## Best practices

- Update incident timeline in PagerDuty
- Blameless postmortem for SEV1–SEV2

## Production considerations

- Manual Argo CD sync only ([ADR-003](../../adr/003-manual-argocd-sync.md))
- Error budget policy gates risky changes

## Security considerations

- No production changes from personal accounts without audit trail
- Secrets via ESO/Secret Manager only

## Further reading

- [game-days/README.md](../game-days/README.md)
- [error-budget-policy.md](../error-budget-policy.md)
