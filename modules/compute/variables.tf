variable "table_regions" {
  description = "Map of regions to their provider references for DynamoDB tables"
  type        = map(any)
  default = {}
}

variable "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool used for API authorization"
  type        = string
}
