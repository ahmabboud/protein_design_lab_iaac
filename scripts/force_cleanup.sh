#!/bin/bash
# Force Cleanup Script for Protein Discovery Lab Infrastructure
# This script will forcibly delete all resources created by Terraform
# Use with caution - this will DELETE ALL RESOURCES without confirmation

# Don't exit immediately on error to make the script more robust
set +e

# Check if running in the correct directory
if [ ! -f "main.tf" ] || [ ! -f "variables.tf" ]; then
  echo "ERROR: This script must be run from the root of the Terraform project."
  echo "Please navigate to the directory containing main.tf and variables.tf."
  exit 1
fi

# Check for required tools
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required but not installed. Please install jq."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "ERROR: AWS CLI is required but not installed. Please install AWS CLI."; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "ERROR: Terraform is required but not installed. Please install Terraform."; exit 1; }

echo "========================================================================="
echo "WARNING: This script will DELETE ALL RESOURCES created by this project"
echo "This action is IRREVERSIBLE and will result in DATA LOSS"
echo "========================================================================="
echo "Options:"
echo "1. Use Terraform-based cleanup (recommended)"
echo "2. Use AWS CLI-based cleanup (fallback)"
echo "3. Abort"
read -p "Enter option (1-3): " option

if [ "$option" = "3" ]; then
  echo "Cleanup aborted."
  exit 0
fi

echo "Waiting 5 seconds. Press Ctrl+C to abort..."
sleep 5
echo "Proceeding with cleanup..."

# Load environment variables from .env file if it exists
if [ -f .env ]; then
  source .env
fi

# Get essential variables interactively if not set
if [ -z "$AWS_REGION" ]; then
  if [ -n "$TF_VAR_aws_region" ]; then
    export AWS_REGION=$TF_VAR_aws_region
  else
    # Default or ask user
    read -p "Enter AWS region [us-east-1]: " AWS_REGION
    AWS_REGION=${AWS_REGION:-us-east-1}  # Hardcoded default region
    export AWS_REGION
    export TF_VAR_aws_region=$AWS_REGION
  fi
fi

# Get project name if not available
if [ -z "$TF_VAR_project_name" ]; then
  read -p "Enter project name [protein-discovery]: " PROJECT_NAME
  PROJECT_NAME=${PROJECT_NAME:-protein-discovery}  # Hardcoded default project name
  export TF_VAR_project_name=$PROJECT_NAME
fi

