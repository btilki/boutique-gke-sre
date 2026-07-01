#!/usr/bin/env bash
# Orphan resource scan — boutique-gke-sre
#
# Lists GCP resources that commonly survive a partial teardown.
# Read-only; safe to run anytime.
#
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-boutique-gke}"

echo "==> Orphan resource scan: ${PROJECT_ID}"
echo ""

scan() {
  local title="$1"
  shift
  echo "--- ${title} ---"
  if output="$("$@" 2>&1)"; then
    if [[ -n "${output}" ]]; then
      echo "${output}"
    else
      echo "(none)"
    fi
  else
    echo "(error or API disabled)"
  fi
  echo ""
}

scan "GKE clusters" \
  gcloud container clusters list --project="${PROJECT_ID}" --format="table(name,location,status)"

scan "Compute instances" \
  gcloud compute instances list --project="${PROJECT_ID}" --format="table(name,zone,status)"

scan "Global static IPs" \
  gcloud compute addresses list --project="${PROJECT_ID}" --global --format="table(name,address,status)"

scan "Regional addresses" \
  gcloud compute addresses list --project="${PROJECT_ID}" --format="table(name,region,address,status)"

scan "Cloud DNS zones" \
  gcloud dns managed-zones list --project="${PROJECT_ID}" --format="table(name,dnsName,visibility)"

scan "Artifact Registry repositories" \
  gcloud artifacts repositories list --project="${PROJECT_ID}" --format="table(name,location,format)"

scan "Service accounts (custom)" \
  gcloud iam service-accounts list --project="${PROJECT_ID}" --format="table(email,displayName)" \
    | grep -v '@appspot.gserviceaccount.com' || true

scan "GCS buckets" \
  gcloud storage buckets list --project="${PROJECT_ID}" --format="table(name,location)" 2>/dev/null \
    || gsutil ls -p "${PROJECT_ID}" 2>/dev/null || echo "(none or no access)"

scan "Secret Manager secrets" \
  gcloud secrets list --project="${PROJECT_ID}" --format="table(name,createTime)"

echo "==> Compare with docs/teardown.md destroy order. Re-run after terraform destroy."
