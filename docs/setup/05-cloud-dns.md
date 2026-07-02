# Cloud DNS and registrar NS delegation

## Goal

A Cloud DNS managed zone for `biroltilki.art` exists in project `boutique-gke` with **A records** for `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art` pointing at the global ingress static IP. Your domain registrar delegates DNS to Google’s name servers (`ns-cloud-*.googledomains.com`), and public `dig` queries return the static IP.

## Why this step is required

Google-managed TLS certificates (topic 06) and public HTTPS hostnames require resolvable DNS. The `dns` Terraform module creates the managed zone and A records; **registrar NS delegation** is the step only you can perform at your domain provider. Without delegation, `dig` returns nothing or stale records and certificate provisioning fails.

The `dns` module depends on `module.ingress_edge` for the static IP address. If you applied only `module.gke` in topic 04, apply `ingress_edge` and `dns` in this topic before registrar changes.

## Prerequisites

- Prior guide: [04 — GKE cluster](04-gke-cluster.md) — cluster running; `kubectl` works
- Tools: Terraform ≥ 1.5, `gcloud`, `dig` (macOS: built-in; install `bind-tools` on Linux if needed)
- Access: DNS Admin on `boutique-gke`; login to domain registrar for `biroltilki.art`
- See also: [dns.md](../dns.md)

## Commands

### 1. Apply ingress static IP and Cloud DNS (if not already applied)

```bash
gcloud config set project boutique-gke
cd terraform/environments/boutique
terraform init
terraform plan -out=tfplan
```

Confirm the plan includes `module.ingress_edge` and `module.dns` if they are not yet in state. Apply:

```bash
terraform apply tfplan
```

To apply only the DNS-related modules:

```bash
terraform apply -target=module.ingress_edge -target=module.dns
```

### 2. Capture Terraform outputs

```bash
terraform output ingress_static_ip
terraform output dns_name_servers
terraform output boutique_url
terraform output argocd_url
```

Copy all four name server hostnames from `dns_name_servers` (they look like `ns-cloud-a1.googledomains.com.` through `ns-cloud-d1.googledomains.com.` — exact letters vary).

### 3. Verify zone and records in GCP

```bash
gcloud dns managed-zones describe biroltilki-art \
  --project=boutique-gke \
  --format='yaml(name,dnsName,nameServers)'

gcloud dns record-sets list \
  --zone=biroltilki-art \
  --project=boutique-gke \
  --filter='type=A'
```

### 4. Delegate at domain registrar (graphical UI)

Perform these steps at the registrar where you purchased `biroltilki.art` (Google Domains, Cloudflare Registrar, Namecheap, etc.). Menu labels differ slightly; the pattern is the same.

