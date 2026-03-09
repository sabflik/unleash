# Run terraform formatting, validation, and tflint
.PHONY: tf-lint
tf-lint:
	@echo "==> Formatting Terraform files"
	terraform fmt -recursive
	@echo "==> Validating Terraform configuration"
	terraform validate
	@echo "==> Running tflint"
	tflint --recursive

# Run terraform security checks with tfsec
.PHONY: tf-sec
tf-sec:
	@echo "==> Running tfsec security checks"
	tfsec .

# Run terraform plan and output
.PHONY: tf-plan
tf-plan:
	@echo "==> Running terraform plan"
	cd terraform && terraform init && terraform plan -var-file=config.tfvars

# Run python tests
.PHONY: test
test:
	@echo "==> Running Python tests"
	pytest -v test_get_jwt.py