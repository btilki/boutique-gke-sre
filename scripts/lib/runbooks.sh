#!/usr/bin/env bash
# Resolve runbook URLs from observability/monitoring/runbooks.yaml
set -euo pipefail

RUNBOOKS_YAML="${RUNBOOKS_YAML:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/observability/monitoring/runbooks.yaml}"
PARSE_PY="${BASH_SOURCE[0]%/*}/parse_runbooks.py"

runbook_github_url() {
  python3 "${PARSE_PY}" "${RUNBOOKS_YAML}" url "$1"
}

runbook_short_name() {
  python3 "${PARSE_PY}" "${RUNBOOKS_YAML}" short "$1"
}

runbook_description() {
  python3 "${PARSE_PY}" "${RUNBOOKS_YAML}" description "$1"
}

pagerduty_policies() {
  python3 "${PARSE_PY}" "${RUNBOOKS_YAML}" pagerduty
}
