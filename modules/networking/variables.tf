variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "subnet_cidrs" {
  description = "CIDR blocks for subnets"
  type        = list(string)
  default     = []
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
