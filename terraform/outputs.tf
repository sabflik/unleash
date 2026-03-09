# expose module outputs from compute module
output "greet_api_invoke_urls" {
  description = "Invoke URLs for greet endpoint from compute module"
  value       = module.compute.greet_api_invoke_urls
}

output "dispatch_api_invoke_urls" {
  description = "Invoke URLs for dispatch endpoint from compute module"
  value       = module.compute.dispatch_api_invoke_urls
}
