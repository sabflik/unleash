# compute module outputs

output "greet_api_invoke_urls" {
  description = "Greet API Gateway invoke URLs by region"
  value       = { for k, v in aws_api_gateway_stage.greet_prod : k => v.invoke_url }
}

output "dispatch_api_invoke_urls" {
  description = "Dispatch API Gateway invoke URLs by region"
  value       = { for k, v in aws_api_gateway_stage.dispatch_prod : k => v.invoke_url }
}
