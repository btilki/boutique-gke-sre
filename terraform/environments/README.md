# Terraform environments

Root modules per deployment target.

| Environment | Path                   | Description                            |
| ----------- | ---------------------- | -------------------------------------- |
| `boutique`  | [boutique/](boutique/) | Single GCP project + cluster (current) |

## Extension

Add `staging/` or `prod/` as sibling directories reusing `../modules/`.
