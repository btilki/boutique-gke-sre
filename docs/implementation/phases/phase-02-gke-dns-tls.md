# Phase 2 — GKE + DNS + TLS

**Status:** Not started
**Size:** L
**Setup guides:** [04 — GKE cluster](../setup/04-gke-cluster.md), [05 — Cloud DNS](../setup/05-cloud-dns.md), [06 — Ingress + TLS](../setup/06-ingress-tls.md)

## Objectives

- Private regional GKE cluster with Workload Identity
- Global static ingress IP
- Cloud DNS zone + A records for `boutique.biroltilki.art` and `argocd.boutique.biroltilki.art`
- ManagedCertificate and Ingress annotations (HTTPS active after topic 09)

## Terraform modules

Apply after Phase 1: `gke`, `ingress_edge`, `dns` (wired in `terraform/environments/boutique/main.tf`).

## User actions required

1. Complete setup guides 04–06
2. Validate: `kubectl get nodes`, `dig` both hostnames, static IP reserved
3. Commit Phase 2 artifacts

## Previous phase

[Phase 1 — Terraform foundation](phase-01-terraform-foundation.md)

## Next phase

Phase 3 — WIF + Artifact Registry + CI ([07-github-wif.md](../setup/07-github-wif.md), [08-artifact-registry-binary-auth.md](../setup/08-artifact-registry-binary-auth.md))
