variable "bucket_names" {
  description = "List of S3 bucket names to clean up"
  type        = list(string)
  default     = []
}
