# Main cleanup configuration
# To use: terraform apply -target=module.cleanup

module "cleanup" {
  source = "./modules/cleanup"
  
  project_tag_value  = var.caylent_project
  workload_tag_value = var.caylent_workload
  aws_region         = var.aws_region
  vpc_id             = module.networking.vpc_id
  subnet_id          = module.networking.private_subnet_ids[0]
  role_arn           = module.iam.sagemaker_role_arn
  
  # Add ability to control whether to actually perform deletions
  dry_run            = var.cleanup_dry_run
  
  # Add describer for what's being cleaned up
  description        = "Cleaning up ${var.project_name} protein discovery resources"
}
