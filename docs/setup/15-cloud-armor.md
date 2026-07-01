# Cloud Armor on storefront

## Goal

Create a **Cloud Armor** security policy with an **OWASP ModSecurity Core Rule Set (CRS)** baseline, attach it to the backend service fronting the boutique Ingress, and verify legitimate traffic still reaches **https://boutique.biroltilki.art** while typical attack patterns are blocked at the edge.

## Why this step is required

The storefront Ingress is public internet-facing. Cloud Armor adds WAF and DDoS protection at the Google Cloud load balancer — before malicious requests reach GKE nodes or application pods. OWASP CRS provides a maintained rule set for common web attacks (SQLi, XSS, path traversal).

This is edge hardening in the production bar: HTTPS (topic 06), policy enforcement (topics 11–12), and now WAF (topic 15).

## Prerequisites

- Prior guide: [14-pagerduty.md](14-pagerduty.md)
- Boutique deployed and serving traffic (topic 12)
- Boutique Ingress creates a GCE backend service (verify in Console)
- Tools: `gcloud`, `curl`, `dig`
- Access: `roles/compute.securityAdmin` on `boutique-gke`

## Commands

### 1. Identify the backend service

List backend services created by the GKE Ingress controller:

```bash
gcloud compute backend-services list --project=boutique-gke \
  --format='table(name,backends.group)'
```

Look for a backend service associated with the `boutique` namespace Ingress (name often contains `boutique` or the Ingress UID). Note the name — used as `BACKEND_SERVICE` below.

```bash
export BACKEND_SERVICE="<your-backend-service-name>"
```

Alternatively: **GCP Console → Network services → Load balancing → [boutique HTTPS LB] → Backend → Backend service name**.

### 2. Create Cloud Armor security policy (Console)

**GCP Console → Network security → Cloud Armor → Create policy**

| Field | Value |
|-------|-------|
| Name | `boutique-owasp-crs` |
| Policy type | Backend security policy |
| Default rule action | Allow |

Click **Create policy**.

### 3. Add OWASP CRS preconfigured rule set

Inside policy `boutique-owasp-crs` → **Rules** → **Add rule**

| Field | Value |
|-------|-------|
| Description | `OWASP CRS 3.3 baseline` |
| Priority | `1000` |
| Match | **Advanced rule** → **Preconfigured expression** |
| Expression | `evaluatePreconfiguredExpr('xss-stable')` |

Add additional CRS rules (recommended baseline):

| Priority | Preconfigured expression | Purpose |
|----------|-------------------------|---------|
| 1000 | `evaluatePreconfiguredExpr('xss-stable')` | Cross-site scripting |
| 1001 | `evaluatePreconfiguredExpr('sqli-stable')` | SQL injection |
| 1002 | `evaluatePreconfiguredExpr('lfi-stable')` | Local file inclusion |
| 1003 | `evaluatePreconfiguredExpr('rfi-stable')` | Remote file inclusion |
| 1004 | `evaluatePreconfiguredExpr('rce-stable')` | Remote code execution |

Set each rule action to **Deny (403)**.

Optional rate limiting rule (priority 2000):

| Field | Value |
|-------|-------|
| Match | `true` (all requests) |
| Action | Rate-based ban |
| Threshold | e.g. 100 requests per 60 s per IP |

### 4. Create policy via gcloud (alternative)

```bash
gcloud compute security-policies create boutique-owasp-crs \
  --project=boutique-gke \
  --description="OWASP CRS baseline for Online Boutique storefront"

gcloud compute security-policies rules create 1000 \
  --project=boutique-gke \
  --security-policy=boutique-owasp-crs \
  --expression="evaluatePreconfiguredExpr('xss-stable')" \
  --action=deny-403 \
  --description="OWASP CRS - XSS"

gcloud compute security-policies rules create 1001 \
  --project=boutique-gke \
  --security-policy=boutique-owasp-crs \
  --expression="evaluatePreconfiguredExpr('sqli-stable')" \
  --action=deny-403 \
  --description="OWASP CRS - SQLi"
```

