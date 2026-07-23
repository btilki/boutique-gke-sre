# Runbook: browse latency burn

**Alert policy:** `browse-latency-burn`
**SLO:** Browse p95 &lt; 500ms (goal 0.95 ≤ 500ms) — [catalog](../slos/catalog.md)

## Purpose

Respond to multi-window burn on frontend request latency SLI (HTTPS LB `total_latencies`).

## Initial triage

1. Confirm user impact: `curl -o /dev/null -s -w '%{time_total}\n' `boutique.biroltilki.art``
2. Cloud Console → Monitoring → Services → `boutique-frontend` → SLO `browse-latency`
3. Cloud Monitoring → Metrics Explorer → `loadbalancing.googleapis.com/https/total_latencies` for the boutique frontend url_map
4. `kubectl top pods -n boutique -l app=frontend` and `kubectl get hpa,pdb -n boutique` (if configured)
5. Grafana → golden-signals / SLO overview dashboards (topic 17) if available
6. Check recent Argo CD sync / digest change: `argocd app get boutique --grpc-web`

## Common causes

- Frontend CPU/memory saturation or single-replica overload
- Slow upstream gRPC calls (productcatalog, cart, currency) inflating page time
- Cold start / image pull after deploy
- Edge issues: Cloud Armor challenge rate, backend timeout, unhealthy NEG
- url_map / backend service misconfiguration after ingress change

## Diagnostic tree

```text
Storefront slow?
  ├─ High LB latency, pods healthy → check upstream services + Trace
  ├─ Pods Pending / OOMKilled → capacity / limits / node pool
  ├─ Recent deploy → [bad-deploy-rollback.md](bad-deploy-rollback.md)
  └─ Availability also burning → [browse-availability-burn.md](browse-availability-burn.md)
```

## Escalation

- Fast burn (1 h / 6 h): page on-call; pause non-critical deploys if budget falling fast
- Slow burn (24 h): ticket; schedule latency review per [error-budget-policy.md](../error-budget-policy.md)

## Further reading

- [error-budget-policy.md](../error-budget-policy.md)
- [setup/17-latency-slos-dashboards.md](../../setup/17-latency-slos-dashboards.md)
- [browse-availability-burn.md](browse-availability-burn.md)
