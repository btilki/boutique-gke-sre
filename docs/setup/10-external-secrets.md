# External Secrets Operator + Secret Manager

## Goal

Install External Secrets Operator (ESO) on the cluster, bind its Kubernetes service account to a GCP service account via **Workload Identity**, and apply a `ClusterSecretStore` that reads from **GCP Secret Manager**. Application teams will use `ExternalSecret` CRs — never plain `Secret` manifests in Git (enforced by Kyverno in topic 11).

> **Phase 4 gate:** Topics **09–11** must complete before treating the cluster as production-ready.

## Why this step is required

Online Boutique and platform components need runtime secrets (API keys, TLS material, integration tokens) without storing them in Git or in etcd as manually created Secrets. ESO watches `ExternalSecret` resources and materializes Kubernetes Secrets from Secret Manager at runtime.

This pattern pairs with Kyverno policy `block-plain-secrets` in `gitops/policies/kyverno/block-plain-secrets.yaml`: only ESO-managed secrets are allowed. Workload Identity eliminates JSON key files — the ESO controller authenticates to GCP using its Kubernetes service account identity.

## Prerequisites

- Prior guide: [09-argocd-bootstrap.md](09-argocd-bootstrap.md)
- GKE cluster with Workload Identity enabled (topic 04)
- APIs enabled: `secretmanager.googleapis.com`, `iam.googleapis.com`
- Tools: `kubectl`, `helm`, `gcloud`
- Access: `roles/iam.serviceAccountAdmin`, `roles/secretmanager.admin` (or least-privilege equivalents) on `boutique-gke`
- Cluster context set: `kubectl config current-context` points at `boutique-gke`

## Commands

### 1. Create the GCP service account for ESO

```bash
export PROJECT_ID=boutique-gke
export GSA_NAME=external-secrets
export GSA_EMAIL="${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
export KSA_NAMESPACE=external-secrets
export KSA_NAME=external-secrets

gcloud iam service-accounts create "${GSA_NAME}" \
  --project="${PROJECT_ID}" \
  --display-name="External Secrets Operator"

gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${GSA_EMAIL}" \
  --role="roles/secretmanager.secretAccessor"
```

Use a narrower custom role in production if you know the exact secret names ESO will read.

### 2. Install External Secrets Operator via Helm

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --version 0.14.2 \
  --set installCRDs=true \
  --wait \
  --timeout 10m
```

See `gitops/bootstrap/external-secrets/operator/README.md` for the canonical install reference.

### 3. Bind Workload Identity (GSA ↔ KSA)

Allow the Kubernetes service account to impersonate the GCP service account:

```bash
export PROJECT_ID=boutique-gke
export GSA_EMAIL="external-secrets@${PROJECT_ID}.iam.gserviceaccount.com"
export KSA_NAMESPACE=external-secrets
export KSA_NAME=external-secrets

gcloud iam service-accounts add-iam-policy-binding "${GSA_EMAIL}" \
  --project="${PROJECT_ID}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${KSA_NAMESPACE}/${KSA_NAME}]"
```

Annotate the ESO controller service account (Helm default name may be `external-secrets`; verify with `kubectl -n external-secrets get sa`):

```bash
kubectl annotate serviceaccount "${KSA_NAME}" \
  -n "${KSA_NAMESPACE}" \
  iam.gke.io/gcp-service-account="${GSA_EMAIL}" \
  --overwrite
```

Restart the controller so it picks up the annotation:

```bash
kubectl -n external-secrets rollout restart deployment external-secrets
kubectl -n external-secrets rollout status deployment external-secrets
```

### 4. Create a test secret in Secret Manager (no real credentials in Git)

```bash
echo -n "bootstrap-test-value" | gcloud secrets create boutique-eso-bootstrap-test \
  --project=boutique-gke \
  --replication-policy=automatic \
  --data-file=-
```

### 5. Apply the ClusterSecretStore

Confirm values in `gitops/bootstrap/external-secrets/cluster-secret-store.yaml` match your cluster:

| Field                         | Expected value     |
| ----------------------------- | ------------------ |
| `projectID`                   | `boutique-gke`     |
| `clusterLocation`             | `europe-west1`     |
| `clusterName`                 | `boutique-gke`     |
| `serviceAccountRef.name`      | `external-secrets` |
| `serviceAccountRef.namespace` | `external-secrets` |

Apply:

```bash
kubectl apply -f gitops/bootstrap/external-secrets/cluster-secret-store.yaml
```

### 6. Create a sample ExternalSecret (validation only)

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: eso-bootstrap-test
  namespace: boutique
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: gcp-secret-manager
  target:
    name: eso-bootstrap-test
    creationPolicy: Owner
  data:
    - secretKey: test-key
      remoteRef:
        key: boutique-eso-bootstrap-test
EOF
```

