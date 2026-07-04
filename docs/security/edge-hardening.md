# Edge hardening — Argo CD and Binary Authorization

## Purpose

Document post-bootstrap hardening applied after topic 16 smoke validation: **Binary Authorization enforce mode** and **Cloud Armor on Argo CD**.

## Binary Authorization — enforce mode

### What changes

| Mode                           | Behavior                                      |
| ------------------------------ | --------------------------------------------- |
| `DRYRUN_AUDIT_LOG_ONLY`        | Violations logged; deploys still succeed      |
| `ENFORCED_BLOCK_AND_AUDIT_LOG` | Unsigned/un-attested images blocked at deploy |

### Configuration

`terraform/environments/boutique/terraform.tfvars`:

```hcl
binary_authorization_enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"
```

Apply:

```bash
cd terraform/environments/boutique
terraform plan -target='module.binary_authorization[0]'
terraform apply -target='module.binary_authorization[0]'
```

Verify:

```bash
gcloud container binauthz policy export --project=boutique-gke | grep enforcementMode
```

### Platform image whitelists

Platform controllers (Argo CD, Kyverno, ESO, Redis) use upstream images not yet mirrored with cosign attestations. The `binary-authorization` module whitelists known platform registries via `platform_image_whitelist_patterns`.

**Boutique application images** in Artifact Registry are **not** whitelisted — they require cosign attestation from CI.

Extend platform mirroring ([mirror-platform-images.yml](../../.github/workflows/mirror-platform-images.yml)) to Argo CD/Kyverno/ESO, then remove corresponding whitelist patterns.

### Break-glass

Temporarily revert to dry-run per [setup/08-artifact-registry-binary-auth.md](../setup/08-artifact-registry-binary-auth.md) Recovery section.

## Argo CD — Cloud Armor edge

### Threat

`argocd.boutique.biroltilki.art` is a public admin surface. Without edge controls: brute-force login, OWASP attack patterns, no rate limiting.

### Policy `argocd-edge`

Terraform module `armor_argocd` creates:

| Rule (priority)    | Action                                                  |
| ------------------ | ------------------------------------------------------- |
| 500–501 (optional) | Allow admin CIDRs; deny all others                      |
| 1000–1001          | OWASP CRS SQLi + XSS deny (evaluated before rate limit) |
| 2000               | Rate limit 30 req/min/IP (ban 5 min)                    |
| 2147483647         | Default allow                                           |

### Apply

```bash
cd terraform/environments/boutique
terraform plan -target='module.armor_argocd[0]'
terraform apply -target='module.armor_argocd[0]'

chmod +x scripts/attach-argocd-armor.sh
./scripts/attach-argocd-armor.sh
```

### Optional IP allowlist

Restrict Argo CD to office/VPN only in `terraform.tfvars`:

```hcl
argocd_armor_allowed_cidrs = ["203.0.113.10/32"]
```

Re-apply Terraform. Traffic from other IPs receives `403`.

### Validation

```bash
gcloud compute backend-services list --project=boutique-gke --global \
  --filter='name~argocd' --format='table(name,securityPolicy.basename())'

curl -sI https://argocd.boutique.biroltilki.art | head -1

curl -s -o /dev/null -w "sqli %{http_code}\n" \
  "https://argocd.boutique.biroltilki.art/?id=1'%20OR%201=1--"
```

Expected: backend shows `argocd-edge`; normal traffic `200`; SQLi probe `403`.

## Troubleshooting

| Symptom                                   | Cause                                                         | Fix                                                                                                                                  |
| ----------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| SQLi probe returns `200` on Argo CD       | Rate-limit rule evaluated before CRS (priority 1000)          | CRS must be priority 1000–1001; rate limit at 2000 — see policy table above. Re-apply `module.armor_argocd` or fix rules via gcloud. |
| `terraform apply` fails on rule reorder   | GCP API conflict when changing priorities in one step         | Delete/recreate rules via gcloud (see topic 16 session notes) or apply in two steps; then `terraform apply` to sync state.           |
| Argo CD backend has no policy             | Ingress recreated new backend name                            | Re-run `./scripts/attach-argocd-armor.sh`                                                                                            |
| Helm install Argo CD fails (Kyverno deny) | Platform hooks blocked by `require-digest` / `require-probes` | Scale `kyverno-admission-controller` to 0, install Helm, scale back to 1                                                             |
| Binary Auth blocks platform pods          | Image not whitelisted                                         | Add pattern to `platform_image_whitelist_patterns` or mirror image to AR with cosign attestation                                     |
| Only `DRYRUN` on cluster rule             | `terraform.tfvars` not updated                                | Set `binary_authorization_enforcement_mode = "ENFORCED_BLOCK_AND_AUDIT_LOG"` and apply `module.binary_authorization[0]`              |

## Related

- [supply-chain.md](supply-chain.md)
- [setup/15-cloud-armor.md](../setup/15-cloud-armor.md)
- [setup/08-artifact-registry-binary-auth.md](../setup/08-artifact-registry-binary-auth.md)
