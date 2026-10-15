# ADR 003 — Manual Argo CD sync

## Status

Accepted

## Context

Even on a single cluster, promotion follows production-pilot discipline: operators sync on purpose.

## Decision

Argo CD Applications use **manual sync** — operators sync deliberately after PR merge.

## Consequences

- **Positive:** Prevents surprise deploys
- **Negative:** Extra click; drift until sync
- **Mitigation:** CI smoke tests after documented sync step; auto-sync only if second non-prod cluster added later
