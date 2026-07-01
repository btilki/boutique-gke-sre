# ADR 001 — Single GCP project and cluster

## Status

Accepted

## Context

We need environment isolation vs operational simplicity for a portfolio SRE reference.

## Decision

Use **one GCP project** (`boutique-gke`) and **one regional private GKE cluster**. Isolate by Kubernetes namespaces, not by cluster or project.

## Consequences

- **Positive:** Lower cost, simpler Terraform, faster bootstrap/teardown
- **Negative:** No hard blast-radius separation between "envs"; patterns must translate explicitly to multi-env designs
- **Mitigation:** Document extension path in repository-structure rule; use manual Argo sync and policies as production discipline
