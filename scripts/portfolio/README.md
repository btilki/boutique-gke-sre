# Portfolio media scripts

Generate portfolio PNG screenshots from **live GCP API data** and terminal output.

## Usage

```bash
# Requires: gcloud auth, Pillow (pip install pillow), network access
python3 scripts/portfolio/generate-media-screenshots.py
```

## Outputs

| File                                           | Source                                             |
| ---------------------------------------------- | -------------------------------------------------- |
| `docs/diagrams/slo-browse-checkout.png`        | Cloud Monitoring SLO compliance API                |
| `docs/diagrams/runbook-lint-success.png`       | `make runbook-lint` terminal output                |
| `docs/diagrams/pagerduty-test-incident.png`    | TEST-pagerduty-routing alert from Monitoring API   |
| `docs/diagrams/kyverno-five-policies.png`      | `kubectl get clusterpolicy` (5 Enforce policies)   |
| `docs/diagrams/alert-policy-runbook-link.png`  | `browse-availability-burn` policy + runbook URL    |
| `docs/diagrams/binary-auth-enforced.png`       | Binary Authorization policy API                    |
| `docs/diagrams/cloud-armor-ingress.png`        | Cloud Armor security policy + backend attachment   |
| `docs/diagrams/grafana-boutique-dashboard.png` | `kubectl top` pods + Grafana deployment status     |
| `docs/diagrams/cloud-trace-checkout.png`       | Cloud Trace API (or representative checkout spans) |

## Notes

- Images are styled for portfolio legibility; data is from the live `boutique-gke` project.
- Re-run after SLO or alert changes to refresh captures.
- For pixel-perfect Console UI shots, capture manually per [media-guide.md](../../docs/portfolio/media-guide.md).
