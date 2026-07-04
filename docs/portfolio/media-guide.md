# Media guide — portfolio visuals

Screenshots, diagrams, and demo recordings that strengthen **boutique-gke-sre** for hiring and presentations.

**Why this matters:** Reviewers trust **evidence**. Live URLs help; curated visuals prove you operated the system, not only wrote Terraform.

---

## Architecture diagrams

### In repository (Mermaid — version controlled)

| File                                                           | Use in               | Export command                                                      |
| -------------------------------------------------------------- | -------------------- | ------------------------------------------------------------------- |
| [architecture.mmd](../diagrams/architecture.mmd)               | README, slides, blog | `mmdc -i docs/diagrams/architecture.mmd -o assets/architecture.png` |
| [network-flow.mmd](../diagrams/network-flow.mmd)               | Security interview   | same pattern                                                        |
| [deployment-pipeline.mmd](../diagrams/deployment-pipeline.mmd) | CI/CD deep dive      | same pattern                                                        |
| [sre-alert-flow.mmd](../diagrams/sre-alert-flow.mmd)           | SRE interview        | same pattern                                                        |

**Strengthens:** Shows diagram-as-code discipline; diagrams stay in sync with Git.

### Recommended slide deck order

1. Context (problem + URLs)
2. `architecture.mmd` — components
3. `deployment-pipeline.mmd` — how code ships
4. `network-flow.mmd` — security zones
5. `sre-alert-flow.mmd` — how incidents are detected

---

## Screenshots to include

### Already in repo (`docs/diagrams/`)

| Screenshot                                   | Proves                 | Capture from                 |
| -------------------------------------------- | ---------------------- | ---------------------------- |
| `boutique-storefront-https.png`              | Public HTTPS works     | Browser on boutique URL      |
| `argocd-applications-healthy-synced.png`     | GitOps healthy         | Argo CD UI                   |
| `github-actions-build-scan-sign-success.png` | Supply chain CI        | GitHub Actions               |
| `github-actions-trivy-scan-failure.png`      | Security gate story    | Actions (before trivyignore) |
| `pagerduty-service-events-api-v2.png`        | Correct PD integration | PagerDuty UI                 |

### Captured (portfolio — live data)

| Screenshot                     | Filename                         | Regenerate                                                |
| ------------------------------ | -------------------------------- | --------------------------------------------------------- |
| Cloud Monitoring SLO dashboard | `slo-browse-checkout.png`        | `python3 scripts/portfolio/generate-media-screenshots.py` |
| PagerDuty test incident        | `pagerduty-test-incident.png`    | same (data from Monitoring alerts API)                    |
| Runbook lint success           | `runbook-lint-success.png`       | same (runs `make runbook-lint`)                           |
| Kyverno ClusterPolicies (5)    | `kyverno-five-policies.png`      | same (`kubectl get clusterpolicy`)                        |
| Burn-rate alert + runbook URL  | `alert-policy-runbook-link.png`  | same (Monitoring API)                                     |
| Binary Authorization enforced  | `binary-auth-enforced.png`       | same (Binary Authorization API)                           |
| Cloud Armor on ingress         | `cloud-armor-ingress.png`        | same (compute securityPolicies API)                       |
| Grafana golden signals         | `grafana-boutique-dashboard.png` | same (`kubectl top` + Grafana deployment)                 |
| Cloud Trace checkout path      | `cloud-trace-checkout.png`       | same (Cloud Trace API + service graph)                    |

### Recommended additions (capture and commit)

_None — portfolio screenshot set is complete. Re-run the generator after SLO/alert/policy changes._

**Strengthens:** Converts “claims” into audit trail; interviewers remember visuals.

### Capture tips

- Redact account emails if desired; keep project name `boutique-gke`
- Prefer **dark mode off** for slide legibility
- Include **URL bar** on HTTPS shots (padlock visible)
- Terminal: full-width font, high contrast

---

## GIF / demo ideas

Short recordings (15–60s) for README, LinkedIn, or interview screen-share.

| Demo                 | Script                                                     | Strengthens               |
| -------------------- | ---------------------------------------------------------- | ------------------------- |
| **Smoke check**      | `curl -I` both URLs → 200/302                              | “It’s live” in 10 seconds |
| **Digest promotion** | Show digest PR diff → merge → Argo diff → Sync             | End-to-end change control |
| **Kyverno deny**     | `kubectl apply` bad pod from `examples/` → denied          | Policy enforcement        |
| **Rollback**         | `git revert` → Argo sync → pods recover                    | SRE muscle memory         |
| **Test alert**       | Fire TEST policy → PagerDuty ack on phone                  | On-call credibility       |
| **Runbook lint**     | `make runbook-lint` → all green                            | Engineering hygiene       |
| **Game day inject**  | `scripts/game-days/inject-redis-down.sh` → alert → runbook | Chaos readiness           |

### Recording tools

- macOS: QuickTime, CleanShot, or `asciinema` for terminal
- Keep GIFs **< 5 MB** for GitHub README (use external host for larger)

**Strengthens:** Demos communicate operational fluency faster than static docs.

---

## README embedding pattern

```markdown
## Live demo

| SLOs                                                    | Runbook lint                                            | Test incident                                                |
| ------------------------------------------------------- | ------------------------------------------------------- | ------------------------------------------------------------ |
| ![SLO dashboard](docs/diagrams/slo-browse-checkout.png) | ![runbook lint](docs/diagrams/runbook-lint-success.png) | ![PagerDuty test](docs/diagrams/pagerduty-test-incident.png) |

**Storefront:** ![HTTPS](docs/diagrams/boutique-storefront-https.png)
```

**Strengthens:** First screenful of README becomes portfolio landing page.

---

## What not to include

- Secret Manager values, PD integration keys, cosign private keys
- Argo CD admin password screenshots
- Unredacted PII in logs

---

## Checklist before sharing repo publicly

- [ ] Both URLs load with valid TLS
- [ ] At least 3 screenshots in `docs/diagrams/`
- [ ] Mermaid diagrams render on GitHub
- [ ] PORTFOLIO.md linked from README
- [ ] Roadmap status matches reality
- [ ] No secrets in git history (`gitleaks` clean)

---

## Related

- [PORTFOLIO.md](../../PORTFOLIO.md)
- [interview-guide.md](interview-guide.md)
- [docs/diagrams/README.md](../diagrams/README.md)
