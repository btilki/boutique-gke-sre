#!/usr/bin/env bash
# Apply Kyverno ClusterPolicies to rendered Online Boutique Helm manifests.
# Ensures the chart passes digest, probe, resource, and related admission rules.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART="${REPO_ROOT}/gitops/apps/boutique"
POLICIES="${REPO_ROOT}/gitops/policies/kyverno"
RENDERED="$(mktemp)"

cleanup() {
  rm -f "${RENDERED}"
}
trap cleanup EXIT

command -v helm >/dev/null || {
  echo "helm not installed; required for Boutique Kyverno validation"
  exit 1
}
command -v kyverno >/dev/null || {
  echo "kyverno CLI not installed; see https://kyverno.io/docs/kyverno-cli/"
  exit 1
}

echo "==> Boutique Helm chart Kyverno policy validation"
helm template boutique "${CHART}" \
  -f "${CHART}/values.yaml" \
  -f "${CHART}/values-images.yaml" \
  > "${RENDERED}"

echo "--- kyverno apply (rendered chart) ---"
kyverno apply "${POLICIES}/" --resource="${RENDERED}"

echo "Boutique chart Kyverno validation complete."
