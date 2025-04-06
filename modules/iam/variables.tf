variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

# Add missing tag variables if not already defined
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
