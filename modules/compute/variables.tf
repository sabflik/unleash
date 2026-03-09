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

variable "container_image" {
  description = "Docker image URI for ECS task"
  type        = string
  default     = "amazon/aws-cli:latest"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 80
}

variable "ecs_task_cpu" {
  description = "CPU units for ECS task (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "Memory for ECS task in MB"
  type        = string
  default     = "512"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks to run"
  type        = number
  default     = 1
}
