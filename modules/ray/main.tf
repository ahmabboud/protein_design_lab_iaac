# Create a SageMaker App-based Ray cluster implementation
# Note: aws_sagemaker_cluster is not a supported resource type in the AWS provider
# Instead, we're using SageMaker domain apps with Ray configuration

# Define local values for Ray configuration
locals {
  cluster_name = "${var.project_name}-ray-cluster"
  ray_head_app_name = "${var.project_name}-${var.environment}-ray-head"
  ray_cpu_worker_app_name = "${var.project_name}-${var.environment}-ray-cpu-worker"
  ray_gpu_worker_app_name = "${var.project_name}-${var.environment}-ray-gpu-worker"
}

# Create lifecycle configs for Ray cluster nodes
resource "aws_sagemaker_studio_lifecycle_config" "ray_head_config" {
  studio_lifecycle_config_name = "${var.project_name}-${var.environment}-ray-head-config"
  studio_lifecycle_config_app_type = "JupyterServer"
  
  studio_lifecycle_config_content = base64encode(templatefile(
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
  
  studio_lifecycle_config_content = base64encode(templatefile(
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

# Create a null resource that will be used to set up Ray using AWS CLI
# This is a workaround until AWS provider supports SageMaker HyperPod
resource "null_resource" "ray_cluster_setup" {
  provisioner "local-exec" {
    command = <<-EOF
      echo "Setting up Ray cluster ${local.cluster_name}"
      
      # This is a placeholder for the actual Ray cluster setup command
      # In a real implementation, you would use AWS CLI commands to create and configure
      # SageMaker HyperPod cluster with Ray
      
      echo "Ray cluster setup would execute here with:"
      echo "Head node: ${var.ray_head_instance_type}"
      echo "CPU Workers: ${var.cpu_worker_count} x ${var.ray_cpu_instance_type}"
      echo "GPU Workers: ${var.gpu_worker_count} x ${var.ray_gpu_instance_type}"
    EOF
  }
  
  triggers = {
    head_instance_type = var.ray_head_instance_type
    cpu_worker_count = var.cpu_worker_count
    gpu_worker_count = var.gpu_worker_count
    ray_version = var.ray_version
  }
}