### 5. Attach policy to boutique backend service

**Console → Backend services → [BACKEND_SERVICE] → Security → Cloud Armor policy → `boutique-owasp-crs` → Save**

Or via gcloud:

```bash
gcloud compute backend-services update "${BACKEND_SERVICE}" \
  --project=boutique-gke \
  --security-policy=boutique-owasp-crs \
  --global
```

Propagation takes 1–5 minutes.

### 6. Verify legitimate traffic

```bash
curl -I https://boutique.biroltilki.art
curl -s -o /dev/null -w "%{http_code}\n" https://boutique.biroltilki.art
```

Expected: `200` or `302` — normal storefront responses.

### 7. Verify WAF blocks attack patterns (optional)

Send a request with a common SQLi probe (expect **403** from Cloud Armor):

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  "https://boutique.biroltilki.art/?id=1'%20OR%201=1--"
```

Expected: `403` (blocked at edge). Exact status depends on which CRS rule matches.

Check Cloud Armor logs: **Console → Cloud Armor → boutique-owasp-crs → Logs**.

## Expected output

- Security policy `boutique-owasp-crs` exists with CRS preconfigured rules
- Backend service for boutique Ingress shows attached policy
- Normal `curl -I https://boutique.biroltilki.art` returns `HTTP/2 200` or `302`
- Malicious test URL returns `403`
- Cloud Armor request logs show `deny` entries for blocked requests

## Validation

```bash
# DNS still correct
dig +short boutique.biroltilki.art

# Legitimate HTTPS traffic allowed
curl -I https://boutique.biroltilki.art

# Policy attached to backend
gcloud compute backend-services describe "${BACKEND_SERVICE}" \
  --project=boutique-gke \
  --global \
  --format='value(securityPolicy)'

# Policy rules present
gcloud compute security-policies describe boutique-owasp-crs \
  --project=boutique-gke \
  --format='table(rules.priority,rules.description,rules.action)'
```

**Pass criteria:** Storefront accessible; Cloud Armor policy attached; CRS rules active; attack probe blocked with 403.

## Common problems

| Symptom | Cause | Fix |
|---------|-------|-----|
| All requests 403 | Default deny or overly broad rule | Add default allow rule at max priority (2147483647) |
| Policy not enforcing | Wrong backend service | Re-identify LB backend from Ingress status |
| Legitimate traffic blocked | CRS false positive | Tune rule sensitivity; add preview mode first |
| No logs | Logging not enabled | Enable Cloud Armor logging on policy |
| `backend-services update` fails | Regional vs global mismatch | Add `--global` for external HTTP(S) LB |
| Storefront 502 after attach | Backend health check failing | Check pod health; unrelated to Armor if probes fail |

## Recovery

- **Detach policy (break-glass):** `gcloud compute backend-services update "${BACKEND_SERVICE}" --security-policy="" --global`
- **Preview mode:** Set rule action to `allow` with `preview: true` to log without blocking
- **Delete policy:** Detach first, then `gcloud compute security-policies delete boutique-owasp-crs`
- **Rollback rule:** Delete specific rule priority; CRS rules are independent

## Best practices

- Start CRS rules in **preview** mode; review logs before enforcing deny
- Add IP allowlist for CI smoke-test runners if they trigger false positives
- Combine Cloud Armor with Kubernetes NetworkPolicy for defense in depth
- Monitor false positive rate after enablement; tune for checkout POST paths
- Document policy changes in change management — WAF changes can block revenue paths

## Security notes

- Cloud Armor protects north-south traffic only; east-west traffic uses NetworkPolicy
- OWASP CRS is a baseline — not a substitute for secure application code
- Rate limiting mitigates volumetric abuse but tune thresholds to avoid blocking NATed users
- Cloud Armor logs may contain request URLs — handle per data retention policy
- Restrict `compute.securityAdmin` to platform team members

## Next step

→ [Smoke validation + SRE verification](16-smoke-validation.md)
