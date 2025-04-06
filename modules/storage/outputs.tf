output "protein_data_bucket_id" {
  description = "ID of the S3 bucket for protein data"
  value       = aws_s3_bucket.protein_data_bucket.id
}

output "protein_data_bucket_arn" {
  description = "ARN of the S3 bucket for protein data"
  value       = aws_s3_bucket.protein_data_bucket.arn
}
