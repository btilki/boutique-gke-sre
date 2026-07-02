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
  "${REPO_ROOT}/observability"
)

for target in "${TARGETS[@]}"; do
  if [[ -d "${target}" ]]; then
    echo "--- ${target} ---"
    find "${target}" \( -name '*.yaml' -o -name '*.yml' \) | while read -r f; do
      kubeconform "${ARGS[@]}" "${f}" || exit 1
    done
  fi
done

echo "kubeconform validation complete."
