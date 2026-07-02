#!/usr/bin/env bash
# Fail if values-images.yaml contains floating image tags instead of digest pins.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VALUES_FILE="${REPO_ROOT}/gitops/apps/boutique/values-images.yaml"

echo "==> digest-only check: ${VALUES_FILE}"

if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "FAIL: ${VALUES_FILE} not found"
  exit 1
fi

# Match explicit tag fields or :latest in image references (ignore comment lines).
if grep -v '^[[:space:]]*#' "${VALUES_FILE}" | grep -E ':latest|^[[:space:]]*tag:'; then
  echo "FAIL: floating tag found in values-images.yaml — use digest pins only"
  exit 1
fi

# Every image entry must declare a digest field with sha256.
digest_count="$(grep -c '^[[:space:]]*digest: sha256:' "${VALUES_FILE}" || true)"

if [[ "${digest_count}" -lt 1 ]]; then
  echo "FAIL: no sha256 digest pins found in values-images.yaml"
  exit 1
fi

echo "OK: digest-only (${digest_count} digest pin(s))"
