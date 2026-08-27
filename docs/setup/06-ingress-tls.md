# Static ingress IP and TLS (managed certificates)

## Goal

Terraform has reserved **two** global static IPs (`boutique-ingress-ip` and `argocd-ingress-ip`). Git already contains per-hostname GCE Ingress annotations and **ManagedCertificate** CRs. After Argo CD Ingress apply (topic 09) and Boutique deploy (topic 12), each hostname serves valid **TLS** (**Transport Layer Security**) on its own load balancer.

## Why this step is required

Public traffic reaches the cluster through Google Cloud external HTTP(S) load balancers. **GCE Ingress creates one load balancer per Ingress object**, so Boutique and Argo CD cannot share an IP. Dedicated static IPs keep Cloud DNS A records (topic 05) stable across Ingress reconciles. **Google-managed certificates** provision automatically when DNS points at the matching load balancer and the ManagedCertificate CR is `Active`. This avoids manual TLS secret management.

HTTPS will **not** work end-to-end until:

- Topic 09 applies the Argo CD Ingress (`argocd-ingress-ip` + `argocd-managed-cert`)
- Topic 12 syncs the Boutique Ingress (`boutique-ingress-ip` + `boutique-managed-cert`)
- Each ManagedCertificate reaches `Active` (often 15–60 minutes after DNS and Ingress are correct)

## Prerequisites

- Prior guide: [05 — Cloud DNS and registrar NS delegation](05-cloud-dns.md) — each hostname resolves to its matching static IP
- Tools: `kubectl`, `gcloud`, `curl`, `dig`
- Access: `kubectl` to cluster `boutique-gke`
- Repository paths (already committed — **do not rewrite** to a shared IP or shared cert):
  - `gitops/bootstrap/argocd/ingress.yaml`
  - `gitops/bootstrap/argocd/managed-certificate.yaml`
  - `gitops/apps/boutique/templates/ingress.yaml` (applied in topic 12)

## Commands

### 1. Confirm both static IPs from Terraform

```bash
gcloud config set project boutique-gke
cd terraform/environments/boutique
terraform output ingress_static_ip
terraform output argocd_ingress_static_ip
terraform output ingress_static_ip_name
terraform output argocd_ingress_static_ip_name
```

Verify both GCP address resources exist:

```bash
gcloud compute addresses list --global --project=boutique-gke \
  --filter="name:(boutique-ingress-ip OR argocd-ingress-ip)" \
  --format="table(name,address,status)"
```

### 2. Confirm DNS still points each hostname at its own IP

```bash
BOUTIQUE_IP="$(terraform output -raw ingress_static_ip)"
ARGOCD_IP="$(terraform output -raw argocd_ingress_static_ip)"
echo "Boutique expected: ${BOUTIQUE_IP}"
echo "Argo CD expected:  ${ARGOCD_IP}"
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
```

The two addresses must differ. If they match, topic 05 did not apply the dual-IP `ingress-edge` / `dns` modules.

### 3. Confirm committed ManagedCertificate for Argo CD

GKE requires the ManagedCertificate in the **same namespace** as the Ingress that references it. The Argo CD cert is already in Git (`gitops/bootstrap/argocd/managed-certificate.yaml`) — one domain, colocated with the Argo Ingress:

```yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: argocd-managed-cert
  namespace: argocd
spec:
  domains:
    - argocd.boutique.biroltilki.art
```

The Boutique cert (`boutique-managed-cert` in namespace `boutique`, domain `boutique.biroltilki.art` only) is created by Helm in topic 12. Do **not** put both hostnames on one certificate or one Ingress.

You may apply the Argo CD certificate after the `argocd` namespace exists (topic 09 creates it). Optional early apply:

```bash
kubectl apply -f gitops/bootstrap/argocd/namespace.yaml
kubectl apply -f gitops/bootstrap/argocd/managed-certificate.yaml
kubectl get managedcertificate -n argocd
kubectl describe managedcertificate argocd-managed-cert -n argocd
```

