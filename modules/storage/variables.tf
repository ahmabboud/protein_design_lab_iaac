variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "suffix" {
  description = "Suffix for globally unique resource names"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for FSx filesystem"
  type        = string
  default     = ""
}

variable "fsx_storage_capacity" {
  description = "Storage capacity for FSx Lustre filesystem (GB)"
  type        = number
  default     = 1200
}

variable "fsx_deployment_type" {
  description = "Deployment type for FSx Lustre filesystem"
  type        = string
  default     = "SCRATCH_2"
}

variable "fsx_storage_type" {
  description = "Storage type for FSx Lustre filesystem"
  type        = string
  default     = "SSD"
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
