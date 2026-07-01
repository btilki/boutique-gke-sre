# ExternalSecret example

Minimal External Secrets Operator (ESO) pattern for boutique-gke-sre.

## Purpose

Demonstrate the ESO-only secrets pattern enforced by Kyverno (`block-plain-secrets`). **No real secret values** in this example.

## Prerequisites

- ESO installed ([docs/setup/10-external-secrets.md](../../docs/setup/10-external-secrets.md))
- ClusterSecretStore pointing at GCP Secret Manager
- Secret `boutique-example-config` created in Secret Manager (placeholder value)

## Files

| File | Purpose |
|------|---------|
| `sample-externalsecret.yaml` | ExternalSecret referencing Secret Manager key |

## Validation

```bash
kubectl apply --dry-run=client -f sample-externalsecret.yaml
# After apply (with real store):
kubectl get externalsecret -n boutique
```

## Security

Never commit Secret Manager values or Kubernetes Secret data. Use `dataFrom` or `remoteRef` only.

## Further reading

- [examples/README.md](../README.md)
- [gitops/bootstrap/external-secrets/](../../gitops/bootstrap/external-secrets/)
