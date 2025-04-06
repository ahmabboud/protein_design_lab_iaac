# Terraform-based Cleanup Module for Protein Discovery Lab Infrastructure
# This module will find and destroy resources based on tags

# Find resources based on project tags
data "aws_resourcegroupstaggingapi_resources" "project_resources" {
  tag_filter {
    key = "caylent:project"
    values = [var.project_tag_value]
  }
}

data "aws_resourcegroupstaggingapi_resources" "workload_resources" {
  tag_filter {
    key = "caylent:workload"
    values = [var.workload_tag_value]
  }
}

# Extract S3 bucket ARNs for cleanup
locals {
  # Extract resource ARNs and organize by type
  s3_bucket_arns = [
    for resource in data.aws_resourcegroupstaggingapi_resources.project_resources.resource_tag_mapping_list :
    resource.resource_arn if length(regexall("^arn:aws:s3", resource.resource_arn)) > 0
  ]
  
  s3_bucket_names = [
    for arn in local.s3_bucket_arns :
    split(":", arn)[5]
  ]
  
  sagemaker_domain_arns = [
    for resource in data.aws_resourcegroupstaggingapi_resources.project_resources.resource_tag_mapping_list :
    resource.resource_arn if length(regexall("^arn:aws:sagemaker.*:domain/", resource.resource_arn)) > 0
  ]
  
  sagemaker_notebook_arns = [
    for resource in data.aws_resourcegroupstaggingapi_resources.project_resources.resource_tag_mapping_list :
    resource.resource_arn if length(regexall("^arn:aws:sagemaker.*:notebook-instance/", resource.resource_arn)) > 0
  ]
  
  # Extract resource IDs from ARNs
  sagemaker_domain_ids = [
    for arn in local.sagemaker_domain_arns :
    element(split("/", arn), length(split("/", arn)) - 1)
  ]
  
  sagemaker_notebook_names = [
    for arn in local.sagemaker_notebook_arns :
    element(split("/", arn), length(split("/", arn)) - 1)
  ]
}

# Clear out S3 buckets first before deleting them
resource "null_resource" "empty_s3_buckets" {
  for_each = toset(local.s3_bucket_names)
  
  provisioner "local-exec" {
    command = "aws s3 rm s3://${each.key} --recursive"
  }
}

# Cleanup resources using Terraform destroy
module "cleanup_s3" {
  source = "../s3_cleanup"
  count  = length(local.s3_bucket_names) > 0 ? 1 : 0
  
  bucket_names = local.s3_bucket_names
  depends_on   = [null_resource.empty_s3_buckets]
}

module "cleanup_sagemaker" {
  source = "../sagemaker_cleanup"
  count  = length(local.sagemaker_domain_ids) > 0 || length(local.sagemaker_notebook_names) > 0 ? 1 : 0
  
  domain_ids     = local.sagemaker_domain_ids
  notebook_names = local.sagemaker_notebook_names
}

# Root module can call terraform destroy on this cleanup module once resources are identified

# RECOMMENDATION: Add the following policy to any IAM role used for cleanup:
# "Action": [
#   "tag:GetResources",
#   "tag:GetTagKeys",
#   "tag:GetTagValues"
# ]
