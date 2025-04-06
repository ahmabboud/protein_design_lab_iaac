# IAM Module for Protein Design Lab

resource "aws_iam_role" "sagemaker_role" {
  name = "${var.project_name}-sagemaker-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      }
    ]
  })
  
  # Missing Caylent tags
  tags = {
    Name = "${var.project_name}-sagemaker-role"
    Environment = var.environment
    "caylent:owner" = var.caylent_owner
    "caylent:workload" = var.caylent_workload
    "caylent:project" = var.caylent_project
  }
}

# Attach necessary policies to the SageMaker role
resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Add tagging permissions for cleanup operations
resource "aws_iam_policy" "resource_tagging_permissions" {
  name        = "${var.project_name}-resource-tagging-policy"
  description = "Policy for AWS Resource Groups Tagging API operations"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "tag:GetResources",
          "tag:GetTagKeys",
          "tag:GetTagValues",
          "tag:TagResources",
          "tag:UntagResources"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
  
  # Missing Caylent tags
  tags = {
    Name = "${var.project_name}-resource-tagging-policy"
    Environment = var.environment
    "caylent:owner" = var.caylent_owner
    "caylent:workload" = var.caylent_workload
    "caylent:project" = var.caylent_project
  }
}

resource "aws_iam_role_policy_attachment" "tagging_policy_attachment" {
  role       = aws_iam_role.sagemaker_role.name
  policy_arn = aws_iam_policy.resource_tagging_permissions.arn
}