1. Sign in to your registrar account.
2. Open **My domains** (or **Domain list**) and click **`biroltilki.art`**.
3. Open **DNS** settings. Look for **Nameservers**, **DNS management**, or **Custom nameservers**.
4. Change from **Default nameservers** (registrar-hosted DNS) to **Custom nameservers** (sometimes labeled **Use custom DNS** or **I'll use my own nameservers**).
5. Remove any existing registrar nameserver entries if the UI requires clearing them first.
6. Add **four** nameserver hostnames — paste exactly from `terraform output dns_name_servers`, **without** trailing dots if the UI rejects them:
   - Example slot 1: `ns-cloud-a1.googledomains.com`
   - Example slot 2: `ns-cloud-b1.googledomains.com`
   - Example slot 3: `ns-cloud-c1.googledomains.com`
   - Example slot 4: `ns-cloud-d1.googledomains.com`
     (Your Terraform output values are authoritative — use those, not these examples.)
7. **Do not** create A records at the registrar when using custom nameservers; Cloud DNS owns all records after delegation.
8. Click **Save**, **Apply**, or **Update nameservers**.
9. Confirm the registrar shows the four `ns-cloud-*.googledomains.com` entries as active.

**GCP Console cross-check (optional):**

1. Open [Google Cloud Console](https://console.cloud.google.com/) → select project **`boutique-gke`**.
2. Navigate **Network services** → **Cloud DNS**.
3. Click managed zone **`biroltilki-art`** (DNS name `biroltilki.art.`).
4. Copy **DNS name servers** from the zone details page — they must match what you entered at the registrar.
5. Under **Zone details** → **Records**, confirm **A** records for `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art` point to the same IP as `terraform output ingress_static_ip`.

### 5. Wait for propagation

Delegation can take 5 minutes to 48 hours. Poll every few minutes:

```bash
dig +short NS biroltilki.art
```

When delegation is active, all returned NS hostnames are `ns-cloud-*.googledomains.com`.

## Expected output

**`terraform output dns_name_servers`:**

```
tolist([
  "ns-cloud-a1.googledomains.com.",
  "ns-cloud-b1.googledomains.com.",
  "ns-cloud-c1.googledomains.com.",
  "ns-cloud-d1.googledomains.com.",
])
```

**`terraform output ingress_static_ip`:**

```
"35.xxx.xxx.xxx"
```

**`gcloud dns record-sets list` (A records):**

```
NAME                              TYPE  TTL  DATA
boutique.biroltilki.art.          A     300  35.xxx.xxx.xxx
argocd.boutique.biroltilki.art.   A     300  35.xxx.xxx.xxx
```

**`dig +short NS biroltilki.art` (after delegation):**

```
ns-cloud-a1.googledomains.com.
ns-cloud-b1.googledomains.com.
ns-cloud-c1.googledomains.com.
ns-cloud-d1.googledomains.com.
```

## Validation

```bash
STATIC_IP="$(cd terraform/environments/boutique && terraform output -raw ingress_static_ip)"
echo "Expected IP: ${STATIC_IP}"

dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
dig +short NS biroltilki.art
dig +trace boutique.biroltilki.art | tail -20
```

Expected:

- `dig +short boutique.biroltilki.art` returns the static IP (same as `ingress_static_ip`)
- `dig +short argocd.boutique.biroltilki.art` returns the **same** static IP
- NS query returns only Google Cloud DNS name servers
- HTTPS `curl` may still fail until topic 06 (certificates) and topic 09 (Argo CD ingress sync) — DNS-only success is sufficient here

Optional authoritative check against Google DNS:

```bash
dig @8.8.8.8 +short boutique.biroltilki.art
dig @8.8.8.8 +short argocd.boutique.biroltilki.art
```

## Common problems

| Symptom                                 | Cause                                      | Fix                                                                                                  |
| --------------------------------------- | ------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| `dig +short` returns empty              | NS not delegated or propagation incomplete | Re-check registrar custom nameservers; wait up to 48 h; flush local DNS cache                        |
| `dig` returns old/wrong IP              | Stale registrar A records or split DNS     | Ensure registrar uses **custom nameservers only**, not hybrid DNS                                    |
| `terraform apply` fails on `module.dns` | `ingress_edge` not applied                 | `terraform apply -target=module.ingress_edge` then re-apply `module.dns`                             |
| NS correct but A record missing         | Terraform drift or wrong zone              | `gcloud dns record-sets list --zone=biroltilki-art --project=boutique-gke`; re-run `terraform apply` |
| `403` on Cloud DNS API                  | API or IAM                                 | Enable `dns.googleapis.com`; grant `roles/dns.admin`                                                 |
| Partial NS set at registrar             | Fewer than four nameservers                | Add all four from `terraform output dns_name_servers`                                                |

## Recovery

**Re-run Terraform DNS without touching registrar:**

```bash
cd terraform/environments/boutique
terraform plan -target=module.ingress_edge -target=module.dns
terraform apply -target=module.ingress_edge -target=module.dns
```

**Revert registrar to previous nameservers (rollback delegation):**

1. Registrar → `biroltilki.art` → **Nameservers**
2. Switch back to **Default nameservers** (registrar-hosted)
3. Save — public DNS will stop using Cloud DNS (use only if tearing down or fixing a misconfiguration)

**Destroy DNS resources (teardown only):**

```bash
cd terraform/environments/boutique
terraform destroy -target=module.dns
```

Restore registrar default NS before or immediately after destroy to avoid orphaned delegation.

## Best practices

- Delegate the **root** zone `biroltilki.art` once; manage all subdomains in Cloud DNS
- Use Terraform for A records — avoid manual Console edits that cause drift
- Keep TTL at 300s during bootstrap; increase after stability if desired
- Record the static IP and name servers in your runbook / password manager vault (not in public Git)
- Validate with both `dig +short` and `dig @8.8.8.8` to rule out local resolver cache

## Security notes

- Cloud DNS zone is a critical asset — restrict `roles/dns.admin` to platform engineers
- DNS changes are logged in Cloud Audit Logs — review Admin Activity after delegation
- Do not point production NS to a test project; single project `boutique-gke` only
- Registrar account MFA should be enabled; NS hijack equals full traffic control
- No secret material in DNS records for this project; app secrets use Secret Manager (topic 10)

## Next step

→ [06 — Static ingress IP and TLS (managed certificates)](06-ingress-tls.md)

Confirm both hostnames resolve to the static IP before configuring GKE Ingress and ManagedCertificate resources.
