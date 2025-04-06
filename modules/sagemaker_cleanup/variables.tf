variable "domain_ids" {
  description = "List of SageMaker domain IDs to clean up"
  type        = list(string)
  default     = []
}

variable "notebook_names" {
  description = "List of SageMaker notebook instance names to clean up"
  type        = list(string)
  default     = []
}

variable "aws_region" {
  description = "AWS region where resources are deployed"
  type        = string
}

variable "project_name" {
  description = "Name of the project for resource identification"
  type        = string
  default     = "protein-discovery"
}

variable "cleanup_timeout" {
  description = "Timeout in seconds for cleanup operations"
  type        = number
  default     = 600
}

variable "max_retries" {
  description = "Maximum number of retries for cleanup operations"
  type        = number
  default     = 3
}

variable "vpc_id" {
  description = "VPC ID for import operations"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID for import operations"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "Instance type for notebook import"
  type        = string
  default     = "ml.t3.medium"
}

variable "role_arn" {
  description = "Role ARN for notebook import"
  type        = string
  default     = ""
}