### 4. Confirm GCE Ingress annotations (already in Git)

`gitops/bootstrap/argocd/ingress.yaml` must match Terraform names. **Do not change these to `boutique-ingress-ip` or `boutique-managed-cert`.**

| Annotation                                    | Value                 |
| --------------------------------------------- | --------------------- |
| `kubernetes.io/ingress.class`                 | `gce`                 |
| `kubernetes.io/ingress.global-static-ip-name` | `argocd-ingress-ip`   |
| `networking.gke.io/managed-certificates`      | `argocd-managed-cert` |

Boutique Helm (`gitops/apps/boutique/values.yaml`) uses `staticIpName: boutique-ingress-ip` and `managedCertName: boutique-managed-cert`. TLS terminates at the load balancer; Argo CD server runs `insecure` HTTP behind Ingress (backend port **80** — topic 09 Helm values).

Do **not** apply the Argo CD Ingress until Argo CD is installed (topic 09).

### 5. How GCE Ingress and ManagedCertificate work together

| Component                                     | Role                                                                     |
| --------------------------------------------- | ------------------------------------------------------------------------ |
| `google_compute_global_address.ingress`       | Reserves IPv4 `boutique-ingress-ip`                                      |
| `google_compute_global_address.argocd`        | Reserves IPv4 `argocd-ingress-ip`                                        |
| `kubernetes.io/ingress.global-static-ip-name` | Binds that Ingress to the named global address                           |
| `ManagedCertificate` CR                       | Requests Google-managed TLS cert for listed domains (same namespace)     |
| `networking.gke.io/managed-certificates`      | Links Ingress to the certificate resource name                           |
| Cloud DNS A records                           | Each hostname must resolve to **its** Ingress IP before cert is `Active` |

Certificate provisioning flow:

```
DNS A → matching static IP → GCE LB on Ingress sync → Google validates domain → ManagedCertificate Active → HTTPS
```

### 6. Monitor certificate status (after topic 09 Ingress apply)

```bash
kubectl get managedcertificate -n argocd
kubectl describe managedcertificate argocd-managed-cert -n argocd
gcloud compute ssl-certificates list --project=boutique-gke
```

Wait until `Status` shows `Certificate Status: Active` (not `Provisioning`). Boutique cert appears after topic 12.

### 7. Validate HTTPS when ready (post topic 09 / 12)

```bash
curl -I https://argocd.boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
```

## Expected output

**`terraform output` (two different addresses):**

```
ingress_static_ip         = "35.xxx.xxx.xxx"
argocd_ingress_static_ip  = "34.xxx.xxx.xxx"
```

**`gcloud compute addresses list`:**

```
NAME                  ADDRESS         STATUS
argocd-ingress-ip     34.xxx.xxx.xxx  RESERVED
boutique-ingress-ip   35.xxx.xxx.xxx  RESERVED
```

**`kubectl get managedcertificate -n argocd` (after topic 09 apply, before Active):**

```
NAME                  AGE   STATUS
argocd-managed-cert   2m    Provisioning
```

**`kubectl describe managedcertificate argocd-managed-cert -n argocd` (when ready):**

```
Status:
  Certificate Name:    mcrt-xxxxx
  Certificate Status:  Active
  Domain Status:
    Domain:     argocd.boutique.biroltilki.art
    Status:     Active
```

**`curl -I https://argocd.boutique.biroltilki.art` (after topic 09 + cert Active):**

```
HTTP/2 200
```

or `HTTP/2 302` redirect to login — both indicate TLS success. No `SSL certificate problem` errors.

## Validation

```bash
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
gcloud compute addresses list --global --project=boutique-gke \
  --filter="name:(boutique-ingress-ip OR argocd-ingress-ip)" \
  --format="table(name,address)"
kubectl get managedcertificate -n argocd 2>/dev/null || echo "argocd namespace not created yet — complete topic 09"
kubectl describe ingress argocd-server -n argocd 2>/dev/null || echo "Ingress not applied yet — complete topic 09"
```

