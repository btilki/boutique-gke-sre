# Load / capacity scripts

Lightweight traffic helpers for capacity and SLO signal generation. **Not** a replacement for production load testing platforms.

## Scripts

| Script                             | Purpose                                                       |
| ---------------------------------- | ------------------------------------------------------------- |
| [smoke-browse.sh](smoke-browse.sh) | Sequential HTTPS GETs to the storefront; prints status + time |

## Usage

```bash
# Default: 30 requests to https://boutique.biroltilki.art
./scripts/load/smoke-browse.sh

# Custom
STOREFRONT_URL=https://boutique.biroltilki.art REQUESTS=50 ./scripts/load/smoke-browse.sh
```

## Guardrails

- Run only when the cluster is up and error-budget band allows (see [error-budget-policy](../../docs/sre/error-budget-policy.md))
- Prefer agreed maintenance / game-day windows
- For heavier profiles, add k6/Locust separately — do not commit secrets or production-breaking defaults

## Related

- [docs/sre/capacity/baseline.md](../../docs/sre/capacity/baseline.md)
- [docs/setup/20-sre-practices-capacity-toil.md](../../docs/setup/20-sre-practices-capacity-toil.md)
