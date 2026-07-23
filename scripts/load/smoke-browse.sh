#!/usr/bin/env bash
# Smoke browse load — sequential GETs against the storefront .
# Generates HTTPS LB samples for latency/availability signals. Not a soak test.
set -euo pipefail

STOREFRONT_URL="${STOREFRONT_URL:-https://boutique.biroltilki.art}"
REQUESTS="${REQUESTS:-30}"
SLEEP_SEC="${SLEEP_SEC:-0.2}"

echo "Target: ${STOREFRONT_URL}"
echo "Requests: ${REQUESTS}"
echo "---"

ok=0
fail=0
for i in $(seq 1 "${REQUESTS}"); do
  # shellcheck disable=SC2034
  read -r code time_total < <(curl -sS -o /dev/null -w "%{http_code} %{time_total}" \
    --connect-timeout 5 --max-time 30 "${STOREFRONT_URL}" || echo "000 0")
  if [[ "${code}" =~ ^2 ]]; then
    ok=$((ok + 1))
  else
    fail=$((fail + 1))
  fi
  printf "%3d  http=%s  time_s=%s\n" "${i}" "${code}" "${time_total}"
  sleep "${SLEEP_SEC}"
done

echo "---"
echo "ok=${ok} fail=${fail}"
if [[ "${fail}" -gt 0 ]]; then
  exit 1
fi
