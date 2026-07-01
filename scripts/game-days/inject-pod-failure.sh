#!/usr/bin/env bash
# Game day: inject pod failure — boutique-gke-sre
#
# SAFETY:
#   - Run only in the boutique-gke project during scheduled game days.
#   - Requires explicit confirmation (CONFIRM=yes) before destructive actions.
#   - Prefer a single pod in a non-critical replica set; avoid deleting all replicas.
#   - Document start/end time in the game-day log.
#
# Usage:
#   CONFIRM=yes NAMESPACE=boutique DEPLOYMENT=frontend ./inject-pod-failure.sh
#
set -euo pipefail

CONFIRM="${CONFIRM:-}"
NAMESPACE="${NAMESPACE:-boutique}"
DEPLOYMENT="${DEPLOYMENT:-frontend}"

if [[ "${CONFIRM}" != "yes" ]]; then
  echo "Refusing to run without CONFIRM=yes"
  echo "Example: CONFIRM=yes NAMESPACE=${NAMESPACE} DEPLOYMENT=${DEPLOYMENT} $0"
  exit 1
fi

echo "==> Target: deployment/${DEPLOYMENT} in namespace ${NAMESPACE}"
echo "==> Listing pods before injection..."
kubectl get pods -n "${NAMESPACE}" -l "app=${DEPLOYMENT}" -o wide

POD="$(kubectl get pods -n "${NAMESPACE}" -l "app=${DEPLOYMENT}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
if [[ -z "${POD}" ]]; then
  echo "No pod found for app=${DEPLOYMENT}; adjust DEPLOYMENT label selector."
  exit 1
fi

echo "==> Deleting pod ${POD} (Kubernetes will recreate)..."
kubectl delete pod -n "${NAMESPACE}" "${POD}" --wait=false

echo "==> Watch recovery: kubectl get pods -n ${NAMESPACE} -w"
echo "==> Validate storefront: curl -I https://boutique.biroltilki.art"
echo "Done. Revert: no action required — controller reconciles."
