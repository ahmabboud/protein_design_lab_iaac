# Main Terraform configuration for Protein Design Lab Infrastructure

provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
  default_tags {
    tags = {
      "caylent:owner" = var.caylent_owner
      "caylent:workload" = var.caylent_workload
      "caylent:project" = var.caylent_project
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Create random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Module references
module "networking" {
  source      = "./modules/networking"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  project_name = var.project_name
  subnet_cidrs = var.subnet_cidrs
  caylent_owner = var.caylent_owner
  caylent_workload = var.caylent_workload
  caylent_project = var.caylent_project
}

module "storage" {
  source      = "./modules/storage"
  environment = var.environment
  project_name = var.project_name
  suffix = random_string.suffix.result
  fsx_storage_capacity = var.fsx_storage_capacity
  fsx_deployment_type = var.fsx_deployment_type
  fsx_storage_type = var.fsx_storage_type
  caylent_owner = var.caylent_owner
  caylent_workload = var.caylent_workload
  caylent_project = var.caylent_project
}

module "iam" {
  source = "./modules/iam"
  environment = var.environment
  project_name = var.project_name
  caylent_owner = var.caylent_owner
  caylent_workload = var.caylent_workload
  caylent_project = var.caylent_project
}

module "sagemaker" {
  source           = "./modules/sagemaker"
  environment      = var.environment
  subnet_ids       = module.networking.private_subnet_ids
  security_group_ids = [module.networking.sagemaker_sg_id]
  project_name     = var.project_name
  sagemaker_role_arn = module.iam.sagemaker_role_arn
  instance_type    = var.sagemaker_instance_type
  sagemaker_user_name = var.sagemaker_user_name
  caylent_workload = var.caylent_workload
  caylent_project  = var.caylent_project
  caylent_owner    = var.caylent_owner
  depends_on       = [module.networking]
}

module "ray_cluster" {
  source           = "./modules/ray"
  environment      = var.environment
  vpc_id           = module.networking.vpc_id
  subnet_ids       = module.networking.private_subnet_ids
  security_group_ids = [module.networking.ray_sg_id]
  project_name     = var.project_name
  sagemaker_role_arn = module.iam.sagemaker_role_arn
  storage_bucket_id = module.storage.protein_data_bucket_id
  account_id       = var.account_id
  aws_region       = var.aws_region
  cpu_worker_count = var.cpu_worker_count
  gpu_worker_count = var.gpu_worker_count
  ray_head_instance_type = var.ray_head_instance_type
  ray_cpu_instance_type = var.ray_cpu_instance_type
  ray_gpu_instance_type = var.ray_gpu_instance_type
  min_capacity_param = var.min_capacity_param
  max_capacity_param = var.max_capacity_param
  caylent_owner    = var.caylent_owner
  caylent_workload = var.caylent_workload
  caylent_project  = var.caylent_project
  depends_on       = [module.networking, module.storage]
}
