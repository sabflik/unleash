terraform {
  required_version = ">= 1.14.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.34.0"
    }
  }
}

resource "aws_cognito_user_pool" "users" {
  name = var.user_pool_name

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  auto_verified_attributes = ["email"]
}

resource "aws_ssm_parameter" "pool_id" {
  name  = "/user-pool-id"
  type  = "String"
  value = aws_cognito_user_pool.users.id
}

resource "aws_cognito_user_pool_client" "web_app" {
  name         = var.user_pool_client_name
  user_pool_id = aws_cognito_user_pool.users.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]

  prevent_user_existence_errors = "ENABLED"
}

resource "aws_ssm_parameter" "client_id" {
  name  = "/user-pool-client-id"
  type  = "String"
  value = aws_cognito_user_pool_client.web_app.id
}

data "aws_secretsmanager_secret" "test_user_credentials" {
  name = "cognito-user"
}

data "aws_secretsmanager_secret_version" "test_user_credentials" {
  secret_id = data.aws_secretsmanager_secret.test_user_credentials.id
}

locals {
  user_creds = jsondecode(
    data.aws_secretsmanager_secret_version.test_user_credentials.secret_string
  )
}

resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.users.id
  username     = local.user_creds.username
  password     = local.user_creds.password

  attributes = {
    email          = local.user_creds.email
    email_verified = true
  }
}
