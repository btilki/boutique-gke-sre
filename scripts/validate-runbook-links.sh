#!/usr/bin/env bash
# Validate alert policy ↔ runbook linkage across registry, YAML refs, and scripts.
# Run: ./scripts/validate-runbook-links.sh
# CI:  make runbook-lint
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REGISTRY="${ROOT}/observability/monitoring/runbooks.yaml"
ALERT_DIR="${ROOT}/observability/monitoring/alert-policies"
RUNBOOK_DIR="${ROOT}/docs/sre/runbooks"
SCRIPTS_DIR="${ROOT}/scripts"
PARSE_PY="${ROOT}/scripts/lib/parse_runbooks.py"

errors=0

fail() {
  echo "FAIL: $*" >&2
  errors=$((errors + 1))
}

pass() {
  echo "OK: $*"
}

echo "=== Runbook link validation ==="

if [[ ! -f "${REGISTRY}" ]]; then
  fail "Registry missing: ${REGISTRY}"
  exit 1
fi

# 1. Registry → runbook files on disk
python3 - "${REGISTRY}" "${RUNBOOK_DIR}" "${PARSE_PY}" <<'PY' || errors=$((errors + 1))
import sys, pathlib, importlib.util

spec = importlib.util.spec_from_file_location("parse_runbooks", sys.argv[3])
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

registry = mod.load_registry(pathlib.Path(sys.argv[1]))
runbook_dir = pathlib.Path(sys.argv[2])
failed = False
for policy, entry in registry["policies"].items():
    rb = entry["runbook"]
    path = runbook_dir / rb
    if not path.is_file():
        print(f"FAIL: policy {policy} → missing runbook {path}", file=sys.stderr)
        failed = True
    else:
        print(f"OK: {policy} → {rb}")
    if not entry.get("description"):
        print(f"FAIL: policy {policy} missing description in registry", file=sys.stderr)
        failed = True
sys.exit(1 if failed else 0)
PY

# 2. Each registry policy has a reference YAML in alert-policies/
while IFS= read -r policy; do
  yaml_file="${ALERT_DIR}/${policy}.yaml"
  if [[ ! -f "${yaml_file}" ]]; then
    fail "Missing reference YAML: ${yaml_file}"
    continue
  fi
  if ! grep -q "runbook:" "${yaml_file}"; then
    fail "${yaml_file} missing documentation.runbook"
    continue
  fi
  expected_url="$(python3 "${PARSE_PY}" "${REGISTRY}" url "${policy}")"
  if ! grep -qF "${expected_url}" "${yaml_file}"; then
    fail "${yaml_file} runbook URL does not match registry (${expected_url})"
  else
    pass "YAML ${policy} URL matches registry"
  fi
done < <(python3 "${PARSE_PY}" "${REGISTRY}" list)

# 3. Create scripts source registry (DRY runbook URLs)
for script in create-burn-rate-policies.sh create-latency-burn-rate-policies.sh create-uptime-check.sh create-argocd-uptime-check.sh create-supplemental-alert-policies.sh; do
  script_path="${SCRIPTS_DIR}/${script}"
  if [[ ! -f "${script_path}" ]]; then
    fail "Missing script: ${script_path}"
    continue
  fi
  if grep -q 'scripts/lib/runbooks.sh\|runbook_github_url' "${script_path}"; then
    pass "${script} sources runbook registry"
  else
    fail "${script} must source scripts/lib/runbooks.sh (DRY runbook URLs)"
  fi
done

# 4. attach-pagerduty-channel.sh uses pagerduty_policies from registry
pd_script="${SCRIPTS_DIR}/attach-pagerduty-channel.sh"
if grep -q 'pagerduty_policies' "${pd_script}"; then
  pass "attach-pagerduty-channel.sh loads policies from registry"
  policy_count="$(python3 "${PARSE_PY}" "${REGISTRY}" pagerduty | wc -l | tr -d ' ')"
  pass "Registry defines ${policy_count} PagerDuty-routed policies"
else
  fail "attach-pagerduty-channel.sh must call pagerduty_policies()"
fi

# 5. Operations quick-reference exists
qr="${ROOT}/docs/operations/quick-reference.md"
if [[ -f "${qr}" ]]; then
  pass "quick-reference.md present"
else
  fail "Missing ${qr}"
fi

echo "=== Summary ==="
if [[ "${errors}" -gt 0 ]]; then
  echo "${errors} validation error(s)" >&2
  exit 1
fi
echo "All runbook links valid."
