# Runbook: checkout latency burn

**Alert policy:** `checkout-latency-burn`
**SLO:** Checkout p95 < 1000ms — [catalog](../slos/catalog.md)

> Full steps expanded in Phase 6–7.

## Purpose

Respond when checkout path latency consumes error budget.

## Initial triage

1. Cloud Trace → filter `checkoutservice` spans
2. `kubectl top pods -n boutique`
3. Check `checkoutservice`, `paymentservice`, `shippingservice` logs in Cloud Logging

## Further reading

- [redis-cart-down.md](redis-cart-down.md) if cart state involved
