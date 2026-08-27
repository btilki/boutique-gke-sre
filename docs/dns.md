# DNS — biroltilki.art

## Purpose

Document **DNS** (**Domain Name System**) delegation and A records for public hostnames `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art`. Each hostname points at a **dedicated** GCE Ingress static IP.

## Current status (post-teardown)

| Hostname                         | Role       | Status                                                              |
| -------------------------------- | ---------- | ------------------------------------------------------------------- |
| `boutique.biroltilki.art`        | Storefront | **Inactive** — no public A record (infra decommissioned 2026-07-04) |
| `argocd.boutique.biroltilki.art` | Argo CD UI | **Inactive** — no public A record (infra decommissioned 2026-07-04) |

Expected while offline: `dig +short` returns empty for both names. Re-create A records only during Phase 2 rebuild ([setup/05-cloud-dns.md](setup/05-cloud-dns.md)).

## When to use

- Phase 2 after Terraform creates Cloud DNS zone and both static IPs
- Debugging HTTPS or certificate provisioning failures
- Teardown verification (records removed; names inactive)

## Prerequisites

- [04 — GKE cluster](setup/04-gke-cluster.md) and networking in progress or complete
- Access to domain registrar for `biroltilki.art`
- Terraform `ingress-edge` + `dns` modules applied (Phase 2)

## Architecture

```
Registrar (biroltilki.art NS) → Cloud DNS managed zone
  ├── boutique.biroltilki.art        → A → boutique-ingress-ip
  └── argocd.boutique.biroltilki.art → A → argocd-ingress-ip
```

GCE Ingress provisions one HTTP(S) load balancer per Ingress object, so the two hostnames cannot share an IP. Google-managed TLS certificates provision after each A record resolves to **its** load balancer IP.

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

| Hostname                         | Type | Target                                      |
| -------------------------------- | ---- | ------------------------------------------- |
| `boutique.biroltilki.art`        | A    | `terraform output ingress_static_ip`        |
| `argocd.boutique.biroltilki.art` | A    | `terraform output argocd_ingress_static_ip` |

## Validation

```bash
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
curl -I https://argocd.boutique.biroltilki.art
```

**Expected DNS:** Each name returns its dedicated global static IP (the two addresses differ).
**Expected HTTPS:** After certs provision (15–60 min): `HTTP/2 200` or `302`, no certificate errors.

## Troubleshooting

| Symptom                  | Cause                              | Fix                                             |
| ------------------------ | ---------------------------------- | ----------------------------------------------- |
| `dig` empty              | NS not delegated or wrong zone     | Re-check registrar NS                           |
| Wrong IP                 | Stale record or single-IP leftover | Compare to both Terraform IP outputs            |
| Both names same IP       | DNS module not on dual-IP          | Re-apply `module.ingress_edge` and `module.dns` |
| TLS stuck "Provisioning" | DNS not pointing to **this** LB IP | Wait for propagation; check Ingress events      |
| Cert active but 404      | Ingress rules                      | [06 — Ingress + TLS](setup/06-ingress-tls.md)   |

## Common mistakes

- Creating A records at registrar while also using Cloud DNS NS (use one authority)
- Pointing both hostnames at `boutique-ingress-ip` (Argo CD Ingress will never become healthy)

## Best practices

- Lower TTL before migration; document **both** IPs in Terraform outputs
- Keep DNS in Terraform for reproducible teardown

## Production considerations

- Subdomain-only delegation (`boutique.biroltilki.art` zone) vs apex — choose one strategy and document in tfvars
- Teardown must delete records before releasing static IPs

## Security considerations

- DNS changes are admin-audited in Cloud Audit Logs
- Restrict `dns.admin` IAM to platform operators

## Further reading

- [setup/05-cloud-dns.md](setup/05-cloud-dns.md)
- [setup/06-ingress-tls.md](setup/06-ingress-tls.md)
- [teardown.md](teardown.md)
- [GCP Cloud DNS docs](https://cloud.google.com/dns/docs)
