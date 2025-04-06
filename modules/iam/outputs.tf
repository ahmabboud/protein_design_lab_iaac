output "sagemaker_role_arn" {
  description = "ARN of the SageMaker execution role"
  value       = aws_iam_role.sagemaker_role.arn
}

output "sagemaker_role_name" {
  description = "Name of the SageMaker execution role"
  value       = aws_iam_role.sagemaker_role.name
}
