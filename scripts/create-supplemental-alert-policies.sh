#!/usr/bin/env bash
# Create supplemental alert policies: bad-deploy-rollback, redis-cart-down (topic 13+).
# Idempotent: fails if policies already exist; delete in Console first to recreate.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/runbooks.sh
source "${SCRIPT_DIR}/lib/runbooks.sh"

PROJECT="${PROJECT_ID:-boutique-gke}"
TOKEN=$(gcloud auth print-access-token)
API="https://monitoring.googleapis.com/v3/projects/${PROJECT}/alertPolicies"

create_policy() {
  local payload="$1"
  curl -s -X POST "${API}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "${payload}"
}

build_doc() {
  local policy="$1"
  local runbook
  runbook="$(runbook_github_url "${policy}")"
  local desc
  desc="$(runbook_description "${policy}")"
  printf '%s\n\nRunbook: %s\nOperations: https://github.com/btilki/boutique-gke-sre/blob/main/docs/operations/quick-reference.md' \
    "${desc}" "${runbook}"
}

echo "=== Creating bad-deploy-rollback ==="
BAD_DEPLOY_DOC="$(build_doc bad-deploy-rollback)"
export BAD_DEPLOY_DOC
create_policy "$(python3 <<'PY'
import json, os
doc = os.environ["BAD_DEPLOY_DOC"]
print(json.dumps({
    "displayName": "bad-deploy-rollback",
    "combiner": "OR",
    "enabled": True,
    "userLabels": {
        "runbook": "bad-deploy-rollback",
        "namespace": "boutique",
        "severity": "sev2-sev3",
    },
    "documentation": {
        "content": doc,
        "mimeType": "text/markdown",
    },
    "conditions": [{
        "displayName": "boutique namespace container restart spike",
        "conditionThreshold": {
            "filter": (
                'resource.type="k8s_container" '
                'AND resource.labels.namespace_name="boutique" '
                'AND metric.type="kubernetes.io/container/restart_count"'
            ),
            "comparison": "COMPARISON_GT",
            "thresholdValue": 5,
            "duration": "300s",
            "aggregations": [{
                "alignmentPeriod": "60s",
                "perSeriesAligner": "ALIGN_DELTA",
                "crossSeriesReducer": "REDUCE_SUM",
                "groupByFields": ["resource.labels.namespace_name"],
            }],
            "trigger": {"count": 1},
        },
    }],
}))
PY
)" | python3 -m json.tool

echo "=== Creating redis-cart-down ==="
REDIS_DOC="$(build_doc redis-cart-down)"
export REDIS_DOC
create_policy "$(python3 <<'PY'
import json, os
doc = os.environ["REDIS_DOC"]
print(json.dumps({
    "displayName": "redis-cart-down",
    "combiner": "OR",
    "enabled": True,
    "userLabels": {
        "runbook": "redis-cart-down",
        "namespace": "boutique",
        "workload": "redis-cart",
    },
    "documentation": {
        "content": doc,
        "mimeType": "text/markdown",
    },
    "conditions": [{
        "displayName": "redis-cart container restart or instability",
        "conditionThreshold": {
            "filter": (
                'resource.type="k8s_container" '
                'AND resource.labels.namespace_name="boutique" '
                'AND resource.labels.container_name="redis" '
                'AND metric.type="kubernetes.io/container/restart_count"'
            ),
            "comparison": "COMPARISON_GT",
            "thresholdValue": 2,
            "duration": "180s",
            "aggregations": [{
                "alignmentPeriod": "60s",
                "perSeriesAligner": "ALIGN_DELTA",
                "crossSeriesReducer": "REDUCE_SUM",
                "groupByFields": [
                    "resource.labels.namespace_name",
                    "resource.labels.pod_name",
                ],
            }],
            "trigger": {"count": 1},
        },
    }],
}))
PY
)" | python3 -m json.tool

echo "=== Done ==="
gcloud monitoring policies list --project="${PROJECT}" \
  --filter='displayName:("bad-deploy-rollback" OR "redis-cart-down")' \
  --format='table(displayName,enabled)'
