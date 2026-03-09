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

variable "test_user_email" {
  description = "Email for the test user"
  type        = string
}

variable "test_user_password" {
  description = "Temporary password for the test user"
  type        = string
  sensitive   = true
}
