#!/usr/bin/env bash
# kubeconform manifest schema validation stub — boutique-gke-sre
#
# Validates Kubernetes YAML under gitops/ against upstream schemas.
# Install: https://github.com/yannh/kubeconform
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCHEMA_DIR="${SCHEMA_DIR:-}"

echo "==> kubeconform manifest validation"
command -v kubeconform >/dev/null || {
  echo "kubeconform not installed; see https://github.com/yannh/kubeconform"
  exit 1
}

ARGS=(
  -summary
  -ignore-missing-schemas
  -kubernetes-version 1.29.0
)

if [[ -n "${SCHEMA_DIR}" ]]; then
  ARGS+=(-schema-location "${SCHEMA_DIR}")
else
  ARGS+=(-schema-location default)
fi

TARGETS=(
  "${REPO_ROOT}/gitops/bootstrap"
  "${REPO_ROOT}/gitops/policies"
)

for target in "${TARGETS[@]}"; do
  if [[ -d "${target}" ]]; then
    echo "--- ${target} ---"
    find "${target}" \( -name '*.yaml' -o -name '*.yml' \) | while read -r f; do
      kubeconform "${ARGS[@]}" "${f}" || exit 1
    done
  fi
done

# observability/ mixes Kustomize resources with reference YAML (monitoring/, images.yaml).
# Validate only what Argo CD applies: rendered Kustomize output.
OBSERVABILITY="${REPO_ROOT}/observability"
if [[ -d "${OBSERVABILITY}" ]]; then
  echo "--- kubectl kustomize observability ---"
  command -v kubectl >/dev/null || {
    echo "kubectl not installed; required for observability kustomize validation"
    exit 1
  }
  kubectl kustomize "${OBSERVABILITY}" | kubeconform "${ARGS[@]}" - || exit 1
fi

# Rendered Helm charts — values-images.yaml must contain real digest pins for a valid render.
HELM_CHARTS=(
  "${REPO_ROOT}/gitops/apps/boutique"
)

command -v helm >/dev/null || {
  echo "helm not installed; required for Helm chart validation"
  exit 1
}

for chart in "${HELM_CHARTS[@]}"; do
  if [[ -f "${chart}/Chart.yaml" ]]; then
    chart_name="$(basename "${chart}")"
    echo "--- helm template ${chart_name} ---"
    helm template "${chart_name}" "${chart}" \
      -f "${chart}/values.yaml" \
      -f "${chart}/values-images.yaml" \
      | kubeconform "${ARGS[@]}" - || exit 1
  fi
done

echo "kubeconform validation complete."
