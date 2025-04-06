output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "sagemaker_sg_id" {
  description = "Security group ID for SageMaker"
  value       = aws_security_group.sagemaker.id
}

output "ray_sg_id" {
  description = "Security group ID for Ray cluster"
  value       = aws_security_group.ray.id
}
