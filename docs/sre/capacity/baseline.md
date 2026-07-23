# Capacity baseline — boutique-gke-sre

## Purpose

Document the intended capacity model for Online Boutique on one private regional GKE cluster: workload **HA** (**high availability**), **HPA** (**Horizontal Pod Autoscaler**) / **PDB** (**Pod Disruption Budget**) defaults, node pool autoscaling, and **when to scale** vs when to freeze (error budget).

## When to use

- Planning HPA / node pool changes
- Interpreting game day 02 (pod/zone failure)
- Before load exercises (see [scripts/load/](../../../scripts/load/))
- Weekly platform sync if Pending pods or SLO latency burn

## Architecture

```text
Users → HTTPS LB → frontend (HPA 2–6)
                 → checkoutservice (HPA 2–6)
                 → cartservice (2) → redis-cart (1)
                 → other services (1)

Nodes: regional pool e2-standard-4, autoscaling 1–3 per zone
Cluster Autoscaler + HPA + PDBs
```

## Workload defaults (GitOps)

Source: [gitops/apps/boutique/README.md](../../../gitops/apps/boutique/README.md)

| Workload                | Replicas                | HPA            | PDB               |
| ----------------------- | ----------------------- | -------------- | ----------------- |
| `frontend`              | HPA-managed (min 2)     | CPU 70%, max 6 | `minAvailable: 1` |
| `checkoutservice`       | HPA-managed (min 2)     | CPU 70%, max 6 | `minAvailable: 1` |
| `cartservice`           | 2                       | —              | `minAvailable: 1` |
| `redis-cart`            | **1** (single-instance) | —              | `minAvailable: 1` |
| Other Boutique services | 1                       | —              | —                 |

**Do not** set `redis-cart` replicas &gt; 1 without Redis HA — ClusterIP would split cart state.

## Node pool defaults (Terraform)

Source: [terraform/modules/gke](../../../terraform/modules/gke/)

| Setting      | Default                                             |
| ------------ | --------------------------------------------------- |
| Machine type | `e2-standard-4`                                     |
| Autoscaling  | `min_node_count=1`, `max_node_count=3` **per zone** |
| Region       | `europe-west1` (multi-zone)                         |

Rough upper bound: up to ~9 nodes (3 zones × 3) before hitting pool max — confirm live with `kubectl get nodes`.

## When to scale

| Signal                                    | First action                                 | Escalate to                                                      |
| ----------------------------------------- | -------------------------------------------- | ---------------------------------------------------------------- |
| Frontend/checkout CPU high; HPA below max | Wait for HPA; verify metrics-server          | Raise HPA `maxReplicas` via GitOps PR                            |
| HPA at max; latency SLO burning           | Confirm dependency health (Trace)            | Increase HPA max and/or node pool `max_node_count` via Terraform |
| Pods `Pending` (Insufficient cpu/memory)  | `kubectl describe pod`; check requests       | Raise node pool max; or reduce requests carefully                |
| Single zone loss                          | Expect regional reschedule; PDBs hold        | Game day 02; verify autoscaler logs                              |
| Error budget &lt; 25%                     | **Do not** expand risky capacity experiments | [error-budget freeze](../error-budget/freeze-log.md)             |

## When not to scale

- To “fix” burn alerts without a hypothesis
- Redis replica count (use restore/runbook instead)
- During freeze without platform lead exception

## Baseline load profile (repo stub)

Light synthetic browse traffic: [scripts/load/smoke-browse.sh](../../../scripts/load/smoke-browse.sh).

| Profile                  | Tool        | Use                                               |
| ------------------------ | ----------- | ------------------------------------------------- |
| Smoke browse             | `curl` loop | Sanity / generate LB latency samples              |
| Heavier (optional later) | k6 / Locust | Document targets in PR; run only in agreed window |

**Guardrails:** Prefer low-traffic windows; respect error-budget band; no destructive checkout floods in shared envs without approval.

## Validation commands

```bash
kubectl get hpa,pdb,deploy -n boutique
kubectl top nodes
kubectl top pods -n boutique
kubectl get nodes -o wide
```

## Related

- [operations-runbook.md — Scaling](../../operations/operations-runbook.md)
- [day-2-ops.md](../../operations/day-2-ops.md)
- [game-days/02-zone-pod-failure.md](../game-days/02-zone-pod-failure.md)
- [setup/20-sre-practices-capacity-toil.md](../../setup/20-sre-practices-capacity-toil.md) (topic 20)
