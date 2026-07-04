#!/usr/bin/env bash
# Attach Cloud Armor policy argocd-edge to the GKE Ingress backend for Argo CD.
# Prerequisites:
#   - terraform apply created module.armor_argocd (policy argocd-edge)
#   - Argo CD Ingress running (kubectl -n argocd get ingress argocd-server)
set -euo pipefail

PROJECT="${PROJECT_ID:-boutique-gke}"
POLICY="${ARGOCD_ARMOR_POLICY:-argocd-edge}"

echo "=== Resolve Argo CD backend service ==="
BACKEND=$(gcloud compute backend-services list --project="${PROJECT}" --global \
  --filter='name~argocd.*argocd-server' --format='value(name)' | head -1)

if [[ -z "${BACKEND}" ]]; then
  echo "ERROR: No global backend service matching argocd-server. Is Argo CD Ingress applied?" >&2
  exit 1
fi
echo "Backend: ${BACKEND}"

if ! gcloud compute security-policies describe "${POLICY}" --project="${PROJECT}" >/dev/null 2>&1; then
  echo "ERROR: Security policy ${POLICY} not found. Run terraform apply for module.armor_argocd first." >&2
  exit 1
fi

echo "=== Attach ${POLICY} to ${BACKEND} ==="
gcloud compute backend-services update "${BACKEND}" \
  --project="${PROJECT}" \
  --security-policy="${POLICY}" \
  --global

echo "=== Verify ==="
gcloud compute backend-services describe "${BACKEND}" \
  --project="${PROJECT}" --global \
  --format='table(name,securityPolicy.basename())'

echo "=== Done ==="
echo "Test: curl -sI https://argocd.boutique.biroltilki.art | head -1"
