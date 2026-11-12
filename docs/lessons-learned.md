# Lessons learned — boutique-gke-sre

Concrete takeaways from the closed production pilot (topics 01–16 and Phase 8 teardown). Not a full postmortem — only items backed by the repo, screenshots, or the Redis cart game day.

---

## What worked

- **SRE after deployment stayed the center of the story.** Browse and checkout SLOs, burn alerts with runbook URLs, and a PagerDuty test path are in Git and in the evidence gallery. Interviewers can walk that path without a live cluster.
- **Teardown as a first-class step** kept cost honest. Leaving private GKE, NAT, and load balancers running is the expensive failure mode. Phase 8 and [`teardown.md`](teardown.md) treat destroy as mandatory after the pilot.
- **Honest scope** (one project, one cluster, namespaces not isolation) made the tradeoffs discussable instead of hidden. See [`pilot-claims.md`](pilot-claims.md) and [`../SECURITY.md`](../SECURITY.md).

## What broke or surprised us

- **Scale-to-zero under Binary Authorization is a recreate, not a wake-up.** In game day 03, `kubectl scale` on `redis-cart` failed for minutes because the Artifact Registry image had no trusted cosign attestation. The old pod had been admitted before enforce; scaling to zero forced a new admit. A short Binary Authorization DRYRUN restored service; enforce was turned back on in the same exercise. Details: [`sre/game-days/reports/`](sre/game-days/reports/README.md) and the matching postmortem under [`sre/postmortems/`](sre/postmortems/README.md).
- **Restore runbooks assumed scale alone was enough.** The inject worked; the restore path under Binary Authorization enforce was not rehearsed. Attested digests (or a documented break-glass) belong in the redis runbook before the next game day.
- **Alert routing was skipped in that game day.** Storefront 5xx was obvious from curl; PagerDuty ack and the `redis-cart-down` alert were not exercised. A game day should either include alert routing or say “not in scope” before inject.
- **Evidence that is not on disk does not help a reviewer.** Digest PR diffs, a live Kyverno deny, Binary Authorization deny screenshots, and teardown console proof were lived or documented, but they still sit under “Not shown yet” in [`evidence/README.md`](evidence/README.md).

## Design limits we accept (and would change for real production)

- Public Kubernetes API endpoint with private nodes — tighten on a rebuild ([`../SECURITY.md`](../SECURITY.md)).
- Project Binary Authorization default remains allow plus dry-run; only this cluster requires attestation.
- Cosign private key in GitHub secrets — prefer a shorter-lived or keyless path when you rebuild.
- NetworkPolicy objects in Git do not prove the CNI drops packets until Dataplane V2 or Calico is pinned.
- Storefront Cloud Armor stayed a console procedure in the lived path.

## Related

- Proof gallery: [`evidence/README.md`](evidence/README.md)
- File-backed claims: [`pilot-claims.md`](pilot-claims.md)
- Architecture summary: [`../ARCHITECTURE.md`](../ARCHITECTURE.md)
- Game days: [`sre/game-days/`](sre/game-days/README.md)
- Rebuild: [`setup/README.md`](setup/README.md) (topics 01–16)
