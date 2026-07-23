# Static ingress IP and TLS (managed certificates)

## Goal

The global static IP `boutique-ingress-ip` is reserved and attached to GCE Ingress resources via annotation. A GKE **ManagedCertificate** covers `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art` with **TLS** (**Transport Layer Security**). Ingress manifests reference the static IP name and certificate name. After Argo CD ingress sync (topic 09), both hostnames serve valid HTTPS.

## Why this step is required

Public traffic reaches the cluster through a Google Cloud external HTTP(S) load balancer. A **global static IP** ensures DNS A records (topic 05) remain stable across Ingress reconciles. **Google-managed certificates** provision automatically when DNS points at the load balancer and the ManagedCertificate CR is Active. This avoids manual TLS secret management and aligns with GKE Ingress best practices.

HTTPS will **not** work end-to-end until topic 09 syncs the Argo CD Ingress with the annotations below and the ManagedCertificate reaches `Active` status (often 15–60 minutes after DNS and Ingress are correct).

## Prerequisites

- Prior guide: [05 — Cloud DNS and registrar NS delegation](05-cloud-dns.md) — both hostnames resolve to the static IP
- Tools: `kubectl`, `gcloud`, `curl`, `dig`
- Access: `kubectl` to cluster `boutique-gke`; permission to apply manifests in `argocd` namespace
- Repository paths: `gitops/bootstrap/argocd/ingress.yaml`, Terraform `module.ingress_edge`

## Commands

### 1. Confirm static IP from Terraform

```bash
gcloud config set project boutique-gke
cd terraform/environments/boutique
terraform output ingress_static_ip
terraform output -raw ingress_static_ip
```

Verify the GCP resource exists:

```bash
gcloud compute addresses describe boutique-ingress-ip \
  --global \
  --project=boutique-gke \
  --format='yaml(name,address,status)'
```

### 2. Confirm DNS still points at the static IP

```bash
STATIC_IP="$(terraform output -raw ingress_static_ip)"
echo "Expected: ${STATIC_IP}"
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
```

### 3. Create ManagedCertificate for both domains

GKE requires the ManagedCertificate in the **same namespace** as the Ingress that references it. Create the certificate in `argocd` for the Argo CD Ingress (topic 09). For the boutique storefront, you will create a matching certificate in the boutique namespace during topic 12; this guide establishes the pattern and the shared domain list.

Save the following as `gitops/bootstrap/argocd/managed-certificate.yaml` (or apply directly):

```yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: boutique-managed-cert
  namespace: argocd
  labels:
    app.kubernetes.io/part-of: boutique-gke-sre
spec:
  domains:
    - boutique.biroltilki.art
    - argocd.boutique.biroltilki.art
```

Apply the ManagedCertificate (namespace `argocd` must exist — created in topic 09 if not present yet; you may create the namespace early):

```bash
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f gitops/bootstrap/argocd/managed-certificate.yaml
kubectl get managedcertificate -n argocd
kubectl describe managedcertificate boutique-managed-cert -n argocd
```

### 4. Configure GCE Ingress annotations for Argo CD

Update `gitops/bootstrap/argocd/ingress.yaml` so the `metadata.annotations` block includes:

```yaml
kubernetes.io/ingress.global-static-ip-name: boutique-ingress-ip
networking.gke.io/managed-certificates: boutique-managed-cert
```

Full reference manifest (commit after uncommenting/setting annotations):

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  namespace: argocd
  annotations:
    kubernetes.io/ingress.global-static-ip-name: boutique-ingress-ip
    networking.gke.io/managed-certificates: boutique-managed-cert
  labels:
    app.kubernetes.io/name: argocd-server
    app.kubernetes.io/part-of: argocd
spec:
  ingressClassName: gce
  rules:
    - host: argocd.boutique.biroltilki.art
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 443
```

Do **not** apply the Ingress until Argo CD is installed (topic 09). This topic prepares Git manifests and the ManagedCertificate CR.

### 5. How GCE Ingress and ManagedCertificate work together

| Component                                           | Role                                                                    |
| --------------------------------------------------- | ----------------------------------------------------------------------- |
| `google_compute_global_address.ingress` (Terraform) | Reserves IPv4 address `boutique-ingress-ip`                             |
| `kubernetes.io/ingress.global-static-ip-name`       | Tells GKE Ingress controller to bind that named global address          |
| `ManagedCertificate` CR                             | Requests Google-managed TLS cert for listed domains                     |
| `networking.gke.io/managed-certificates`            | Links Ingress to certificate resource name in the same namespace        |
| Cloud DNS A records                                 | Must point both hostnames at the static IP before cert becomes `Active` |

Certificate provisioning flow:

```
DNS A → static IP → GCE LB created on Ingress sync → Google validates domain → ManagedCertificate Active → HTTPS on LB
```

### 6. Monitor certificate status (after topic 09 Ingress apply)

```bash
kubectl get managedcertificate -n argocd
kubectl describe managedcertificate boutique-managed-cert -n argocd
gcloud compute ssl-certificates list --project=boutique-gke
```

Wait until `Status` shows `Certificate Status: Active` (not `Provisioning`).

### 7. Validate HTTPS when ready (post topic 09)

```bash
curl -I https://argocd.boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
```

## Expected output

**`terraform output ingress_static_ip`:**

```
"35.xxx.xxx.xxx"
```

**`gcloud compute addresses describe boutique-ingress-ip`:**

```yaml
address: 35.xxx.xxx.xxx
name: boutique-ingress-ip
status: RESERVED
```

**`kubectl get managedcertificate -n argocd` (after apply, before Active):**

```
NAME                    AGE   STATUS
boutique-managed-cert   2m    Provisioning
```

**`kubectl describe managedcertificate boutique-managed-cert -n argocd` (when ready):**

```
Status:
  Certificate Name:    mcrt-xxxxx
  Certificate Status:  Active
  Domain Status:
    Domain:     argocd.boutique.biroltilki.art
    Status:     Active
    Domain:     boutique.biroltilki.art
    Status:     Active
