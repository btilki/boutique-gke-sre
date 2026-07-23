# Runbook: uptime check failed

**Alert policy:** `uptime-check-failed`
**Targets** (when DNS is active):

- Storefront: `boutique.biroltilki.art`
- Argo CD: `argocd.boutique.biroltilki.art/healthz`

**Lab note:** After teardown both hostnames are **inactive** ([dns.md](../../dns.md)) — empty `dig` / failed curls are expected offline; do not treat as a live SEV.

## Purpose

External probe cannot reach a public HTTPS edge — storefront outage (SEV1 candidate) and/or GitOps UI / API health failure (SEV2–SEV3 depending on blast radius).

Check which condition fired in the alert (host / check display name) before assuming total storefront loss.

## Initial triage

```bash
# Identify which edge failed (alert body / Monitoring incident)
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art

curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art/healthz

kubectl get ingress -n boutique
kubectl get ingress -n argocd
kubectl get pods -n boutique -l app=frontend
kubectl get pods -n argocd
```

## Branch: storefront (`boutique-storefront`)

### Common causes

- DNS delegation or A record drift (`boutique-ingress-ip`)
- TLS certificate not provisioned
- Load balancer / Ingress deleted or misconfigured
- All frontend pods down

### Escalation

SEV1 if confirmed user-facing storefront outage → [severity.md](../incident-response/severity.md)

## Branch: Argo CD (`argocd-ui`)

### Common causes

- DNS / TLS / Ingress on `argocd-ingress-ip`
- Argo CD server pods not Ready
- Cloud Armor / IAP blocking synthetic probes (allow health path or probe ranges)
- Certificate or backend service misconfiguration after topic 09 / 15

### Escalation

- SEV2 if deploys blocked and no kubectl/GitOps fallback
- SEV3 if UI down but `kubectl` / `argocd` CLI still works via API server access

See [troubleshooting/argocd-sync-failures.md](../../troubleshooting/argocd-sync-failures.md) and [setup/09-argocd-bootstrap.md](../../setup/09-argocd-bootstrap.md).

## Further reading

- [uptime-checks/README.md](../../../observability/monitoring/uptime-checks/README.md)
- [create-uptime-check.sh](../../../scripts/create-uptime-check.sh) / [create-argocd-uptime-check.sh](../../../scripts/create-argocd-uptime-check.sh)
- [quick-reference.md](../../operations/quick-reference.md)
