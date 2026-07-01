#!/usr/bin/env bash
# Validate local prerequisites before bootstrap.
set -euo pipefail

echo "==> Checking tools..."
for cmd in gcloud terraform kubectl helm; do
  command -v "${cmd}" >/dev/null || { echo "Missing: ${cmd}"; exit 1; }
  echo "  OK ${cmd}"
done

echo "==> Checking gcloud auth..."
gcloud auth list --filter=status:ACTIVE --format='value(account)' | head -1

echo "==> Checking project (set boutique-gke or export PROJECT_ID)..."
PROJECT_ID="${PROJECT_ID:-boutique-gke}"
gcloud projects describe "${PROJECT_ID}" --format='value(projectId)' 2>/dev/null || {
  echo "Cannot describe project ${PROJECT_ID}"
  exit 1
}

echo "Prerequisites OK."
