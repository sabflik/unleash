# Run terraform formatting, validation, and tflint if installed
.PHONY: tf-lint
tf-lint:
	@echo "==> Formatting Terraform files"
	terraform fmt -recursive
	@echo "==> Validating Terraform configuration"
	terraform validate
	@echo "==> Running tflint"
	tflint --recursive
