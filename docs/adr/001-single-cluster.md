# ADR 001 — Single GCP project and cluster

## Status

Accepted

## Context

We need environment isolation vs operational simplicity for a production SRE platform.

## Decision

Use **one GCP project** (`boutique-gke`) and **one regional GKE cluster**. Nodes are private. The Kubernetes API endpoint is public. Isolate by Kubernetes namespaces, not by cluster or project.

## Consequences

- **Positive:** Lower cost, simpler Terraform, faster bootstrap/teardown
- **Negative:** No hard blast-radius separation between "envs"; patterns must translate explicitly to multi-env designs
- **Control plane:** `enable_private_endpoint = false` in `terraform/modules/gke`. Master authorized networks are not configured.
- **Mitigation:** Document extension path in repository-structure rule; use manual Argo sync and policies as production discipline
