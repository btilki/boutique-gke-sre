#!/usr/bin/env bash
# Attach PagerDuty notification channel to topic 13 alert policies (topic 14 step 4).
# Prerequisites:
#   - GSM secret pagerduty-integration-key (Events API v2 integration key)
#   - Alert policies from topic 13 exist in Cloud Monitoring
set -euo pipefail

PROJECT="${PROJECT_ID:-boutique-gke}"
CHANNEL_NAME="pagerduty-boutique-production"
POLICIES=(
  browse-availability-burn
  checkout-availability-burn
  uptime-check-failed
)

if ! gcloud secrets describe pagerduty-integration-key --project="${PROJECT}" >/dev/null 2>&1; then
  echo "ERROR: Secret pagerduty-integration-key not found in Secret Manager." >&2
  echo "Create it per docs/setup/14-pagerduty.md step 2 before running this script." >&2
  exit 1
fi

INTEGRATION_KEY="$(gcloud secrets versions access latest --secret=pagerduty-integration-key --project="${PROJECT}")"
export INTEGRATION_KEY
TOKEN=$(gcloud auth print-access-token)

echo "=== Resolve or create notification channel ==="
CHANNEL_ID=$(gcloud alpha monitoring channels list --project="${PROJECT}" \
  --filter="displayName=${CHANNEL_NAME}" --format='value(name)' | head -1)

if [[ -z "${CHANNEL_ID}" ]]; then
  echo "Creating channel ${CHANNEL_NAME}..."
  CHANNEL_ID=$(curl -s -X POST \
    "https://monitoring.googleapis.com/v3/projects/${PROJECT}/notificationChannels" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json, os
print(json.dumps({
    'type': 'pagerduty',
    'displayName': '${CHANNEL_NAME}',
    'labels': {'service_key': os.environ['INTEGRATION_KEY']},
    'enabled': True,
}))
")" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])")
else
  echo "Using existing channel: ${CHANNEL_ID}"
fi

attach_channel() {
  local policy_name="$1"
  local policy_resource
  policy_resource=$(gcloud monitoring policies list --project="${PROJECT}" \
    --filter="displayName=${policy_name}" --format='value(name)' | head -1)
  if [[ -z "${policy_resource}" ]]; then
    echo "WARN: policy ${policy_name} not found — skip" >&2
    return
  fi
  echo "=== Attaching channel to ${policy_name} ==="
  curl -s -X PATCH \
    "https://monitoring.googleapis.com/v3/${policy_resource}?updateMask=notificationChannels" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json
print(json.dumps({'notificationChannels': ['${CHANNEL_ID}']}))
")" | python3 -c "import sys,json; p=json.load(sys.stdin); print(p.get('displayName', p))"
}

for p in "${POLICIES[@]}"; do
  attach_channel "${p}"
done

echo "=== Done ==="
gcloud monitoring policies list --project="${PROJECT}" \
  --filter='displayName:("-availability-burn" OR displayName="uptime-check-failed")' \
  --format='table(displayName,notificationChannels)'
