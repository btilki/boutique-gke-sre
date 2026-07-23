#!/usr/bin/env bash
# Create multi-window latency SLO burn-rate alert policies (topic 17).
# Prerequisite: browse-latency and checkout-latency SLOs exist in Cloud Monitoring.
# Idempotent: fails if policies already exist; delete in Console first to recreate.
#
# Availability burn policies remain in create-burn-rate-policies.sh (topic 13).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/runbooks.sh
source "${SCRIPT_DIR}/lib/runbooks.sh"

PROJECT="${PROJECT_ID:-boutique-gke}"
# PROJECT_NUMBER: set explicitly on rebuild, or resolve via gcloud
PROJECT_NUMBER="${PROJECT_NUMBER:-$(gcloud projects describe "${PROJECT}" --format='value(projectNumber)')}"
TOKEN=$(gcloud auth print-access-token)
API="https://monitoring.googleapis.com/v3/projects/${PROJECT}/alertPolicies"

build_policy() {
  local display_name="$1"
  local slo="$2"
  local policy_key="$3"
  local runbook
  runbook="$(runbook_github_url "${policy_key}")"
  local doc
  doc="$(runbook_description "${policy_key}")"
  local runbook_short
  runbook_short="$(runbook_short_name "${policy_key}")"
  export runbook doc runbook_short display_name slo
  python3 <<'PY'
import json, os
display_name = os.environ["display_name"]
slo = os.environ["slo"]
runbook = os.environ["runbook"]
runbook_short = os.environ["runbook_short"]
doc = os.environ["doc"]
ops = "https://github.com/btilki/boutique-gke-sre/blob/main/docs/operations/quick-reference.md"
windows = [
    ("Fast burn 1h (page)", "3600s", 14.4),
    ("Fast burn 6h (page)", "21600s", 6.0),
    ("Slow burn 24h (ticket)", "86400s", 3.0),
    ("Slow burn 24h (ticket)", "86400s", 1.0),
]
conditions = []
for wname, lookback, threshold in windows:
    conditions.append({
        "displayName": f"{display_name} — {wname} @ {threshold}x",
        "conditionThreshold": {
            "filter": f'select_slo_burn_rate("{slo}", "{lookback}")',
            "comparison": "COMPARISON_GT",
            "thresholdValue": threshold,
            "duration": "0s",
            "trigger": {"count": 1},
        },
    })
print(json.dumps({
    "displayName": display_name,
    "combiner": "OR",
    "enabled": True,
    "userLabels": {
        "runbook": runbook_short,
        "slo": slo.split("/")[-1],
    },
    "documentation": {
        "content": doc + "\n\nRunbook: " + runbook + "\nQuick reference: " + ops,
        "mimeType": "text/markdown",
    },
    "conditions": conditions,
}))
PY
}

create_policy() {
  local payload="$1"
  curl -s -X POST "${API}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${payload}"
}

BROWSE_LATENCY_SLO="projects/${PROJECT_NUMBER}/services/boutique-frontend/serviceLevelObjectives/browse-latency"
CHECKOUT_LATENCY_SLO="projects/${PROJECT_NUMBER}/services/boutique-checkout/serviceLevelObjectives/checkout-latency"

echo "Creating browse-latency-burn (SLO: ${BROWSE_LATENCY_SLO})..."
create_policy "$(build_policy "browse-latency-burn" "${BROWSE_LATENCY_SLO}" "browse-latency-burn")" | python3 -m json.tool

echo "Creating checkout-latency-burn (SLO: ${CHECKOUT_LATENCY_SLO})..."
create_policy "$(build_policy "checkout-latency-burn" "${CHECKOUT_LATENCY_SLO}" "checkout-latency-burn")" | python3 -m json.tool

echo "Done. Attach PagerDuty via ./scripts/attach-pagerduty-channel.sh (topic 14) if not already attached."
echo "Validate: make runbook-lint"
