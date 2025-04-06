variable "environment" {
  description = "Environment name"
  type        = string
}

variable "instance_type" {
  description = "SageMaker notebook instance type"
  type        = string
  default     = "ml.t3.medium"
}

variable "subnet_ids" {
  description = "Subnet IDs for SageMaker"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for SageMaker"
  type        = list(string)
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "sagemaker_role_arn" {
  description = "ARN of the SageMaker execution role"
  type        = string
  default     = ""
}

variable "sagemaker_user_name" {
  description = "Username for SageMaker user profile"
  type        = string
  default     = "protein-researcher"
}

variable "caylent_workload" {
  description = "Value for caylent:workload tag"
  type        = string
  default     = "protein_lab_1"
}

variable "caylent_project" {
  description = "Value for caylent:project tag"
  type        = string
  default     = "protein_experiment"
}

variable "caylent_owner" {
  description = "Value for caylent:owner tag"
  type        = string
  default     = "ahmad.abboud@caylent.com"
}
