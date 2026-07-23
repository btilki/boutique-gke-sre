# Supply chain and platform security

## Purpose

Document DevSecOps controls for boutique-gke-sre: authentication, secrets, images, admission policy, and network segmentation.

## When to use

- Security review or architecture walkthrough
- Implementing Phases 3–4 (**WIF** (**Workload Identity Federation**), **ESO** (**External Secrets Operator**), Kyverno, NetworkPolicy)
- Debugging deploy denials

## Prerequisites

- [architecture/overview.md](../architecture/overview.md) §9
- [threat-model.md](threat-model.md)

## Architecture

```
CI (WIF) → Trivy → AR → cosign → PR digest → Argo sync
  → Binary Authorization → Kyverno → NetworkPolicy → workload
Secrets: Secret Manager → ESO → Pod (never plain Secret in Git)
```

Pipeline uses **AR** (**Artifact Registry**) for images and **BA** (**Binary Authorization**) at deploy time.

## WIF authentication (no JSON keys)

- GitHub OIDC → GCP Workload Identity Federation pool/provider
- Short-lived tokens per workflow run
- Attribute condition: repository `ORG/boutique-gke-sre`, ref `refs/heads/main` for prod pipeline
- **Never** document or commit SA key download steps

→ [setup/07-github-wif.md](../setup/07-github-wif.md) · [iam-matrix.md](iam-matrix.md) · [ADR 002](../adr/002-wif-over-sa-keys.md)

## ESO → Secret Manager

- Secret values live in Secret Manager only
- `ExternalSecret` CRs reference secret names/versions
- Kyverno blocks plain `Secret` resources without ESO management labels
- **Rotation:** add Secret Manager version → ESO `refreshInterval` picks up (or force reconcile)

→ [setup/10-external-secrets.md](../setup/10-external-secrets.md) · [examples/external-secret/](../../examples/external-secret/)

## Digest-only images

- Helm values use `image@sha256:...` in `gitops/apps/boutique/values-images.yaml`
- CI opens PR with digest updates only
- Kyverno `require-digest` rejects `:latest` and missing digest

→ [setup/12-boutique-deploy.md](../setup/12-boutique-deploy.md) (§0 bootstrap) · [build-scan-sign.yml](../../.github/workflows/build-scan-sign.yml) · [require-digest.yaml](../../gitops/policies/kyverno/require-digest.yaml)

## Binary Authorization

- Deploy-time: only cosign-signed + attested images from Artifact Registry
- Attestor bound to CI service account
- **Enforce mode:** `ENFORCED_BLOCK_AND_AUDIT_LOG` after topic 16 (see [edge-hardening.md](edge-hardening.md))
- Platform controller images whitelisted until mirrored to AR with attestations
- **Break-glass:** documented in runbook only for emergencies — not normal ops

→ [setup/08-artifact-registry-binary-auth.md](../setup/08-artifact-registry-binary-auth.md) · [edge-hardening.md](edge-hardening.md)

## Kyverno minimum policies

1. Reject `:latest`; require digest
2. Require liveness + readiness probes
3. Require CPU/memory requests and limits
4. Require NetworkPolicy compliance labels (`network-policy.biroltilki.art/tier` on namespaces)
5. Block plain Secret resources (ESO-only)

Tests: `make kyverno-test` · `tests/kyverno/` · CI jobs `kyverno` + `manifests` in `.github/workflows/ci.yml`

## NetworkPolicy default-deny

- Default deny ingress and egress per namespace
- Explicit allows: ingress controller → frontend; service graph inside `boutique`
- Labels enforced by Kyverno policy #4

→ [gitops/policies/network-policies/](../../gitops/policies/network-policies/)

## Step-by-step implementation

Implement in phase order: WIF (7) → AR/Binary Auth (8) → ESO (10) → Kyverno + NetPol (11) → Boutique (12).

## Validation

```bash
# Kyverno deny test fixture
kubectl apply -f examples/kyverno-policy-test/bad-latest-pod.yaml  # expect deny

# No SA keys in repo
pre-commit run gitleaks --all-files
```

## Troubleshooting

| Symptom            | Cause                  | Fix                                                         |
| ------------------ | ---------------------- | ----------------------------------------------------------- |
| Image denied       | Binary Auth / Kyverno  | [kyverno-denials.md](../troubleshooting/kyverno-denials.md) |
| Secret not mounted | ESO / WI binding       | Check ExternalSecret status                                 |
| CI auth fail       | WIF attribute mismatch | [07-github-wif.md](../setup/07-github-wif.md)               |

## Common mistakes

- Pushing `:latest` to cluster bypassing Git
- Creating `kubectl create secret` for app config

## Best practices

- gitleaks + pre-commit on every PR
- Policy tests in CI before merge

## Production considerations

- Binary Auth misconfiguration blocks all deploys — test enforce mode after smoke validation
- Cloud Armor on storefront ([15-cloud-armor.md](../setup/15-cloud-armor.md)) and Argo CD ([edge-hardening.md](edge-hardening.md))

## Security considerations

- Cloud Audit Logs for IAM and Secret Manager access
- Least privilege on CI SA — only AR writer + signer roles needed

## Further reading

- [SECURITY.md](../../SECURITY.md)
- [CONTRIBUTING.md](../../CONTRIBUTING.md)
- [setup/11-kyverno-policies.md](../setup/11-kyverno-policies.md)
