#!/usr/bin/env bash
# Game day: inject Redis / cart failure — boutique-gke-sre
#
# SAFETY:
#   - Run only during scheduled game day 03 (redis-cart-down).
#   - Requires CONFIRM=yes. Affects checkout/cart — expect SEV2 if prolonged.
#   - Restore by scaling Redis back or undoing the NetworkPolicy patch.
#   - Never run against production outside the game-day window.
#
# Usage:
#   CONFIRM=yes ./inject-redis-down.sh
#
set -euo pipefail

CONFIRM="${CONFIRM:-}"
NAMESPACE="${NAMESPACE:-boutique}"
REDIS_DEPLOY="${REDIS_DEPLOY:-redis-cart}"

if [[ "${CONFIRM}" != "yes" ]]; then
  echo "Refusing to run without CONFIRM=yes"
  echo "Example: CONFIRM=yes $0"
  exit 1
fi

echo "==> Scaling ${REDIS_DEPLOY} to 0 in ${NAMESPACE}..."
kubectl scale deployment "${REDIS_DEPLOY}" -n "${NAMESPACE}" --replicas=0

echo "==> Cart/checkout should degrade. Monitor alerts and runbook:"
echo "    docs/sre/runbooks/redis-cart-down.md"
echo "==> Validate impact: curl -I https://boutique.biroltilki.art"
echo ""
echo "==> RESTORE when exercise complete:"
echo "    kubectl scale deployment ${REDIS_DEPLOY} -n ${NAMESPACE} --replicas=1"
echo "Done (failure injected). Remember to restore replicas."
