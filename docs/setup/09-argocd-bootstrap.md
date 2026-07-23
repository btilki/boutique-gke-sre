# Argo CD bootstrap

## Goal

Install Argo CD on the private GKE cluster, expose the UI at **`argocd.boutique.biroltilki.art`**, register the app-of-apps root Application (`gitops/bootstrap/root-app.yaml`), and confirm **manual sync** is the only promotion path. When this topic is complete, you can log in to Argo CD and see child Applications (policies, boutique, observability) in `OutOfSync` state awaiting deliberate sync.

> **Phase 4 gate:** Topics **09–11** (Argo CD, ESO, Kyverno) must complete before treating the cluster as production-ready. Do not deploy Online Boutique (topic 12) until the gate passes.

## Why this step is required

GitOps is the control plane for everything after infrastructure: Kyverno policies, NetworkPolicies, External Secrets, Online Boutique, and observability. Argo CD reconciles desired state from this repository against the live cluster. Manual sync (see [ADR 003](../adr/003-manual-argocd-sync.md)) adds a human review step between merge and production — appropriate for a reference SRE environment where every deploy is intentional.

Without Argo CD you would apply manifests by hand, bypassing audit trails, digest enforcement, and the single source of truth in `gitops/`.

## Prerequisites

- Prior guide: [08-artifact-registry-binary-auth.md](08-artifact-registry-binary-auth.md)
- GKE cluster reachable: topic [04-gke-cluster.md](04-gke-cluster.md)
- DNS and TLS ready: topics [05-cloud-dns.md](05-cloud-dns.md), [06-ingress-tls.md](06-ingress-tls.md)
- Tools: `kubectl`, `helm` (v3+), `gcloud`, `curl`, `dig`
- Access: `roles/container.clusterAdmin` (or equivalent) on project `boutique-gke`
- Repository cloned locally; you are at the repo root for all paths below
- Terraform outputs available (static IP name, cluster name):

```bash
cd terraform/environments/boutique
terraform output ingress_static_ip cluster_name cluster_location
```

Defaults used in this guide: cluster `boutique-gke`, region `europe-west1`, Argo CD static IP resource name `argocd-ingress-ip` (storefront uses `boutique-ingress-ip` in topic 12).

## Commands

### 1. Connect to the cluster

```bash
gcloud container clusters get-credentials boutique-gke \
  --region europe-west1 \
  --project boutique-gke

kubectl cluster-info
```

### 2. Create the Argo CD namespace

```bash
kubectl apply -f gitops/bootstrap/argocd/namespace.yaml
```

### 3. Add the Helm repository and install Argo CD

Create a minimal values file for GKE Ingress with a Google-managed certificate (TLS terminates at the load balancer; Argo CD server runs in insecure mode behind it):

```bash
cat > /tmp/argocd-values.yaml <<'EOF'
configs:
  params:
    server.insecure: true
server:
  service:
    type: ClusterIP
  ingress:
    enabled: false
EOF

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version 7.7.16 \
  -f /tmp/argocd-values.yaml \
  --wait \
  --timeout 10m
```

