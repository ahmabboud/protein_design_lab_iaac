variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  description = "Name of the protein discovery project"
  type        = string
  default     = "protein-discovery"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for the subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "sagemaker_user_name" {
  description = "Username for SageMaker user profile"
  type        = string
  default     = "protein-researcher"
}

variable "cpu_worker_count" {
  description = "Number of CPU worker nodes in Ray cluster"
  type        = number
  default     = 2
}

variable "gpu_worker_count" {
  description = "Number of GPU worker nodes in Ray cluster"
  type        = number
  default     = 1
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
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

variable "sagemaker_instance_type" {
  description = "Instance type for SageMaker notebook"
  type        = string
  default     = "ml.t3.medium"
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
  default     = "ahmad.abboud@caylent.com"
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