```

**`curl -I `argocd.boutique.biroltilki.art`` (after topic 09 + cert Active):**

```
HTTP/2 200
```

or `HTTP/2 302` redirect to login — both indicate TLS success. No `SSL certificate problem` errors.

## Validation

```bash
dig +short boutique.biroltilki.art
dig +short argocd.boutique.biroltilki.art
kubectl get managedcertificate -n argocd
kubectl describe ingress argocd-server -n argocd 2>/dev/null || echo "Ingress not applied yet — complete topic 09"
```

After topic 09:

```bash
curl -I https://argocd.boutique.biroltilki.art
curl -I https://boutique.biroltilki.art
```

Expected before topic 09:

- DNS returns static IP
- ManagedCertificate may show `Provisioning` or `Failed` if Ingress/backend not yet present — normal

Expected after topic 09 and cert Active:

- `curl -I` returns HTTP/2 without TLS errors
- `boutique.biroltilki.art` may return `502` until topic 12 deploys the storefront — TLS can still be valid

## Common problems

| Symptom                                   | Cause                                          | Fix                                                                                                  |
| ----------------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| ManagedCertificate `FailedNotVisible`     | DNS not pointing to LB IP                      | Re-check topic 05; wait for DNS propagation                                                          |
| Certificate stuck `Provisioning` > 60 min | Ingress not created or wrong static IP name    | Confirm annotation `boutique-ingress-ip` matches Terraform `address_name`; apply Ingress in topic 09 |
| `404` or default backend                  | Ingress host rule mismatch                     | Ensure `spec.rules[].host` matches cert domain exactly                                               |
| Wrong IP on LB                            | Typo in static IP annotation                   | `gcloud compute addresses list --global --project=boutique-gke`                                      |
| Cert in wrong namespace                   | ManagedCertificate not co-located with Ingress | Create CR in same namespace as Ingress (`argocd`)                                                    |
| `curl` TLS error before topic 09          | No Ingress/backend yet                         | Expected — complete Argo CD bootstrap first                                                          |

## Recovery

**Delete and recreate ManagedCertificate (forces reprovision):**

```bash
kubectl delete managedcertificate boutique-managed-cert -n argocd
kubectl apply -f gitops/bootstrap/argocd/managed-certificate.yaml
```

**Release static IP (teardown only — breaks DNS):**

```bash
cd terraform/environments/boutique
terraform destroy -target=module.ingress_edge
```

**Fix annotation drift on Ingress:**

```bash
kubectl annotate ingress argocd-server -n argocd \
  kubernetes.io/ingress.global-static-ip-name=boutique-ingress-ip \
  networking.gke.io/managed-certificates=boutique-managed-cert \
  --overwrite
```

## Best practices

- Use one global static IP for both hostnames; route by `Host` header on the shared GCE load balancer
- Keep certificate resources in Git (`gitops/bootstrap/argocd/managed-certificate.yaml`)
- Wait for `Active` before announcing URLs to stakeholders
- Prefer Google-managed certs over cert-manager for GCE Ingress unless you need custom CAs
- Document certificate expiry — Google-managed certs auto-renew; monitor via `kubectl describe managedcertificate`

## Security notes

- TLS terminates at the Google Cloud load balancer for GCE Ingress (not in-cluster unless using SSL passthrough)
- Only list domains you control in ManagedCertificate `spec.domains`
- Static IP is a shared choke point — pair with Cloud Armor (topic 15) for edge protection
- Do not upload private keys to Kubernetes Secrets for these hostnames
- Audit Ingress changes via Git PR review; Argo CD manual sync (topic 09) prevents surprise exposure

## Next step

→ [07 — GitHub Workload Identity Federation](07-github-wif.md)

Topics 07–08 can proceed in parallel with finishing TLS validation. Complete topic 09 before expecting a working Argo CD HTTPS URL.
