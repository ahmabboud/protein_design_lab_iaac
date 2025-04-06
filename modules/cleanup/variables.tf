variable "project_tag_value" {
  description = "Value of the caylent:project tag to identify resources for cleanup"
  type        = string
}

variable "workload_tag_value" {
  description = "Value of the caylent:workload tag to identify resources for cleanup"
  type        = string
}

variable "aws_region" {
  description = "AWS region to target for cleanup"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for referenced resources"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Subnet ID for referenced resources"
  type        = string
  default     = ""
}

variable "role_arn" {
  description = "IAM role ARN for referenced resources"
  type        = string
  default     = ""
}

variable "dry_run" {
  description = "If true, show what would be deleted without actually deleting"
  type        = bool
  default     = false
}

variable "description" {
  description = "Description of the cleanup operation"
  type        = string
  default     = "Resource cleanup operation"
}
