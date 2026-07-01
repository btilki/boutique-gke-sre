# Runbook: uptime check failed

**Alert policy:** `uptime-check-failed`  
**Target:** https://boutique.biroltilki.art

> Full steps expanded in Phase 6–7.

## Purpose

External probe cannot reach storefront — potential total outage (SEV1 candidate).

## Initial triage

```bash
dig +short boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
kubectl get ingress -n boutique
```

## Common causes

- DNS delegation or A record drift
- TLS certificate not provisioned
- Load balancer / Ingress deleted or misconfigured
- All frontend pods down

## Escalation

SEV1 if confirmed user-facing outage → [severity.md](../incident-response/severity.md)