Pin the chart version to a known release; check [argo-helm releases](https://github.com/argoproj/argo-helm/releases) before upgrading in production.

### 4. Apply the Argo CD Ingress manifest

Verify annotations in `gitops/bootstrap/argocd/ingress.yaml` match your Terraform static IP and certificate names, then apply:

| Annotation                                    | Value                 |
| --------------------------------------------- | --------------------- |
| `kubernetes.io/ingress.class`                 | `gce`                 |
| `kubernetes.io/ingress.global-static-ip-name` | `argocd-ingress-ip`   |
| `networking.gke.io/managed-certificates`      | `argocd-managed-cert` |

Apply the managed certificate CR (if not already present) and Ingress:

```bash
kubectl apply -f gitops/bootstrap/argocd/managed-certificate.yaml
kubectl apply -f gitops/bootstrap/argocd/ingress.yaml
```

### 5. Retrieve the initial admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

Save this password securely. It is shown once; change it after first login or configure SSO for long-term use.

### 6. Register the root app-of-apps

Update `gitops/bootstrap/root-app.yaml` so `spec.source.repoURL` matches your fork (default: `https://github.com/btilki/boutique-gke-sre`), then apply:

```bash
kubectl apply -f gitops/bootstrap/root-app.yaml
```

### 7. Confirm manual sync (no auto-sync)

The root Application and all child apps in `gitops/apps/argocd-apps/` intentionally omit `syncPolicy.automated`. Verify:

```bash
kubectl -n argocd get application boutique-root -o yaml | grep -A5 syncPolicy
```

You should see `syncOptions` only — no `automated:` block.

### 8. Log in via CLI (optional)

```bash
# Install argocd CLI: https://argo-cd.readthedocs.io/en/stable/cli_installation/
argocd login argocd.boutique.biroltilki.art \
  --username admin \
  --password '<initial-password>' \
  --grpc-web

argocd app list
```

Do **not** sync child applications yet — topics 10–11 install prerequisites first.

## Expected output

- `helm upgrade --install` ends with `STATUS: deployed`
- `kubectl -n argocd get pods` shows `argocd-server`, `argocd-repo-server`, `argocd-application-controller` pods `Running`
- `kubectl -n argocd get ingress argocd-server` shows an address (may take 5–15 minutes)
- `argocd app list` (or UI) shows `boutique-root` with status `OutOfSync` / `Healthy` or `Missing` until you manually sync in a later topic
- `curl -I `argocd.boutique.biroltilki.art`` returns `HTTP/2 200` or `302` after the managed certificate becomes `Active`

Check certificate status:

```bash
kubectl -n argocd describe managedcertificate argocd-managed-cert
```

## Validation

```bash
# DNS resolves to the Terraform static IP
dig +short argocd.boutique.biroltilki.art

# HTTPS responds without certificate errors
curl -I https://argocd.boutique.biroltilki.art

# Control plane healthy
kubectl -n argocd get pods
kubectl -n argocd get application boutique-root

# Initial admin secret exists (delete after password change)
kubectl -n argocd get secret argocd-initial-admin-secret
```

**Pass criteria:** Argo CD UI loads over HTTPS; `boutique-root` Application exists; no automated syncPolicy on root or child apps; all Argo CD pods Running.

## Common problems

| Symptom                             | Cause                                                                | Fix                                                                                                                                   |
| ----------------------------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| `connection refused` on Argo CD URL | Ingress or managed cert not ready                                    | Wait 15–60 min; check `ManagedCertificate` status is `Active`                                                                         |
| TLS error / wrong certificate       | DNS not pointing at static IP                                        | Compare `dig +short` output to `terraform output ingress_static_ip`                                                                   |
| `502 Bad Gateway` on Argo CD URL    | `server.insecure` not set while using HTTP backend on Ingress        | Ensure `configs.params.server.insecure: true` in Helm values                                                                          |
| `boutique-root` `InvalidSpecError`  | Wrong `repoURL` or private repo without credentials                  | Set correct Git URL; add repo credentials via Argo CD UI or `argocd repo add`                                                         |
| `authentication required` on sync   | `repoURL` points at wrong GitHub org (e.g. `biroltilki` vs `btilki`) | Set `https://github.com/btilki/boutique-gke-sre` in `root-app.yaml` and child apps; `kubectl apply -f gitops/bootstrap/root-app.yaml` |
| Helm install timeout                | API server slow or insufficient nodes                                | `kubectl get events -n argocd`; increase `--timeout`; verify node pool                                                                |
| Cannot decode admin password        | Secret not created yet                                               | Wait for `argocd-server` pod Ready; re-run secret get command                                                                         |

## Recovery

- **Helm rollback:** `helm rollback argocd -n argocd`
- **Full reinstall:** `helm uninstall argocd -n argocd` then re-run install steps; re-apply Ingress and root Application
- **Remove root app only:** `kubectl -n argocd delete application boutique-root` (does not delete child resources already synced)
- **Lost admin password:** delete `argocd-initial-admin-secret`, restart `argocd-server`, or patch admin password via `argocd account update-password`

Always confirm cluster state with `kubectl -n argocd get all` before retrying.

## Best practices

- Pin Helm chart versions; upgrade Argo CD in a maintenance window with a rollback plan
- Change the default `admin` password immediately; plan SSO (OIDC) for long-term production
- Keep `syncPolicy.automated` disabled — manual sync is an intentional control ([ADR 003](../adr/003-manual-argocd-sync.md))
- Store bootstrap manifests in `gitops/bootstrap/argocd/`; never `kubectl apply` one-off YAML that is not in Git
- Use `argocd app diff boutique-root` before the first manual sync in later topics

## Security notes

- Argo CD admin credentials are cluster secrets — never commit passwords to Git
- Restrict Argo CD UI access: consider IAP or IP allowlisting in addition to HTTPS
- Argo CD repo credentials (if private fork) belong in Kubernetes Secrets or ESO `ExternalSecret`, not in shell history
- Enable audit logging for Argo CD API actions in production environments
- The initial admin secret should be deleted after password rotation

## Next step

→ [External Secrets Operator + Secret Manager](10-external-secrets.md)
