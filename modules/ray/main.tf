# Create SageMaker HyperPod cluster for Ray
resource "aws_sagemaker_cluster" "ray_hyperpod_cluster" {
  cluster_name = "${var.project_name}-ray-cluster"
  
  instance_groups {
    instance_group_name = "ray-head"
    instance_type       = var.ray_head_instance_type
    instance_count      = 1
    lifecycle_config_arn = aws_sagemaker_studio_lifecycle_config.ray_head_config.arn
  }
  
  instance_groups {
    instance_group_name = "ray-worker-cpu"
    instance_type       = var.ray_cpu_instance_type
    instance_count      = var.cpu_worker_count
    lifecycle_config_arn = aws_sagemaker_studio_lifecycle_config.ray_worker_config.arn
  }
  
  instance_groups {
    instance_group_name = "ray-worker-gpu"
    instance_type       = var.ray_gpu_instance_type
    instance_count      = var.gpu_worker_count
    lifecycle_config_arn = aws_sagemaker_studio_lifecycle_config.ray_worker_config.arn
  }
  
  role_arn = var.sagemaker_role_arn
  
  tags = {
    Name = "${var.project_name}-ray-cluster"
    Environment = var.environment
  }
}

# Create lifecycle configs for Ray cluster nodes
resource "aws_sagemaker_studio_lifecycle_config" "ray_head_config" {
  studio_lifecycle_config_name = "${var.project_name}-${var.environment}-ray-head-config"
  studio_lifecycle_config_app_type = "JupyterServer"
  
  content = base64encode(templatefile(
    "${path.module}/templates/ray_head_config.tpl",
    {
      ray_version = var.ray_version
    }
  ))

  tags = {
    Name = "${var.project_name}-${var.environment}-ray-head-config"
    Environment = var.environment
    "caylent:owner" = var.caylent_owner
    "caylent:workload" = var.caylent_workload
    "caylent:project" = var.caylent_project
  }
}

resource "aws_sagemaker_studio_lifecycle_config" "ray_worker_config" {
  studio_lifecycle_config_name = "${var.project_name}-${var.environment}-ray-worker-config"
  studio_lifecycle_config_app_type = "JupyterServer"
  
  content = base64encode(templatefile(
    "${path.module}/templates/ray_worker_config.tpl",
    {
      ray_version = var.ray_version
    }
  ))

  tags = {
    Name = "${var.project_name}-${var.environment}-ray-worker-config"
    Environment = var.environment
    "caylent:owner" = var.caylent_owner
    "caylent:workload" = var.caylent_workload
    "caylent:project" = var.caylent_project
  }
}
