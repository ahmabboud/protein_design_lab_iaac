output "notebook_url" {
  description = "URL of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.protein_design.url
}

output "notebook_arn" {
  description = "ARN of the SageMaker notebook instance"
  value       = aws_sagemaker_notebook_instance.protein_design.arn
}
