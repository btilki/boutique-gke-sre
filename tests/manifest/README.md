# Manifest validation

Kubernetes manifest schema checks (kubeconform / kubeval).

Validates:

- Static YAML under `gitops/bootstrap`, `gitops/policies`, and `observability`
- Rendered Helm output for `gitops/apps/boutique` (`values.yaml` + `values-images.yaml`)

Requires `kubeconform` and `helm` on `PATH`.

```bash
./tests/manifest/kubeconform.sh
```
