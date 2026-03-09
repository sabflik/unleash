# look up the user pool from id supplied by root
data "aws_cognito_user_pool" "pool" {
  user_pool_id = var.cognito_user_pool_id
}

# API Gateway deployed to multiple regions
resource "aws_api_gateway_rest_api" "api" {
  for_each    = var.regions
  region    = each.key
  name        = "compute_api-${each.key}"
  description = "API for compute routes in ${each.key}"
}

resource "aws_api_gateway_resource" "greet" {
  for_each    = var.regions
  region    = each.key
  rest_api_id = aws_api_gateway_rest_api.api[each.key].id
  parent_id   = aws_api_gateway_rest_api.api[each.key].root_resource_id
  path_part   = "greet"
}

resource "aws_api_gateway_authorizer" "cognito" {
  for_each      = var.regions
  region      = each.key
  name          = "cognito_authorizer-${each.key}"
  rest_api_id   = aws_api_gateway_rest_api.api[each.key].id
  identity_source = "method.request.header.Authorization"
  type          = "COGNITO_USER_POOLS"
  provider_arns = [
    data.aws_cognito_user_pool.pool.arn
  ]
}

resource "aws_api_gateway_method" "greet_get" {
  for_each      = var.regions
  region      = each.key
  rest_api_id   = aws_api_gateway_rest_api.api[each.key].id
  resource_id   = aws_api_gateway_resource.greet[each.key].id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito[each.key].id
}

resource "aws_api_gateway_resource" "dispatch" {
  for_each    = var.regions
  region    = each.key
  rest_api_id = aws_api_gateway_rest_api.api[each.key].id
  parent_id   = aws_api_gateway_rest_api.api[each.key].root_resource_id
  path_part   = "dispatch"
}

resource "aws_api_gateway_method" "dispatch_get" {
  for_each      = var.regions
  region      = each.key
  rest_api_id   = aws_api_gateway_rest_api.api[each.key].id
  resource_id   = aws_api_gateway_resource.dispatch[each.key].id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito[each.key].id
}
