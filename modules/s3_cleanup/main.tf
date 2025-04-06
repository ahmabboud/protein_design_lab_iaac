# S3 Cleanup Module
# This module handles S3 bucket cleanup

resource "aws_s3_bucket" "bucket_cleanup" {
  for_each      = toset(var.bucket_names)
  bucket        = each.key
  force_destroy = true
}

# The buckets will be destroyed when this module is destroyed
