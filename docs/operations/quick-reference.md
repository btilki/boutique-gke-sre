# On-call quick reference — boutique-gke-sre

**Print this page** · Full runbook: [operations-runbook.md](operations-runbook.md)

|                 |                                            |
| --------------- | ------------------------------------------ |
| **Storefront**  | https://boutique.biroltilki.art            |
| **Argo CD**     | https://argocd.boutique.biroltilki.art     |
| **GCP project** | `boutique-gke`                             |
| **Cluster**     | `boutique-gke` · `europe-west1`            |
| **PagerDuty**   | Mobile app · service `boutique-production` |

---

## Shift start (2 min)

```bash
export PROJECT_ID=boutique-gke CLUSTER_NAME=boutique-gke REGION=europe-west1
gcloud config set project "${PROJECT_ID}"
gcloud container clusters get-credentials "${CLUSTER_NAME}" --region="${REGION}"
curl -sS -o /dev/null -w "boutique: %{http_code}\n" https://boutique.biroltilki.art
kubectl -n argocd get applications
```

**Pass:** HTTP 200/302 · nodes Ready · Argo apps Healthy (or OutOfSync awaiting sync)

---

## Severity

| SEV   | When                                             | Response                    |
| ----- | ------------------------------------------------ | --------------------------- |
| **1** | Storefront down · checkout 100% fail · data loss | Page · war room · 5 min ack |
| **2** | Major degradation · error budget 0%              | Page · stakeholder comms    |
| **3** | Partial · workaround exists                      | Ticket · business hours     |
| **4** | No user impact                                   | Backlog                     |

→ [severity.md](../sre/incident-response/severity.md)

---

## Alert → runbook

| Alert policy                 | Runbook                                                                        |
| ---------------------------- | ------------------------------------------------------------------------------ |
| `browse-availability-burn`   | [browse-availability-burn.md](../sre/runbooks/browse-availability-burn.md)     |
| `checkout-availability-burn` | [checkout-availability-burn.md](../sre/runbooks/checkout-availability-burn.md) |
| `uptime-check-failed`        | [uptime-check-failed.md](../sre/runbooks/uptime-check-failed.md)               |
| `bad-deploy-rollback`        | [bad-deploy-rollback.md](../sre/runbooks/bad-deploy-rollback.md)               |
| `redis-cart-down`            | [redis-cart-down.md](../sre/runbooks/redis-cart-down.md)                       |

Registry: `observability/monitoring/runbooks.yaml`

---

## Emergency commands

### Rollback (preferred)

```bash
git log --oneline -5 -- gitops/apps/boutique/values-images.yaml
# Revert bad commit via PR, then:
argocd app sync boutique --prune
kubectl get pods -n boutique
curl -I https://boutique.biroltilki.art
```

### Storefront down

```bash
curl -vI https://boutique.biroltilki.art 2>&1 | head -20
kubectl get ingress,managedcertificate -n boutique
dig +short boutique.biroltilki.art
```

### Bad pods

```bash
kubectl get pods -n boutique
kubectl describe pod -n boutique <pod>
kubectl logs -n boutique <pod> --previous
kubectl get events -n boutique --sort-by='.lastTimestamp' | tail -15
```

### Redis / cart

```bash
kubectl get pods -n boutique -l app=redis-cart
kubectl logs -n boutique -l app=cartservice --tail=50
```

### Argo CD stuck

```bash
argocd app get boutique
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-application-controller --tail=30
```

---

## Triage order

```
DNS → TLS/cert → Ingress → Argo CD sync → Kyverno → Pods → Logs
```

---

## Escalation

- SEV1/SEV2 checkout outage > 15 min → [escalation.md](../sre/oncall/escalation.md)
- Error budget < 25% → freeze non-critical deploys
- Secret exposure → security lead

---

## Post-incident

1. Resolve PagerDuty incident with validation notes
2. SEV1–SEV2 → postmortem within 5 business days ([TEMPLATE.md](../sre/postmortems/TEMPLATE.md))
3. Update runbook if steps were wrong

---

## Do not

- Enable Argo CD auto-sync on production ([ADR-003](../adr/003-manual-argocd-sync.md))
- `kubectl edit` without Git follow-up PR
- Bypass Binary Authorization or Kyverno
- Commit or paste secrets

---

## Links

| Doc                     | Path                                                      |
| ----------------------- | --------------------------------------------------------- |
| Full operations runbook | [operations-runbook.md](operations-runbook.md)            |
| On-call guide           | [oncall/README.md](../sre/oncall/README.md)               |
| Smoke validation        | [16-smoke-validation.md](../setup/16-smoke-validation.md) |
| Game days               | [game-days/](../sre/game-days/)                           |

---

_v1.0 · 2026-07-04 · boutique-gke-sre_
