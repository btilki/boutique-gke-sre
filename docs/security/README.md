# Security documentation

Threat model, IAM matrix, and supply-chain controls.

| Document                               | Phase | Description                                                |
| -------------------------------------- | ----- | ---------------------------------------------------------- |
| [threat-model.md](threat-model.md)     | 1+    | Trust zones and threats                                    |
| [iam-matrix.md](iam-matrix.md)         | 3+    | Service accounts and bindings                              |
| [supply-chain.md](supply-chain.md)     | 3–4   | WIF, ESO, digest-only, Binary Auth, Kyverno, NetworkPolicy |
| [edge-hardening.md](edge-hardening.md) | 7+    | Binary Auth enforce + Argo CD Cloud Armor (post topic 16)  |

Architecture reference: [overview.md](../architecture/overview.md) §9.