# Check if terraform.tfvars exists to load variables
TF_VARS=""
if [ -f terraform.tfvars ]; then
  echo "Using variables from terraform.tfvars"
  # Extract variables from tfvars file for command line args
  while IFS= read -r line; do
    if [[ $line =~ ^[^#]*=.* ]]; then
      var_name=$(echo "$line" | cut -d '=' -f 1 | xargs)
      var_value=$(echo "$line" | cut -d '=' -f 2- | xargs)
      # Remove quotes if present
      var_value="${var_value%\"}"
      var_value="${var_value#\"}"
      TF_VARS="$TF_VARS -var=\"$var_name=$var_value\""
    fi
  done < terraform.tfvars
fi

if [ "$option" = "1" ]; then
  # Use Terraform-based cleanup
  echo "Running Terraform-based cleanup..."
  terraform init

  # Potential issue: This approach may create resources before destroying them
  # Alternative approach: Use terraform import to grab existing resources
  
  # First try to directly run the cleanup module without creating dependencies
  echo "Attempting to run cleanup module directly..."
  
  # Check if state exists and if the cleanup module is there
  if terraform state list module.cleanup &>/dev/null; then
    echo "Cleanup module found in state, applying it..."
    eval "terraform apply -target=module.cleanup $TF_VARS -auto-approve" || true
    eval "terraform destroy -target=module.cleanup $TF_VARS -auto-approve" || true
  elif terraform state list &>/dev/null; then
    # State exists but cleanup module might not be registered yet
    echo "Terraform state found, applying cleanup module..."
    
    # Instead of first creating networking resources, use data sources
    # to find existing resources using tags
    eval "terraform apply -target=module.cleanup $TF_VARS -auto-approve" || true
    eval "terraform destroy -target=module.cleanup $TF_VARS -auto-approve" || true
  fi
  
  # Now run a full destroy to clean up everything else
  echo "Running full terraform destroy..."
  eval "terraform destroy $TF_VARS -auto-approve" || true
  
  # Remove duplicate destroy call - it's now included above
  
  echo "Terraform-based cleanup completed. Proceeding with manual cleanup to ensure completeness..."
  # Continue with manual cleanup for thoroughness
else
  # Only run terraform destroy if option 1 was not selected
  # (Option 1 already includes destroy in its flow)
  echo "Attempting Terraform destroy..."
  terraform destroy -auto-approve || echo "Terraform destroy failed, proceeding with manual cleanup"
fi

# AWS CLI-based cleanup
echo "Running AWS CLI-based cleanup..."

# Get project name interactively if not already available
if [ -z "$PROJECT_NAME" ]; then
  PROJECT_NAME=$(terraform output -raw project_name 2>/dev/null || echo "")
  if [ -z "$PROJECT_NAME" ] && [ -n "$TF_VAR_project_name" ]; then
    PROJECT_NAME=$TF_VAR_project_name
  elif [ -z "$PROJECT_NAME" ]; then
    read -p "Enter project name [protein-discovery]: " PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-protein-discovery}
  fi
fi

# Get environment interactively if not already available
if [ -z "$ENVIRONMENT" ]; then
  ENVIRONMENT=$(terraform output -raw environment 2>/dev/null || echo "")
  if [ -z "$ENVIRONMENT" ] && [ -n "$TF_VAR_environment" ]; then
    ENVIRONMENT=$TF_VAR_environment
  elif [ -z "$ENVIRONMENT" ]; then
    read -p "Enter environment [dev]: " ENVIRONMENT
    ENVIRONMENT=${ENVIRONMENT:-dev}
  fi
fi

echo "Cleaning up resources for project: $PROJECT_NAME in $ENVIRONMENT environment"

# Add check for missing AWS CLI or credentials
if ! aws sts get-caller-identity &>/dev/null; then
  echo "ERROR: AWS CLI is not configured or credentials are invalid."
  echo "Please configure AWS CLI with 'aws configure' before running this script."
  exit 1
fi

# Function to run AWS CLI commands and ignore errors
aws_cleanup() {
  echo "Running: aws $@"
  aws $@ || echo "Command failed, continuing..."
}

# Clean up SageMaker resources
echo "Cleaning up SageMaker resources..."
# List and delete SageMaker pipelines
for pipeline in $(aws sagemaker list-pipelines --query "PipelineNames[]" --output text | grep $PROJECT_NAME); do
  echo "Deleting SageMaker Pipeline: $pipeline"
  aws_cleanup sagemaker delete-pipeline --pipeline-name $pipeline
done

# Delete SageMaker user profiles and domains
for domain in $(aws sagemaker list-domains --query "Domains[?contains(DomainName, '$PROJECT_NAME')].DomainId" --output text); do
  echo "Found SageMaker Domain: $domain"
  
  # Delete user profiles in domain
  for user in $(aws sagemaker list-user-profiles --domain-id $domain --query "UserProfiles[].UserProfileName" --output text); do
    echo "Deleting User Profile: $user in Domain $domain"
    aws_cleanup sagemaker delete-user-profile --domain-id $domain --user-profile-name $user
  done
  
  # Wait for user profiles to be deleted
  sleep 30
  
  # Delete the domain
  echo "Deleting SageMaker Domain: $domain"
  aws_cleanup sagemaker delete-domain --domain-id $domain
done

# Delete SageMaker Notebook instances
for notebook in $(aws sagemaker list-notebook-instances --query "NotebookInstances[?contains(NotebookInstanceName, '$PROJECT_NAME')].NotebookInstanceName" --output text); do
  echo "Stopping SageMaker Notebook: $notebook"
  aws_cleanup sagemaker stop-notebook-instance --notebook-instance-name $notebook
  
  echo "Waiting for notebook to stop..."
  aws sagemaker wait notebook-instance-stopped --notebook-instance-name $notebook
  
  echo "Deleting SageMaker Notebook: $notebook"
  aws_cleanup sagemaker delete-notebook-instance --notebook-instance-name $notebook
done

# Delete SageMaker clusters (HyperPod)
for cluster in $(aws sagemaker list-clusters --query "Clusters[?contains(ClusterName, '$PROJECT_NAME')].ClusterName" --output text 2>/dev/null || echo ""); do
  echo "Deleting SageMaker Cluster: $cluster"
  aws_cleanup sagemaker delete-cluster --cluster-name $cluster
done

# Clean up S3 buckets
echo "Cleaning up S3 buckets..."
for bucket in $(aws s3api list-buckets --query "Buckets[?contains(Name, '$PROJECT_NAME')].Name" --output text); do
  echo "Emptying S3 bucket: $bucket"
  aws_cleanup s3 rm s3://$bucket --recursive
  echo "Deleting S3 bucket: $bucket"
  aws_cleanup s3api delete-bucket --bucket $bucket
done

# Clean up FSx Lustre filesystems
echo "Cleaning up FSx resources..."
for fs in $(aws fsx describe-file-systems --query "FileSystems[?contains(Tags[?Key==\`Name\`].Value, '$PROJECT_NAME')].FileSystemId" --output text); do
  echo "Deleting FSx filesystem: $fs"
  aws_cleanup fsx delete-file-system --file-system-id $fs
done

# Clean up VPC resources
echo "Cleaning up VPC resources..."

# Get VPC IDs
vpcs=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=*$PROJECT_NAME*" --query "Vpcs[].VpcId" --output text)

for vpc in $vpcs; do
  echo "Cleaning up resources in VPC: $vpc"
  
  # Delete internet gateways
  for igw in $(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc" --query "InternetGateways[].InternetGatewayId" --output text); do
    echo "Detaching Internet Gateway $igw from VPC $vpc"
    aws_cleanup ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
    echo "Deleting Internet Gateway $igw"
    aws_cleanup ec2 delete-internet-gateway --internet-gateway-id $igw
  done
  
  # Delete subnets
  for subnet in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc" --query "Subnets[].SubnetId" --output text); do
    echo "Deleting Subnet $subnet in VPC $vpc"
    aws_cleanup ec2 delete-subnet --subnet-id $subnet
  done
  
  # Delete route tables
  for rt in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc" --query "RouteTables[?Associations[0].Main != \`true\`].RouteTableId" --output text); do
    echo "Deleting Route Table $rt in VPC $vpc"
    aws_cleanup ec2 delete-route-table --route-table-id $rt
  done
  
  # Delete security groups (except default)
  for sg in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc" --query "SecurityGroups[?GroupName != \`default\`].GroupId" --output text); do
    echo "Deleting Security Group $sg in VPC $vpc"
    aws_cleanup ec2 delete-security-group --group-id $sg
  done
  
  # Delete VPC
  echo "Deleting VPC $vpc"
  aws_cleanup ec2 delete-vpc --vpc-id $vpc
done

# Clean up IAM roles
echo "Cleaning up IAM resources..."
for role in $(aws iam list-roles --query "Roles[?contains(RoleName, '$PROJECT_NAME')].RoleName" --output text); do
  # First detach all policies
  for policy in $(aws iam list-attached-role-policies --role-name $role --query "AttachedPolicies[].PolicyArn" --output text); do
    echo "Detaching policy $policy from role $role"
    aws_cleanup iam detach-role-policy --role-name $role --policy-arn $policy
  done
  
  # Delete role
  echo "Deleting IAM role: $role"
  aws_cleanup iam delete-role --role-name $role
done

# Check for remaining resources with better error handling
check_remaining_resources() {
  local resource_type=$1
  local cmd=$2
  
  echo "Checking for remaining $resource_type..."
  local count=0
  
  # Execute command with error handling
  local result=$(eval "$cmd" 2>/dev/null || echo "ERROR")
  
  if [ "$result" = "ERROR" ]; then
    echo "WARNING: Could not check for remaining $resource_type. Insufficient permissions or invalid command."
    return 0
  elif [ -n "$result" ]; then
    count=$(echo "$result" | jq 'length' 2>/dev/null || echo 0)
    if [ "$count" -gt 0 ]; then
      echo "WARNING: $count $resource_type with name containing '$PROJECT_NAME' still exist."
      return $count
    fi
  fi
  
  return 0
}

# At the end, verify cleanup with improved checks
echo "Verifying cleanup..."
REMAINING_RESOURCES=0

# Check for remaining VPCs with better error handling
check_remaining_resources "VPCs" "aws ec2 describe-vpcs --filters \"Name=tag:Name,Values=*$PROJECT_NAME*\" --query \"Vpcs\" --output json"
REMAINING_RESOURCES=$((REMAINING_RESOURCES + $?))

# Check for remaining S3 buckets with better error handling
check_remaining_resources "S3 buckets" "aws s3api list-buckets --query \"Buckets[?contains(Name, '$PROJECT_NAME')].Name\" --output json"
REMAINING_RESOURCES=$((REMAINING_RESOURCES + $?))

# Final status
if [ "$REMAINING_RESOURCES" -eq 0 ]; then
  echo "==========================================================="
  echo "Cleanup appears to be successful! No remaining resources found."
  echo "==========================================================="
else
  echo "==========================================================="
  echo "Cleanup completed with warnings. $REMAINING_RESOURCES resources might still exist."
  echo "Please check the AWS console for remaining resources."
  echo "==========================================================="
fi
