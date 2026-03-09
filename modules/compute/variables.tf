variable "regions" {
  description = "Regions to deploy compute resources to"
  type        = set(string)
  default = []
}

variable "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool used for API authorization"
  type        = string
}

variable "vpc_cidr" {
  description = "Map of region to VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Map of region to public subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}
