# Networking module for Protein Design Lab

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment}-${var.project_name}-vpc"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.subnet_cidrs) >= 2 ? 2 : length(var.subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.environment}-${var.project_name}-private-subnet-${count.index}"
  }
}

resource "aws_subnet" "public" {
  count             = length(var.subnet_cidrs) >= 2 ? 2 : length(var.subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 100)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-${var.project_name}-public-subnet-${count.index}"
  }
}

data "aws_availability_zones" "available" {}

# Security groups
resource "aws_security_group" "sagemaker" {
  name        = "${var.environment}-${var.project_name}-sagemaker-sg"
  description = "Security group for SageMaker resources"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  # Allow HTTPS inbound for SageMaker
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS access from within VPC"
  }

  tags = {
    Name = "${var.environment}-${var.project_name}-sagemaker-sg"
    Environment = var.environment
    "caylent:owner" = var.caylent_owner
    "caylent:workload" = var.caylent_workload
    "caylent:project" = var.caylent_project
  }
}

resource "aws_security_group" "ray" {
  name        = "${var.environment}-${var.project_name}-ray-sg"
  description = "Security group for Ray cluster"
  vpc_id      = aws_vpc.main.id

  # Ray runs on SageMaker HyperPod with these instances:
  # - Head node: ml.m5.2xlarge (8 vCPU, 32 GiB memory)
  # - CPU worker nodes: ml.m5.4xlarge (16 vCPU, 64 GiB memory)
  # - GPU worker nodes: ml.g4dn.xlarge (4 vCPU, 16 GiB memory, 1 NVIDIA T4 GPU)
  
  # Allow all traffic within the security group for Ray cluster communication
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow all internal Ray cluster traffic"
  }
  
  # Allow SSH access from VPC
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH access from within VPC"
  }
  
  # Allow Ray dashboard access (port 8265)
  ingress {
    from_port   = 8265
    to_port     = 8265
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Ray dashboard access"
  }
  
  # Allow outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.environment}-${var.project_name}-ray-sg"
    Environment = var.environment
    "caylent:owner" = var.caylent_owner
    "caylent:workload" = var.caylent_workload
    "caylent:project" = var.caylent_project
  }
}
