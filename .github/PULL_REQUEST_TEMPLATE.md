# Pull request

## Summary

<!-- What changed and why -->

## Checklist

- [ ] `make validate` passes locally
- [ ] No secrets or credentials in diff
- [ ] Setup guide updated if operator steps changed
- [ ] Runbook linked if new alert policy (SRE changes)
- [ ] Release notes / migration updated if breaking change ([release/](docs/release/))

## Deployment

- [ ] Manifest digest change via CI PR (not hand-edited `:latest`)
- [ ] Manual Argo CD sync planned after merge (if applicable)
