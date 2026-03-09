# IAM role for Lambda
resource "aws_iam_role" "dispatch_lambda_role" {
  name = "dispatch_lambda_role"

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

resource "aws_iam_role_policy_attachment" "dispatch_lambda_basic" {
  role       = aws_iam_role.dispatch_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# inline policy granting ECS run task permissions
resource "aws_iam_role_policy" "dispatch_ecs_run" {
  name = "dispatch-ecs-run-policy"
  role = aws_iam_role.dispatch_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
          "iam:PassRole"
        ]
        Resource = "*" # Restrict later as needed
      }
    ]
  })
}

# Lambda function for /dispatch endpoint
resource "aws_lambda_function" "dispatch" {
  for_each      = var.regions
  region        = each.key
  function_name = "dispatch_handler"
  role          = aws_iam_role.dispatch_lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.11"

  filename         = data.archive_file.dispatch_lambda_zip.output_path
  source_code_hash = data.archive_file.dispatch_lambda_zip.output_base64sha256

  environment {
    variables = {
      CLUSTER_ARN     = aws_ecs_cluster.main[each.key].arn
      TASK_DEFINITION = aws_ecs_task_definition.app[each.key].arn
      SUBNET_ID       = aws_subnet.public[each.key].id
      SECURITY_GROUP  = aws_security_group.ecs_tasks[each.key].id
    }
  }

  depends_on = [aws_iam_role_policy_attachment.dispatch_lambda_basic, aws_iam_role_policy.dispatch_ecs_run]
}

# Archive the inline Lambda code
data "archive_file" "dispatch_lambda_zip" {
  type        = "zip"
  output_path = "/tmp/dispatch_function.zip"

  source {
    content  = <<-EOT
      import json
      import os
      import boto3

      ecs = boto3.client('ecs')

      def handler(event, context):
          # run a Fargate task using environment variables
          cluster = os.environ.get('CLUSTER_ARN')
          task_def = os.environ.get('TASK_DEFINITION')
          subnet = os.environ.get('SUBNET_ID')
          sg = os.environ.get('SECURITY_GROUP')

          response = ecs.run_task(
              cluster=cluster,
              launchType='FARGATE',
              taskDefinition=task_def,
              networkConfiguration={
                  'awsvpcConfiguration': {
                      'subnets': [subnet],
                      'securityGroups': [sg],
                      'assignPublicIp': 'ENABLED'
                  }
              }
          )

          return {
              'statusCode': 200,
              'body': json.dumps({'started': response.get('tasks', [])})
          }
    EOT
    filename = "index.py"
  }
}


# Integration: dispatch endpoint → Lambda
resource "aws_api_gateway_integration" "dispatch_lambda" {
  region                  = each.key
  for_each                = var.regions
  rest_api_id             = aws_api_gateway_rest_api.api[each.key].id
  resource_id             = aws_api_gateway_resource.dispatch[each.key].id
  http_method             = aws_api_gateway_method.dispatch_get[each.key].http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.dispatch[each.key].invoke_arn
}

# Lambda permission for API Gateway invocation
resource "aws_lambda_permission" "api_gateway_dispatch" {
  region        = each.key
  for_each      = var.regions
  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dispatch[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api[each.key].execution_arn}/*/*"
}

# API Gateway method response
resource "aws_api_gateway_method_response" "dispatch_response" {
  region      = each.key
  for_each    = var.regions
  rest_api_id = aws_api_gateway_rest_api.api[each.key].id
  resource_id = aws_api_gateway_resource.dispatch[each.key].id
  http_method = aws_api_gateway_method.dispatch_get[each.key].http_method
  status_code = "200"
}

# API Gateway integration response
resource "aws_api_gateway_integration_response" "dispatch_integration_response" {
  region      = each.key
  for_each    = var.regions
  rest_api_id = aws_api_gateway_rest_api.api[each.key].id
  resource_id = aws_api_gateway_resource.dispatch[each.key].id
  http_method = aws_api_gateway_method.dispatch_get[each.key].http_method
  status_code = aws_api_gateway_method_response.dispatch_response[each.key].status_code
  depends_on  = [aws_api_gateway_integration.dispatch_lambda]
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "dispatch_api" {
  region      = each.key
  for_each    = var.regions
  rest_api_id = aws_api_gateway_rest_api.api[each.key].id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.dispatch_lambda[each.key],
      aws_api_gateway_method_response.dispatch_response[each.key]
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway stage
resource "aws_api_gateway_stage" "dispatch_prod" {
  for_each      = var.regions
  region        = each.value
  deployment_id = aws_api_gateway_deployment.dispatch_api[each.key].id
  rest_api_id   = aws_api_gateway_rest_api.api[each.key].id
  stage_name    = "dispatch_prod"
}
