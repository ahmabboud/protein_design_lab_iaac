variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "sagemaker_role_arn" {
  description = "ARN of the SageMaker execution role"
  type        = string
}

variable "storage_bucket_id" {
  description = "ID of the S3 bucket for storage"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cpu_worker_count" {
  description = "Number of CPU worker nodes"
  type        = number
  default     = 2
}

variable "gpu_worker_count" {
  description = "Number of GPU worker nodes"
  type        = number
  default     = 1
}

variable "ray_head_instance_type" {
  description = "Instance type for Ray head node"
  type        = string
  default     = "ml.m5.2xlarge"
}

variable "ray_cpu_instance_type" {
  description = "Instance type for Ray CPU worker nodes"
  type        = string
  default     = "ml.m5.4xlarge"
}

variable "ray_gpu_instance_type" {
  description = "Instance type for Ray GPU worker nodes"
  type        = string
  default     = "ml.g4dn.xlarge"
}

variable "ray_version" {
  description = "Ray version to install"
  type        = string
  default     = "2.6.1"
}

variable "min_capacity_param" {
  description = "Minimum capacity for auto-scaling"
  type        = number
  default     = 1
}

variable "max_capacity_param" {
  description = "Maximum capacity for auto-scaling"
  type        = number
  default     = 5
}

variable "caylent_owner" {
  description = "Value for caylent:owner tag"
  type        = string
}

variable "caylent_workload" {
  description = "Value for caylent:workload tag"
  type        = string
}

variable "caylent_project" {
  description = "Value for caylent:project tag"
  type        = string
}
