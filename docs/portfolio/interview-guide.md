# Interview guide — boutique-gke-sre

Resume bullets, talking points, and common interview questions derived from this repository.

**Portfolio overview:** [PORTFOLIO.md](../../PORTFOLIO.md)

---

## Resume bullet points

Copy and adapt; quantify with your live URLs and dates.

### Platform / DevOps

- Designed and operated a **production-style private GKE platform** on GCP with Terraform IaC, GitOps (Argo CD), and namespace-isolated workloads serving **HTTPS traffic on a custom domain**
- Implemented **Workload Identity Federation** for GitHub Actions—eliminating long-lived GCP service account keys from CI
- Built **digest-only GitOps pipeline**: Trivy scan → Artifact Registry → cosign sign/attest → automated digest PR → **Binary Authorization** at deploy

### SRE

- Defined **browse (99.9%) and checkout (99.95%) SLOs** with **multi-window burn-rate alerting** routed to PagerDuty; every alert policy links to a versioned runbook (CI-linted)
- Authored **operations runbook**, on-call quick reference, error-budget policy, and **game-day scenarios** (bad deploy, zone failure, Redis down, alert routing)
- Validated **end-to-end on-call path** with synthetic Cloud Monitoring test alert → PagerDuty incident

### Security

- Enforced **Kyverno admission policies** (digest-only, probes, resources, NetworkPolicy labels, ESO-only secrets) with automated policy tests in CI
- Implemented **NetworkPolicy default-deny** with explicit service graph and **Cloud Armor** edge protection
- Centralized secrets in **GCP Secret Manager** via External Secrets Operator and Workload Identity

### One-liner (LinkedIn / summary)

> Production SRE reference on private GKE: GitOps, signed digest-only deploys, Kyverno/ESO/NetworkPolicy, SLOs with burn alerts to PagerDuty, and full operational documentation—including teardown.

---

## Interview talking points

### 30-second pitch

“I built a live GCP platform around Online Boutique that mirrors how a small platform team would run production: Terraform for infra, Argo CD for GitOps with intentional manual sync, a full supply chain from Trivy through cosign to Binary Authorization, and an SRE layer with real SLOs, burn-rate alerts to PagerDuty, and runbooks. It’s publicly reachable over HTTPS, and I can walk through bootstrap, deploy, incident response, and teardown.”

### 2-minute deep dive (choose one track)

**Track A — Supply chain**

- Problem: third-party images + need immutable deploys
- WIF for CI auth; mirror upstream to Artifact Registry
- Trivy gate with documented accepted-risk baseline for upstream CVEs
- cosign + Binary Authorization; Kyverno rejects `:latest`
- Promotion = digest PR + human Argo sync (ADR-003)

**Track B — SRE / on-call**

- SLIs tied to user journeys (browse vs checkout)
- Multi-window burn rates; runbook URL in every policy
- `runbooks.yaml` registry + `make runbook-lint`
- Test alert validated PagerDuty; game days for muscle memory
- Error budget policy gates risky deploys

**Track C — Security architecture**

- Trust zones: Internet → Armor → Ingress → namespace segmentation
- No SA keys; ESO-only secrets; threat model + IAM matrix documented
- Default-deny NetworkPolicy without service mesh complexity

### Behavioral (STAR) story prompts

| Story                    | Situation → Action → Result                                                                    |
| ------------------------ | ---------------------------------------------------------------------------------------------- |
| **Trivy blocked deploy** | Upstream CVEs → documented trivyignore with review policy → pipeline green with signed digests |
| **Test alert**           | Needed paging confidence → TEST policy + fixed metric filter → PagerDuty incident < 2 min      |
| **Kyverno denial**       | Deploy blocked on missing probe → fixed Helm chart → added policy test to CI                   |
| **Manual sync pushback** | “Why not auto-sync?” → ADR-003 → deliberate promotion on single cluster                        |

---

## Common interview questions

### System design

