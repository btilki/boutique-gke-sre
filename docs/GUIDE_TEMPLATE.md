# Guide template

**Maintainer template** for new `docs/` guides. Reader entry points: [`../README.md`](../README.md) · [`README.md`](README.md).

Every guide under `docs/` must include these sections:

1. **Purpose** — what this guide accomplishes
2. **When to use** — triggers, audience, alternatives
3. **Prerequisites** — tools, access, prior steps
4. **Architecture** — how this fits the whole system
5. **Step-by-step implementation** — numbered, copy-pasteable commands
6. **Validation** — commands + expected results
7. **Troubleshooting** — symptom → cause → fix table
8. **Common mistakes** — what goes wrong and how to avoid it
9. **Best practices** — production-hardened recommendations
10. **Production considerations** — scale, cost, blast radius, rollback
11. **Security considerations** — IAM, secrets, least privilege, audit
12. **Further reading** — internal links, GCP docs, runbooks

Setup guides in `setup/` may also use **Next step** linking to the following topic.

## Terminology

Use the **short form only** (e.g. `SLO`, `WIF`, `GKE`). Do not write the long form in parentheses after the abbreviation. Prefer short form on first mention as well.

Do not use “Wave” labels.

Abbreviation map: [DOCUMENTATION.md](DOCUMENTATION.md).
