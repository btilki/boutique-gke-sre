# DNS — biroltilki.art

## Purpose

Document DNS delegation and A records for public hostnames `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art` pointing to the GCE ingress static IP.

## When to use

- Phase 2 after Terraform creates Cloud DNS zone and static IP
- Debugging HTTPS or certificate provisioning failures
- Teardown verification (records removed)

## Prerequisites

- [04 — GKE cluster](setup/04-gke-cluster.md) and networking in progress or complete
- Access to domain registrar for `biroltilki.art`
- Terraform `dns` module applied (Phase 2)

## Architecture

```
Registrar (biroltilki.art NS) → Cloud DNS managed zone
  ├── boutique.biroltilki.art  → A → global static IP
  └── argocd.boutique.biroltilki.art → A → same IP (host-based routing on GCE Ingress)
```

Google-managed TLS certificates provision after A records resolve to the load balancer IP.

## Step-by-step implementation

### 1. Apply Terraform DNS resources

Follow [05 — Cloud DNS](setup/05-cloud-dns.md) when Phase 2 is implemented.

### 2. Get Cloud DNS name servers

**GCP Console:** Network services → Cloud DNS → zone for `biroltilki.art` (or subdomain strategy) → copy **Name servers**.

```bash
gcloud dns managed-zones describe biroltilki-art \
  --project=boutique-gke --format='value(nameServers)'
```

### 3. Delegate at registrar

At your registrar for `biroltilki.art`:

1. Open DNS / Nameservers
2. Select **Custom nameservers**
3. Paste all four `ns-cloud-*.googledomains.com` values
4. Save (propagation: minutes to 48 hours)

### 4. Verify A records

```bash
gcloud dns record-sets list --zone=biroltilki-art --project=boutique-gke
```

| Hostname                         | Type | Target                     |
| -------------------------------- | ---- | -------------------------- |
| `boutique.biroltilki.art`        | A    | Terraform static global IP |
| `argocd.boutique.biroltilki.art` | A    | Same static IP             |

## Validation

```bash
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
```

**Expected DNS:** Both return the same global static IP.
**Expected HTTPS:** After certs provision (15–60 min): `HTTP/2 200` or `302`, no certificate errors.

## Troubleshooting

| Symptom                  | Cause                          | Fix                                           |
| ------------------------ | ------------------------------ | --------------------------------------------- |
| `dig` empty              | NS not delegated or wrong zone | Re-check registrar NS                         |
| Wrong IP                 | Stale record                   | Update A record in Cloud DNS                  |
| TLS stuck "Provisioning" | DNS not pointing to LB IP      | Wait for propagation; check Ingress events    |
| Cert active but 404      | Ingress rules                  | [06 — Ingress + TLS](setup/06-ingress-tls.md) |

## Common mistakes

- Creating A records at registrar while also using Cloud DNS NS (use one authority)
- Forgetting both hostnames share one IP with different Ingress rules

## Best practices

- Lower TTL before migration; document IP in Terraform outputs
- Keep DNS in Terraform for reproducible teardown

## Production considerations

- Subdomain-only delegation (`boutique.biroltilki.art` zone) vs apex — choose one strategy and document in tfvars
- Teardown must delete records before releasing static IP

## Security considerations

- DNS changes are admin-audited in Cloud Audit Logs
- Restrict `dns.admin` IAM to platform operators

## Further reading

- [setup/05-cloud-dns.md](setup/05-cloud-dns.md)
- [setup/06-ingress-tls.md](setup/06-ingress-tls.md)
- [teardown.md](teardown.md)
- [GCP Cloud DNS docs](https://cloud.google.com/dns/docs)