Create the `boutique` namespace first if it does not exist:

```bash
kubectl create namespace boutique --dry-run=client -o yaml | kubectl apply -f -
```

## Expected output

- Helm install: `STATUS: deployed`
- `kubectl -n external-secrets get pods` — all ESO pods `Running` (typically 3: controller, cert-controller, webhook)
- `kubectl get clustersecretstore gcp-secret-manager` — `Ready=True` in status
- `kubectl -n boutique get externalsecret eso-bootstrap-test` — `SecretSynced` / `Ready=True`
- `kubectl -n boutique get secret eso-bootstrap-test` — Secret exists with key `test-key`

Check sync status:

```bash
kubectl -n boutique describe externalsecret eso-bootstrap-test
```

## Validation

```bash
# ESO controller healthy
kubectl -n external-secrets get pods,deploy

# ClusterSecretStore ready
kubectl get clustersecretstore gcp-secret-manager -o yaml | grep -A3 conditions

# Secret materialized from Secret Manager
kubectl -n boutique get secret eso-bootstrap-test -o jsonpath='{.data.test-key}' | base64 -d && echo

# Workload Identity annotation present
kubectl -n external-secrets get sa external-secrets -o yaml | grep iam.gke.io
```

**Pass criteria:** `ClusterSecretStore` Ready; test `ExternalSecret` syncs without `AccessDenied` errors in controller logs.

## Common problems

| Symptom                                  | Cause                                                                | Fix                                                                                          |
| ---------------------------------------- | -------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `ClusterSecretStore` not Ready           | WI binding missing or wrong KSA name                                 | Re-run IAM binding; verify `kubectl get sa -n external-secrets`                              |
| `AccessDenied` on Secret Manager         | GSA lacks `secretAccessor`                                           | Add `roles/secretmanager.secretAccessor` to GSA                                              |
| `secret not found`                       | Wrong secret name in `remoteRef.key` or secret not created in step 4 | `gcloud secrets list --project=boutique-gke`; re-run step 4 or `gcloud secrets versions add` |
| ExternalSecret stuck `SecretSyncedError` | Namespace not allowed / store ref wrong                              | Confirm `kind: ClusterSecretStore` and store name                                            |
| Controller CrashLoop                     | CRDs not installed                                                   | Reinstall with `--set installCRDs=true`                                                      |
| Wrong cluster in store spec              | Typo in `clusterLocation` / `clusterName`                            | Match `terraform output cluster_name cluster_location`                                       |

## Recovery

- **Helm uninstall:** `helm uninstall external-secrets -n external-secrets` (removes operator; leaves synced Secrets until deleted)
- **Remove test resources:** `kubectl delete externalsecret eso-bootstrap-test -n boutique`; `gcloud secrets delete boutique-eso-bootstrap-test --project=boutique-gke`
- **Re-bind WI:** Re-apply IAM policy binding and SA annotation; restart deployment
- **ClusterSecretStore edit:** `kubectl apply -f` after fixing YAML; ESO reconciles automatically

## Best practices

- One `ClusterSecretStore` per GCP project; use `ExternalSecret` per app/namespace
- Name secrets in Secret Manager with a convention: `boutique/<service>/<key>`
- Set `refreshInterval` appropriately — secrets rarely need sub-minute rotation in this reference
- Manage GSA and WI bindings in Terraform when the `iam` module is wired (keep commands here as bootstrap reference)
- Delete bootstrap test secrets and ExternalSecrets after validation

## Security notes

- Never download GCP service account JSON keys for ESO — Workload Identity only
- Grant `secretAccessor` on specific secrets where possible instead of project-wide
- ESO-created Secrets live in etcd encrypted at rest (GKE default); restrict RBAC who can read Secrets
- Do not put secret values in setup guides, Git, or shell history — use Secret Manager console or `gcloud secrets versions add`
- Audit Secret Manager access via Cloud Audit Logs

## Next step

→ [Kyverno policies](11-kyverno-policies.md)
