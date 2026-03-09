variable "regions" {
  description = "Regions to deploy compute resources to"
  type        = set(string)
  default = []
}

variable "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool used for API authorization"
  type        = string
}
