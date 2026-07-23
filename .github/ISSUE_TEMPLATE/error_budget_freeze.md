---
name: Error budget freeze
about: Track deploy freeze or reliability sprint when error budget is low
title: "[error-budget] freeze — "
labels: reliability, error-budget
assignees: ""
---

## Trigger

- [ ] Remaining budget **&lt; 25%** (freeze)
- [ ] Remaining budget **0%** (SEV2 + freeze)
- [ ] Platform lead declared freeze for other reliability reason

**Worst SLO:** browse-availability / browse-latency / checkout-availability / checkout-latency
**Remaining %:**
**Window:** 30-day rolling
**Declared by:**
**On-call:**

## Freeze ID

`EB-YYYYMMDD-N` — also add a row to [docs/sre/error-budget/freeze-log.md](../../docs/sre/error-budget/freeze-log.md)

## Scope (what is paused)

- [ ] Non-critical Boutique digest promotions
- [ ] Infra / Terraform risky changes
- [ ] Game days (unless approved)
- [ ] Other: ________________

## Allowed exceptions

- Security patches with platform lead + note here
- ***

## Reliability work (this sprint)

- [ ] Owner — action — due date

## Exit criteria

- [ ] Worst SLO remaining budget **&gt; 25%**
- [ ] Platform lead sign-off
- [ ] Freeze-log **Exited** timestamp set
- [ ] Team notified (comms template in error-budget-policy.md)

## Links

- Policy: docs/sre/error-budget-policy.md
- Weekly review: docs/sre/error-budget/weekly-review.md
- Postmortem (if SEV2): docs/sre/postmortems/
