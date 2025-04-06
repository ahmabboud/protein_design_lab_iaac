output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.sagemaker_vpc.id
}

output "subnet_ids" {
  description = "The IDs of the subnets"
  value       = [aws_subnet.sagemaker_subnet_1.id, aws_subnet.sagemaker_subnet_2.id]
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for protein data"
  value       = aws_s3_bucket.protein_data_bucket.id
}

output "sagemaker_domain_id" {
  description = "SageMaker domain ID"
  value       = aws_sagemaker_domain.protein_discovery_domain.id
}

output "sagemaker_user_profile_name" {
  description = "SageMaker user profile name"
  value       = aws_sagemaker_user_profile.protein_discovery_user.user_profile_name
}

output "ray_cluster_name" {
  description = "Ray cluster name"
  value       = aws_sagemaker_cluster.ray_hyperpod_cluster.cluster_name
}

output "pipeline_name" {
  description = "SageMaker pipeline name"
  value       = aws_sagemaker_pipeline.protein_discovery_pipeline.pipeline_name
}

output "fsx_dns_name" {
  description = "FSx for Lustre filesystem DNS name"
  value       = aws_fsx_lustre_file_system.ray_fsx.dns_name
}
