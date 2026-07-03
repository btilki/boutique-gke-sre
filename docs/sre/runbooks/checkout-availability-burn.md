# Runbook: checkout availability burn

**Alert policy:** `checkout-availability-burn`
**SLO:** Checkout availability 99.95% — [catalog](../slos/catalog.md)

## Purpose

Respond to multi-window burn on checkout availability SLI (successful checkouts / attempts).

## Initial triage

1. Cloud Console → Monitoring → Services → `boutique-checkout` → SLO `checkout-availability`
2. Cloud Logging → filter `checkoutservice` for `[PlaceOrder]` errors
3. Cloud Trace → filter `checkoutservice` spans for checkout path latency
4. `kubectl get pods -n boutique -l app=checkoutservice`
5. Verify log-based metrics `boutique/checkout_attempts` and `boutique/checkout_success` have recent data

## Common causes

- `checkoutservice` pod failures or image pull errors
- Downstream gRPC dependency outage (`paymentservice`, `cartservice`, `shippingservice`)
- Redis cart unavailable
- Log-based metric filter drift after application log format change

## Escalation

- Fast burn (1 h / 6 h windows): page on-call; consider checkout path freeze
- Slow burn (24 h window): ticket; review error budget policy

## Further reading

- [error-budget-policy.md](../error-budget-policy.md)
- [redis-cart-down.md](redis-cart-down.md) if cart state involved
