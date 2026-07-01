#!/usr/bin/env bash
# Pre-destroy checklist — boutique-gke-sre
#
# Run before terraform destroy or project teardown.
# Does not delete resources; only verifies safe state.
#
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-boutique-gke}"
REGION="${REGION:-europe-west1}"

echo "==> Pre-destroy checklist for project ${PROJECT_ID}"
echo ""

FAIL=0

check() {
  local desc="$1"
  local cmd="$2"
  echo -n "  [ ] ${desc}... "
  if eval "${cmd}" >/dev/null 2>&1; then
    echo "ATTENTION (resource may still exist)"
    FAIL=1
  else
    echo "OK (none / not found)"
  fi
}

echo "1. Confirm backups exported (GKE Backup / Velero) — manual step"
echo "2. Confirm Argo CD apps scaled or removed — manual step"
echo "3. Scanning for common orphan-prone resources..."

check "GKE clusters" "gcloud container clusters list --project=${PROJECT_ID} --format='value(name)' | grep -q ."
check "Global addresses" "gcloud compute addresses list --project=${PROJECT_ID} --global --format='value(name)' | grep -q ."
check "DNS managed zones" "gcloud dns managed-zones list --project=${PROJECT_ID} --format='value(name)' | grep -q ."
check "Artifact Registry repos" "gcloud artifacts repositories list --project=${PROJECT_ID} --format='value(name)' | grep -q ."

echo ""
if [[ "${FAIL}" -eq 0 ]]; then
  echo "Checklist scan complete. Review manual steps in docs/teardown.md before destroy."
else
  echo "Resources still present — follow destroy order in docs/teardown.md"
fi

exit "${FAIL}"
