# Runbook: browse availability burn

**Alert policy:** `browse-availability-burn`  
**SLO:** Browse 99.9% availability — [catalog](../slos/catalog.md)

> Full steps expanded in Phase 6–7 when alert policies are live.

## Purpose

Respond to multi-window burn on frontend availability SLI.

## Initial triage

1. Check uptime: `curl -I https://boutique.biroltilki.art`
2. Cloud Console → Monitoring → SLOs → browse availability
3. `kubectl get pods -n boutique -l app=frontend`
4. Check Ingress and Cloud Armor backend health

## Common causes

- Frontend pod failures; image pull errors
- Ingress / TLS / static IP misconfiguration
- Upstream dependency outage

## Further reading

- [error-budget-policy.md](../error-budget-policy.md)
