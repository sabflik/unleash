variable "user_pool_name" {
  description = "Name for the Cognito user pool"
  type        = string
  default     = "user_pool"
}

variable "user_pool_client_name" {
  description = "Name for the Cognito user pool client"
  type        = string
  default     = "user_pool_client"
}
