# boutique-gke-sre — common operational targets
# Phase 1: validate, lint, terraform fmt/plan

.PHONY: help validate lint fmt tf-init tf-plan tf-fmt kyverno-test install-hooks

TF_ENV ?= terraform/environments/boutique

help:
	@echo "Targets:"
	@echo "  make validate     - Run pre-commit and terraform validate"
	@echo "  make lint         - Run pre-commit hooks on all files"
	@echo "  make fmt          - Format Terraform and YAML"
	@echo "  make tf-init      - terraform init in $(TF_ENV)"
	@echo "  make tf-plan      - terraform plan in $(TF_ENV)"
	@echo "  make kyverno-test  - Run Kyverno policy tests (requires kyverno CLI)"
	@echo "  make install-hooks - Install pre-commit hooks (needs pre-commit + terraform-docs)"

install-hooks:
	@command -v pre-commit >/dev/null || { echo "Install pre-commit: pip install pre-commit"; exit 1; }
	@command -v terraform-docs >/dev/null || { echo "Install terraform-docs: brew install terraform-docs"; exit 1; }
	pre-commit install

validate: lint
	@echo "==> terraform fmt -check"
	terraform fmt -check -recursive terraform/
	@echo "==> terraform init -backend=false (modules)"
	cd $(TF_ENV) && terraform init -backend=false
	@echo "==> terraform validate"
	cd $(TF_ENV) && terraform validate

lint:
	pre-commit run --all-files || true

fmt:
	terraform fmt -recursive terraform/
	pre-commit run terraform_fmt --all-files || true
	pre-commit run prettier --all-files || true

tf-init:
	cd $(TF_ENV) && terraform init

tf-plan:
	cd $(TF_ENV) && terraform plan

tf-fmt:
	terraform fmt -recursive terraform/

kyverno-test:
	@command -v kyverno >/dev/null || { echo "Install kyverno CLI: https://kyverno.io/docs/kyverno-cli/"; exit 1; }
	kyverno test tests/kyverno/