After topic 09:

```bash
curl -I https://argocd.boutique.biroltilki.art
```

Expected before topic 09:

- DNS returns the matching static IP for each hostname
- ManagedCertificate may show `Provisioning` or `Failed` if Ingress/backend not yet present — normal

Expected after topic 09 and cert Active:

- `curl -I` to Argo CD returns HTTP/2 without TLS errors
- `boutique.biroltilki.art` may return `502` until topic 12 deploys the storefront — TLS can still be valid after that topic

## Common problems

| Symptom                                   | Cause                                          | Fix                                                                     |
| ----------------------------------------- | ---------------------------------------------- | ----------------------------------------------------------------------- |
| ManagedCertificate `FailedNotVisible`     | DNS not pointing to **this** Ingress IP        | Re-check topic 05; Argo hostname must match `argocd-ingress-ip`         |
| Certificate stuck `Provisioning` > 60 min | Ingress not created or wrong static IP name    | Confirm annotation `argocd-ingress-ip`; apply Ingress in topic 09       |
| Both hostnames resolve to the same IP     | Single-IP Terraform leftover                   | Re-apply `module.ingress_edge` and `module.dns`; two addresses required |
| `404` or default backend                  | Ingress host rule mismatch                     | Ensure `spec.rules[].host` matches cert domain exactly                  |
| Wrong IP on LB                            | Typo in static IP annotation                   | `gcloud compute addresses list --global --project=boutique-gke`         |
| Cert in wrong namespace                   | ManagedCertificate not co-located with Ingress | Argo cert in `argocd`; Boutique cert in `boutique`                      |
| `curl` TLS error before topic 09          | No Ingress/backend yet                         | Expected — complete Argo CD bootstrap first                             |

## Recovery

**Delete and recreate ManagedCertificate (forces reprovision):**

```bash
kubectl delete managedcertificate argocd-managed-cert -n argocd
kubectl apply -f gitops/bootstrap/argocd/managed-certificate.yaml
```

**Release static IPs (teardown only — breaks DNS):**

```bash
cd terraform/environments/boutique
terraform destroy -target=module.dns -target=module.ingress_edge
```

Destroy DNS records **before** releasing IPs so A records are not left pointing at deleted addresses.

**Fix annotation drift on Argo CD Ingress:**

```bash
kubectl annotate ingress argocd-server -n argocd \
  kubernetes.io/ingress.global-static-ip-name=argocd-ingress-ip \
  networking.gke.io/managed-certificates=argocd-managed-cert \
  --overwrite
```

## Best practices

- One global static IP **per** public Ingress (Boutique and Argo CD)
- Keep certificate resources in Git (`gitops/bootstrap/argocd/managed-certificate.yaml`; Boutique via Helm)
- Wait for `Active` before announcing URLs to stakeholders
- Prefer Google-managed certs over cert-manager for GCE Ingress unless you need custom CAs
- Document certificate expiry — Google-managed certs auto-renew; monitor via `kubectl describe managedcertificate`

## Security notes

- TLS terminates at the Google Cloud load balancer for GCE Ingress (not in-cluster unless using SSL passthrough)
- Only list domains you control in ManagedCertificate `spec.domains`
- Each static IP is an edge choke point — pair with Cloud Armor (topic 15 storefront; `argocd-edge` in edge-hardening)
- Do not upload private keys to Kubernetes Secrets for these hostnames
- Audit Ingress changes via Git PR review; Argo CD manual sync (topic 09) prevents surprise exposure

## Next step

→ [07 — GitHub Workload Identity Federation](07-github-wif.md)

Topics 07–08 can proceed in parallel with finishing TLS validation. Complete topic 09 before expecting a working Argo CD HTTPS URL.
