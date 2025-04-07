# SageMaker Cleanup Module
# This module handles SageMaker resource cleanup using AWS CLI commands via null_resources

# Get user profiles through local-exec instead of invalid data source
resource "null_resource" "list_user_profiles" {
  for_each = toset(var.domain_ids)
  
  provisioner "local-exec" {
    command = <<-EOF
      echo "Listing user profiles for domain: ${each.key}"
      aws sagemaker list-user-profiles \
        --domain-id ${each.key} \
        --region ${var.aws_region} \
        --output json > ${path.module}/user_profiles_${each.key}.json
    EOF
    interpreter = ["/bin/bash", "-c"]
    on_failure = continue
  }
}

# Stop notebook instances before deletion
resource "null_resource" "stop_notebooks" {
  for_each = toset(var.notebook_names)
  
  provisioner "local-exec" {
    command = <<-EOF
      echo "Stopping SageMaker Notebook: ${each.key}"
      aws sagemaker stop-notebook-instance \
        --notebook-instance-name ${each.key} \
        --region ${var.aws_region}
      
      # Wait for notebook to stop (with timeout)
      timeout=${var.cleanup_timeout}
      while [ $timeout -gt 0 ]; do
        status=$(aws sagemaker describe-notebook-instance \
          --notebook-instance-name ${each.key} \
          --region ${var.aws_region} \
          --query 'NotebookInstanceStatus' --output text || echo "ERROR")
        
        if [ "$status" = "Stopped" ]; then
          echo "Notebook ${each.key} stopped successfully"
          break
        elif [ "$status" = "ERROR" ]; then
          echo "Error checking notebook status, continuing..."
          break
        fi
        
        echo "Waiting for notebook ${each.key} to stop... Status: $status"
        sleep 10
        timeout=$((timeout - 10))
      done
      
      if [ $timeout -le 0 ]; then
        echo "Timed out waiting for notebook ${each.key} to stop"
      fi
    EOF
    interpreter = ["/bin/bash", "-c"]
    on_failure = continue
  }
}

# Clean up user profiles - using a simplified approach
resource "null_resource" "cleanup_user_profiles" {
  for_each = toset(var.domain_ids)
  
  provisioner "local-exec" {
    command = <<-EOF
      echo "Finding and deleting user profiles for domain: ${each.key}"
      # If the profiles JSON file exists, use it
      if [ -f "${path.module}/user_profiles_${each.key}.json" ]; then
        profiles=$(cat "${path.module}/user_profiles_${each.key}.json" | jq -r '.UserProfiles[].UserProfileName')
        
        for profile in $profiles; do
          echo "Deleting SageMaker User Profile: $profile in domain ${each.key}"
          for i in $(seq 1 ${var.max_retries}); do
            aws sagemaker delete-user-profile \
              --domain-id ${each.key} \
              --user-profile-name "$profile" \
              --region ${var.aws_region} && break
            
            echo "Retry $i: Failed to delete user profile, retrying in 10 seconds..."
            sleep 10
          done
        done
      else
        echo "No user profile list found for domain ${each.key}. Skipping user profile cleanup."
      fi
    EOF
    interpreter = ["/bin/bash", "-c"]
    on_failure = continue
  }
  
  depends_on = [null_resource.list_user_profiles]
}

# Clean up domains after user profiles
resource "null_resource" "cleanup_domains" {
  for_each = toset(var.domain_ids)
  
  provisioner "local-exec" {
    command = <<-EOF
      echo "Deleting SageMaker Domain: ${each.key}"
      # Wait for a short time to allow user profile deletions to complete
      sleep 30
      
      for i in $(seq 1 ${var.max_retries}); do
        aws sagemaker delete-domain \
          --domain-id ${each.key} \
          --region ${var.aws_region} && break
        
        echo "Retry $i: Failed to delete domain, retrying in 20 seconds..."
        sleep 20
      done
    EOF
    interpreter = ["/bin/bash", "-c"]
    on_failure = continue
  }
  
  depends_on = [null_resource.cleanup_user_profiles]
}

# Clean up notebook instances
resource "null_resource" "delete_notebooks" {
  for_each = toset(var.notebook_names)
  
  provisioner "local-exec" {
    command = <<-EOF
      echo "Deleting SageMaker Notebook: ${each.key}"
      for i in $(seq 1 ${var.max_retries}); do
        aws sagemaker delete-notebook-instance \
          --notebook-instance-name ${each.key} \
          --region ${var.aws_region} && break
        
        echo "Retry $i: Failed to delete notebook instance, retrying in 10 seconds..."
        sleep 10
      done
    EOF
    interpreter = ["/bin/bash", "-c"]
    on_failure = continue
  }
  
  depends_on = [null_resource.stop_notebooks]
}

# Output cleanup logs for debugging
resource "local_file" "cleanup_log" {
  content  = "SageMaker cleanup completed at ${timestamp()}\nDomains: ${jsonencode(var.domain_ids)}\nNotebooks: ${jsonencode(var.notebook_names)}"
  filename = "${path.module}/sagemaker_cleanup_${formatdate("YYYY-MM-DD-hh-mm-ss", timestamp())}.log"
}
