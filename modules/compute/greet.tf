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

  depends_on = [aws_iam_role_policy_attachment.greet_lambda_basic]
}

# Archive the inline Lambda code
data "archive_file" "greet_lambda_zip" {
  type        = "zip"
  output_path = "/tmp/greet_function.zip"

  source {
    content  = <<-EOT
      import json

      def handler(event, context):
          return {
              "statusCode": 200,
              "body": json.dumps({"message": "Hello from greet endpoint!"})
          }
    EOT
    filename = "index.py"
  }
}

# # API Gateway integration with Lambda
# resource "aws_api_gateway_integration" "greet_lambda" {
#   rest_api_id      = aws_api_gateway_rest_api.api.id
#   resource_id      = aws_api_gateway_resource.greet.id
#   http_method      = aws_api_gateway_method.greet_get.http_method
#   type             = "AWS_PROXY"
#   integration_http_method = "POST"
#   uri              = aws_lambda_function.greet.invoke_arn
# }

# # Lambda permission for API Gateway invocation
# resource "aws_lambda_permission" "api_gateway_greet" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.greet.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
# }

# # API Gateway method response
# resource "aws_api_gateway_method_response" "greet_response" {
#   rest_api_id = aws_api_gateway_rest_api.api.id
#   resource_id = aws_api_gateway_resource.greet.id
#   http_method = aws_api_gateway_method.greet_get.http_method
#   status_code = "200"
# }

# # API Gateway integration response
# resource "aws_api_gateway_integration_response" "greet_integration_response" {
#   rest_api_id      = aws_api_gateway_rest_api.api.id
#   resource_id      = aws_api_gateway_resource.greet.id
#   http_method      = aws_api_gateway_method.greet_get.http_method
#   status_code      = aws_api_gateway_method_response.greet_response.status_code
#   depends_on       = [aws_api_gateway_integration.greet_lambda]
# }
