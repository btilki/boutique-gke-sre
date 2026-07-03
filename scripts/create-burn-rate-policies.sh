#!/usr/bin/env bash
# Create multi-window SLO burn-rate alert policies (topic 13 step 5).
# Idempotent: fails if policies already exist; delete in Console first to recreate.
set -euo pipefail

PROJECT="${PROJECT_ID:-boutique-gke}"
TOKEN=$(gcloud auth print-access-token)
API="https://monitoring.googleapis.com/v3/projects/${PROJECT}/alertPolicies"

build_policy() {
  DISPLAY_NAME="$1" SLO="$2" RUNBOOK="$3" RUNBOOK_SHORT="$4" DOC="$5" python3 <<'PY'
import json, os
display_name = os.environ["DISPLAY_NAME"]
slo = os.environ["SLO"]
runbook = os.environ["RUNBOOK"]
runbook_short = os.environ["RUNBOOK_SHORT"]
doc = os.environ["DOC"]
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
        "content": doc + "\n\nRunbook: " + runbook,
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

BROWSE_SLO="projects/334181791139/services/boutique-frontend/serviceLevelObjectives/browse-availability"
CHECKOUT_SLO="projects/334181791139/services/boutique-checkout/serviceLevelObjectives/checkout-availability"

echo "Creating browse-availability-burn..."
create_policy "$(build_policy \
  "browse-availability-burn" \
  "${BROWSE_SLO}" \
  "https://github.com/btilki/boutique-gke-sre/blob/main/docs/sre/runbooks/browse-availability-burn.md" \
  "browse-availability-burn" \
  "Multi-window burn-rate alert for browse-availability SLO (99.9% / 30d).")" | python3 -m json.tool

echo "Creating checkout-availability-burn..."
create_policy "$(build_policy \
  "checkout-availability-burn" \
  "${CHECKOUT_SLO}" \
  "https://github.com/btilki/boutique-gke-sre/blob/main/docs/sre/runbooks/checkout-latency-burn.md" \
  "checkout-latency-burn" \
  "Multi-window burn-rate alert for checkout-availability SLO (99.95% / 30d).")" | python3 -m json.tool
