#!/usr/bin/env bash
# Create Argo CD HTTPS uptime check (topic 18).
# Does not replace create-uptime-check.sh (storefront + initial alert policy).
# After create: attach this check_id as a second OR condition on uptime-check-failed
# (Console or Monitoring API). Reference: observability/monitoring/uptime-checks/argocd-ui.yaml
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/runbooks.sh
source "${SCRIPT_DIR}/lib/runbooks.sh"

PROJECT="${PROJECT_ID:-boutique-gke}"
HOST="argocd.boutique.biroltilki.art"
DISPLAY_NAME="argocd-ui"
PATH_CHECK="/healthz"
RUNBOOK="$(runbook_github_url uptime-check-failed)"

echo "=== Creating uptime check: ${DISPLAY_NAME} (${HOST}${PATH_CHECK}) ==="
gcloud monitoring uptime create "${DISPLAY_NAME}" \
  --project="${PROJECT}" \
  --resource-type=uptime-url \
  --resource-labels="host=${HOST},project_id=${PROJECT}" \
  --protocol=https \
  --path="${PATH_CHECK}" \
  --port=443 \
  --period=5 \
  --timeout=10 \
  --validate-ssl=true \
  --regions=usa-iowa,europe,asia-pacific

echo "=== Fetching uptime check ID ==="
CHECK_ID=$(gcloud monitoring uptime list-configs --project="${PROJECT}" --format=json | python3 -c "
import json, sys
configs = json.load(sys.stdin)
for c in configs:
    if c.get('displayName') == '${DISPLAY_NAME}':
        print(c['name'].split('/')[-1])
        break
")

if [[ -z "${CHECK_ID}" ]]; then
  echo "ERROR: could not find uptime check ID for ${DISPLAY_NAME}" >&2
  exit 1
fi

echo "Check ID: ${CHECK_ID}"
echo ""
echo "Next steps:"
echo "  1. GCP Console → Monitoring → Alerting → policy uptime-check-failed"
echo "  2. Add OR condition: uptime check failed for check_id=${CHECK_ID} (same threshold/duration as storefront)"
echo "  3. Confirm documentation mentions both hosts; runbook: ${RUNBOOK}"
echo "  4. Attach PagerDuty if missing: ./scripts/attach-pagerduty-channel.sh"
echo ""
echo "Validate:"
echo "  gcloud monitoring uptime list-configs --project=${PROJECT} --format='table(displayName,httpCheck.path,period)'"
echo "  curl -I https://${HOST}${PATH_CHECK}"
echo "=== Done ==="
