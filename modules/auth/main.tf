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

// TODO: change auth flows to use OIDC and add a client secret
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

resource "aws_cognito_user" "test_user" {
  user_pool_id = aws_cognito_user_pool.users.id
  username     = "testuser"
  password     = var.test_user_password
  
  attributes = {
    email          = var.test_user_email
    email_verified = true
  }
}