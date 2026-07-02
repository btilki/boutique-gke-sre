# Manifest validation

Kubernetes manifest schema checks (kubeconform / kubeval).

Validates:

- Static YAML under `gitops/bootstrap`, `gitops/policies`, and `observability`
- Rendered Helm output for `gitops/apps/boutique` (`values.yaml` + `values-images.yaml`)
- Digest-only pins in `gitops/apps/boutique/values-images.yaml`
- Kyverno admission rules against rendered Boutique chart (`boutique-kyverno.sh`)

Requires `kubeconform`, `helm`, and `kyverno` on `PATH` for full local runs.

```bash
./tests/manifest/kubeconform.sh
./tests/manifest/digest-only.sh
./tests/manifest/boutique-kyverno.sh
```
