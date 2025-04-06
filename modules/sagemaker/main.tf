# SageMaker resources for Protein Design Lab

resource "aws_sagemaker_notebook_instance" "protein_design" {
  name                    = "${var.environment}-protein-design-notebook"
  role_arn                = aws_iam_role.sagemaker_execution_role.arn
  instance_type           = var.instance_type
  subnet_id               = var.subnet_ids[0]
  security_groups         = var.security_group_ids
  lifecycle_config_name   = aws_sagemaker_notebook_instance_lifecycle_configuration.setup.name
  
  tags = {
    Name = "${var.environment}-protein-design-notebook"
    Project = var.project_name
  }
}

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "setup" {
  name     = "${var.environment}-protein-design-notebook-lifecycle"
  on_start = base64encode(<<-EOF
    #!/bin/bash
    set -e
    
    # Install required packages for protein design
    sudo -u ec2-user -i <<'EOF2'
    conda create -n protein-design python=3.9 -y
    source activate protein-design
    pip install -U ray[all] pytorch biopython biotite
    EOF2
  EOF
  )
  
  tags = {
    "caylent:workload" = var.caylent_workload
    "caylent:project" = var.caylent_project
    "caylent:owner" = var.caylent_owner
  }
}

resource "aws_iam_role" "sagemaker_execution_role" {
  name = "${var.environment}-sagemaker-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      },
    ]
  })
  
  tags = {
    "caylent:workload" = var.caylent_workload
    "caylent:project" = var.caylent_project
    "caylent:owner" = var.caylent_owner
  }
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}
