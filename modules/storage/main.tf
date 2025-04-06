# Storage module for Protein Design Lab

# Create S3 bucket for data storage
resource "aws_s3_bucket" "protein_data_bucket" {
  bucket = "${var.project_name}-${var.environment}-data-${var.suffix}"
  force_destroy = true

  tags = {
    Name = "${var.project_name}-data-bucket"
    Environment = var.environment
    "caylent:owner" = var.caylent_owner
    "caylent:workload" = var.caylent_workload
    "caylent:project" = var.caylent_project
  }
}

# Enable versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "protein_data_versioning" {
  bucket = aws_s3_bucket.protein_data_bucket.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Create FSx for Lustre file system for Ray cluster
resource "aws_fsx_lustre_file_system" "ray_fsx" {
  storage_capacity    = var.fsx_storage_capacity
  subnet_ids          = [var.subnet_id]
  deployment_type     = var.fsx_deployment_type
  storage_type        = var.fsx_storage_type
  
  tags = {
    Name = "${var.project_name}-fsx"
    Environment = var.environment
    "caylent:owner" = var.caylent_owner
    "caylent:workload" = var.caylent_workload
    "caylent:project" = var.caylent_project
  }
}
