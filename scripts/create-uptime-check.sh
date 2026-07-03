#!/usr/bin/env bash
# Create HTTPS uptime check + uptime-check-failed alert policy (topic 13 step 6).
set -euo pipefail

PROJECT="${PROJECT_ID:-boutique-gke}"
HOST="boutique.biroltilki.art"
DISPLAY_NAME="boutique-storefront"
TOKEN=$(gcloud auth print-access-token)

echo "=== Creating uptime check: ${DISPLAY_NAME} ==="
gcloud monitoring uptime create "${DISPLAY_NAME}" \
  --project="${PROJECT}" \
  --resource-type=uptime-url \
  --resource-labels="host=${HOST},project_id=${PROJECT}" \
  --protocol=https \
  --path=/ \
  --port=443 \
  --period=1 \
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

RUNBOOK="https://github.com/btilki/boutique-gke-sre/blob/main/docs/sre/runbooks/uptime-check-failed.md"
FILTER="metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" resource.type=\"uptime_url\" metric.labels.check_id=\"${CHECK_ID}\""

echo "=== Creating uptime-check-failed alert policy ==="
export RUNBOOK FILTER HOST
python3 <<'PY' | curl -s -X POST \
  "https://monitoring.googleapis.com/v3/projects/${PROJECT}/alertPolicies" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d @- | python3 -m json.tool
import json, os
runbook = os.environ["RUNBOOK"]
filt = os.environ["FILTER"]
host = os.environ["HOST"]
print(json.dumps({
    "displayName": "uptime-check-failed",
    "combiner": "OR",
    "enabled": True,
    "userLabels": {
        "runbook": "uptime-check-failed",
        "target": "boutique-storefront",
    },
    "documentation": {
        "content": f"External HTTPS uptime check failed for https://{host}/. PagerDuty channel added in topic 14.\n\nRunbook: {runbook}",
        "mimeType": "text/markdown",
    },
    "conditions": [{
        "displayName": "boutique-storefront uptime check failed",
        "conditionThreshold": {
            "filter": filt,
            "comparison": "COMPARISON_LT",
            "thresholdValue": 1,
            "duration": "300s",
            "aggregations": [{
                "alignmentPeriod": "60s",
                "perSeriesAligner": "ALIGN_NEXT_OLDER",
                "crossSeriesReducer": "REDUCE_COUNT_FALSE",
                "groupByFields": ["resource.label.project_id", "resource.label.host"],
            }],
            "trigger": {"count": 1},
        },
    }],
}))
PY

echo "=== Done ==="
gcloud monitoring uptime list-configs --project="${PROJECT}" --format='table(displayName,httpCheck.useSsl,period)'
gcloud monitoring policies list --project="${PROJECT}" --filter='displayName="uptime-check-failed"' --format='table(displayName,enabled)'
