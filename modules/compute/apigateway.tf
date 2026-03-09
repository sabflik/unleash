# look up the user pool from id supplied by root
# this data source is needed to obtain ARN for authorizer

data "aws_cognito_user_pool" "pool" {
  user_pool_id = var.cognito_user_pool_id
}

# API Gateway within compute module
resource "aws_api_gateway_rest_api" "api" {
  name        = "compute_api"
  description = "API for compute routes"
}

resource "aws_api_gateway_resource" "greet" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "greet"
}

resource "aws_api_gateway_authorizer" "cognito" {
  name                   = "cognito_authorizer"
  rest_api_id            = aws_api_gateway_rest_api.api.id
  identity_source        = "method.request.header.Authorization"
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = [
    data.aws_cognito_user_pool.pool.arn
  ]
}

resource "aws_api_gateway_method" "greet_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.greet.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_resource" "dispatch" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "dispatch"
}

resource "aws_api_gateway_method" "dispatch_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.dispatch.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}
