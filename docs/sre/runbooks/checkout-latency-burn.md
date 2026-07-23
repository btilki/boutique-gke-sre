# Runbook: checkout latency burn

**Alert policy:** `checkout-latency-burn`
**SLO:** Checkout p95 &lt; 1000ms (goal 0.95 ≤ 1s) — [catalog](../slos/catalog.md)

## Purpose

Respond to multi-window burn on checkout path latency SLI (`boutique/checkout_latency` distribution, or Trace/OTel fallback).

## Initial triage

1. Cloud Console → Monitoring → Services → `boutique-checkout` → SLO `checkout-latency`
2. Cloud Trace → filter `checkoutservice` / `PlaceOrder` — identify slow spans (payment, cart, shipping, email)
3. Cloud Logging → `checkoutservice` for slow or retried `[PlaceOrder]` paths
4. Verify log-based metric `boutique/checkout_latency` has recent distribution data (topic 17)
5. `kubectl get pods -n boutique -l 'app in (checkoutservice,paymentservice,cartservice,shippingservice,redis-cart)'`
6. If cart involved: [redis-cart-down.md](redis-cart-down.md)

## Common causes

- Downstream gRPC latency (`paymentservice`, `cartservice` / Redis, `shippingservice`)
- Redis cart saturation or failover
- Checkout pod resource pressure / single replica
- Log-based metric extraction drift (latency field missing → empty SLO series / false burn)
- Recent digest deploy introducing slower dependency path

## Diagnostic tree

```text
Checkout slow?
  ├─ Trace shows payment/cart span dominant → fix that dependency
  ├─ Redis errors / restarts → [redis-cart-down.md](redis-cart-down.md)
  ├─ Availability also burning → [checkout-availability-burn.md](checkout-availability-burn.md)
  ├─ Metric has no data → fix checkout_latency extractor or use Trace fallback (topic 17)
  └─ Recent deploy → [bad-deploy-rollback.md](bad-deploy-rollback.md)
```

## Escalation

- Fast burn (1 h / 6 h): page on-call; consider checkout feature freeze if budget near exhaustion
- Slow burn (24 h): ticket; error-budget review

## Further reading

- [error-budget-policy.md](../error-budget-policy.md)
- [checkout-availability-burn.md](checkout-availability-burn.md)
- [setup/17-latency-slos-dashboards.md](../../setup/17-latency-slos-dashboards.md)
- [redis-cart-down.md](redis-cart-down.md)
