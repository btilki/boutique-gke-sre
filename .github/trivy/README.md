# Trivy policy files

## `upstream-mirror.trivyignore`

Documents **accepted-risk CVEs** for the `build-scan-sign` mirror path when promoting
third-party images (Online Boutique `v0.10.5`, `redis:7.2-alpine`) without rebuilding
from source.

- Used only by `.github/workflows/build-scan-sign.yml`
- Trivy still scans every image; listed CVEs do not fail the workflow
- **Regenerate** when `upstream_version` or `redis_tag` workflow inputs change
- **Review quarterly** — shrink the list as upstream publishes patched images

To regenerate after a version bump:

```bash
# Run build-scan-sign once, then collect CVEs from failed logs:
gh run view <run-id> --log-failed | rg -o 'CVE-[0-9]+-[0-9]+' | sort -u
```

Future **rebuilt** images (Dockerfile in-repo) should use `CRITICAL,HIGH` with an empty
or minimal ignore file.
