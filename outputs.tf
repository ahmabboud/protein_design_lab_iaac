output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for protein data"
  value       = module.storage.protein_data_bucket_id
}

output "notebook_url" {
  description = "SageMaker notebook URL"
  value       = module.sagemaker.notebook_url
}

# Comment out or remove references to resources not yet implemented
# Some outputs may need to be reintroduced later as the modules are completed

# output "sagemaker_domain_id" {
#   description = "SageMaker domain ID"
#   value       = module.sagemaker.domain_id
# }

# output "sagemaker_user_profile_name" {
#   description = "SageMaker user profile name"
#   value       = module.sagemaker.user_profile_name
# }

# output "ray_cluster_name" {
#   description = "Ray cluster name"
#   value       = module.ray_cluster.cluster_name
# }

# output "pipeline_name" {
#   description = "SageMaker pipeline name"
#   value       = module.pipeline.pipeline_name
# }

# output "fsx_dns_name" {
#   description = "FSx for Lustre filesystem DNS name"
#   value       = module.storage.fsx_dns_name
# }
