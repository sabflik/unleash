# IAM role for Lambda
resource "aws_iam_role" "greet_lambda_role" {
  name = "greet_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "greet_lambda_basic" {
  role       = aws_iam_role.greet_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda function for /greet endpoint
resource "aws_lambda_function" "greet" {
  for_each      = var.regions
  region        = each.key
  function_name = "greet_handler"
  role          = aws_iam_role.greet_lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  filename         = data.archive_file.greet_lambda_zip.output_path
  source_code_hash = data.archive_file.greet_lambda_zip.output_base64sha256

  environment {
    variables = {
      REGION = each.key
    }
  }

  depends_on = [aws_iam_role_policy_attachment.greet_lambda_basic]
}

# Archive the inline Lambda code
data "archive_file" "greet_lambda_zip" {
  type        = "zip"
  output_path = "/tmp/greet_function.zip"

  source {
    content  = <<-EOT
      import json
      import os

      def handler(event, context):
          region = os.environ.get("REGION", "unknown")
          return {
              "statusCode": 200,
              "body": json.dumps({"region": region})
          }
    EOT
    filename = "index.py"
  }
}


# Integration: greet endpoint → Lambda
resource "aws_api_gateway_integration" "greet_lambda" {
  region                  = each.key
  for_each                = var.regions
  rest_api_id             = aws_api_gateway_rest_api.api[each.key].id
  resource_id             = aws_api_gateway_resource.greet[each.key].id
  http_method             = aws_api_gateway_method.greet_get[each.key].http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.greet[each.key].invoke_arn
}

# Lambda permission for API Gateway invocation
resource "aws_lambda_permission" "api_gateway_greet" {
  region        = each.key
  for_each      = var.regions
  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.greet[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api[each.key].execution_arn}/*/*"
}

# API Gateway method response
resource "aws_api_gateway_method_response" "greet_response" {
  region      = each.key
  for_each    = var.regions
  rest_api_id = aws_api_gateway_rest_api.api[each.key].id
  resource_id = aws_api_gateway_resource.greet[each.key].id
  http_method = aws_api_gateway_method.greet_get[each.key].http_method
  status_code = "200"
}

# API Gateway integration response
resource "aws_api_gateway_integration_response" "greet_integration_response" {
  region      = each.key
  for_each    = var.regions
  rest_api_id = aws_api_gateway_rest_api.api[each.key].id
  resource_id = aws_api_gateway_resource.greet[each.key].id
  http_method = aws_api_gateway_method.greet_get[each.key].http_method
  status_code = aws_api_gateway_method_response.greet_response[each.key].status_code
  depends_on  = [aws_api_gateway_integration.greet_lambda]
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "greet_api" {
  region      = each.key
  for_each    = var.regions
  rest_api_id = aws_api_gateway_rest_api.api[each.key].id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.greet_lambda[each.key],
      aws_api_gateway_method_response.greet_response[each.key]
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway stage
resource "aws_api_gateway_stage" "greet_prod" {
  for_each      = var.regions
  region        = each.value
  deployment_id = aws_api_gateway_deployment.greet_api[each.key].id
  rest_api_id   = aws_api_gateway_rest_api.api[each.key].id
  stage_name    = "greet_prod"
}