**Q: How would you deploy a new version of the application?**
A: Trigger `build-scan-sign` (or upstream change) → review digest PR merging `values-images.yaml` → `argocd app diff boutique` → manual sync → smoke `curl` + checkout path → watch burn alerts. Rollback = Git revert + sync.

**Q: How do you prevent a bad image from reaching production?**
A: Trivy in CI; digest-only in Git; Kyverno at admission; Binary Authorization verifies cosign attestation; no `:latest`.

**Q: How would you add a staging environment?**
A: Second GCP project or cluster per ADR extension path; separate Argo Application + values overlay; same modules in `terraform/environments/`; keep WIF repo binding scoped.

**Q: Where do secrets live?**
A: Secret Manager → ESO `ExternalSecret` → K8s Secret at runtime. Kyverno blocks hand-created Secrets. Rotation = new SM version + ESO refresh + rollout.

### SRE

**Q: What are your SLOs and why those numbers?**
A: Browse 99.9%, checkout 99.95%—checkout is higher-value path. 30-day rolling. Error budgets in [catalog.md](../sre/slos/catalog.md); policy in [error-budget-policy.md](../sre/error-budget-policy.md).

**Q: How do burn-rate alerts work?**
A: Multiple windows (1h/6h/24h) with different thresholds (14.4×, 6×, 3×, 1×). Fast burn pages; slow burn tickets. Reduces false positives vs single threshold.

**Q: What happens when error budget is exhausted?**
A: Treat as SEV2 minimum; freeze non-critical deploys; reliability focus per error-budget policy.

**Q: Walk me through incident response.**
A: Page → classify SEV → open runbook from alert → stabilize (rollback/scale) → comms if SEV1–2 → resolve → postmortem. [operations-runbook.md](../operations/operations-runbook.md), [quick-reference.md](../operations/quick-reference.md).

### Security

**Q: Why WIF instead of service account keys?**
A: Short-lived OIDC tokens; no key rotation/leak surface in GitHub. ADR-002.

**Q: Why manual Argo CD sync?**
A: Deliberate promotion; no surprise deploys; same discipline as multi-env. ADR-003.

**Q: How do you segment network traffic?**
A: NetworkPolicy default-deny; explicit allows for ingress→frontend and service graph; Cloud Armor north-south.

### Terraform / GCP

**Q: How is state managed?**
A: GCS remote backend; versioned; separate from GitOps. Modules for networking, GKE, DNS, WIF, etc.

**Q: Why private GKE nodes?**
A: Reduced attack surface; egress via Cloud NAT; aligns with enterprise baseline.

---

## Questions to ask the interviewer

Shows maturity when interviewing them:

- How do you define SLOs today—user journey or service metrics?
- What’s your promotion model—GitOps auto-sync, manual, or release trains?
- How do platform and product teams share error budgets?
- Where are supply-chain controls (signing, admission) in your pipeline?

---

## Portfolio presentation tips

1. **Lead with live URLs** — one `curl -I` beats ten architecture slides
2. **Show one workflow end-to-end** — digest PR → Argo diff → sync (screen recording or GIF)
3. **Open an ADR** — proves you document tradeoffs
4. **Run `make runbook-lint` in terminal** — shows operational automation
5. **Keep README scannable** — reviewers spend < 3 minutes on first pass
6. **Name phases honestly** — Phase 8 in progress reads better than “100% complete” with scaffold backup
7. **Link PORTFOLIO.md from README** — respect reviewer time
8. **Prepare 3 diagrams** — architecture, deploy pipeline, alert flow (in repo)
9. **Don't oversell scale** — “portfolio traffic, production patterns” is credible
10. **Close with teardown** — FinOps + lifecycle completes the story

---

## Further reading (in repo)

- [PORTFOLIO.md](../../PORTFOLIO.md)
- [media-guide.md](media-guide.md)
- [docs/adr/](../adr/)
- [docs/sre/game-days/](../sre/game-days/)
