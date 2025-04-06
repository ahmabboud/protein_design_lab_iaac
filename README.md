# Protein Discovery Lab Infrastructure

This repository contains Terraform code for deploying AWS infrastructure to run a protein discovery lab using SageMaker and Ray framework.

## Architecture

This infrastructure includes:

- SageMaker Domain and User Profile for interactive development
- Ray cluster deployed on SageMaker HyperPod for distributed computing
  - Note: Ray requires at least one head node to remain running; true "scale to zero" is not supported by Ray's native architecture
  - Worker nodes can scale up/down based on workload but the head node must remain active
  - For cost optimization, consider using smaller instance types for the head node during idle periods
- S3 buckets for data storage
- FSx Lustre filesystem for high-performance storage
- SageMaker Pipeline for automated protein structure prediction workflow
- IAM roles with proper permissions for SageMaker and resource tagging operations
- Networking components including VPC, subnets, security groups, and routing

## Structure

- `main.tf` - Main configuration file defining modules and their relationships
- `variables.tf` - Variable definitions
- `outputs.tf` - Output definitions
- `backend.tf` - Backend configuration for state storage
- `versions.tf` - Terraform version constraints
- `cleanup.tf` - Configuration for resource cleanup operations
- `modules/` - Terraform modules
  - `networking/` - VPC, subnets, security groups
  - `sagemaker/` - SageMaker notebooks and instances
  - `ray/` - Ray cluster configuration
  - `storage/` - S3 buckets and storage resources
  - `iam/` - IAM roles and policies
  - `cleanup/` - Resource cleanup utilities

## Prerequisites

- AWS CLI installed and configured
- Terraform >= 1.0.0
- An AWS account with appropriate permissions:
  - SageMaker full access
  - EC2 and VPC management
  - S3 bucket management
  - IAM role creation
  - Resource Groups Tagging API access
- S3 bucket and DynamoDB table for Terraform state (already configured in `backend.tf`)

## Getting Started

1. Clone this repository
2. Create a `terraform.tfvars` file with your specific values:
   ```
   # Example terraform.tfvars file - create this in the project root
   aws_region = "us-east-1"
   project_name = "protein-discovery"
   environment = "dev"
   account_id = "123456789012"  # Replace with your AWS account ID
   aws_profile = "default"
   cpu_worker_count = 2
   gpu_worker_count = 1
   ```
3. Initialize Terraform:
```
terraform init
```
4. Plan the deployment:
```
terraform plan
```
5. Deploy the infrastructure:
```
terraform apply
```

## Environments

To deploy to different environments, create environment-specific variable files:
- `dev.tfvars`
- `prod.tfvars`

Then run:
```
terraform apply -var-file=dev.tfvars
```

## Protein Discovery Pipeline

The infrastructure includes a SageMaker Pipeline with the following stages:

1. **Sequence Generation**: Generates protein sequences using ProteinMPNN
2. **Structure Prediction**: Predicts 3D structures using ESMFold
3. **Structure Validation**: Validates and scores the predicted structures
4. **Visualization Preparation**: Prepares structures for visualization

## Scripts

The repository includes Ray-based scripts for:

- `ray_generate_sequences.py`: Generate protein sequences
- `ray_predict_structures.py`: Predict protein structures
- `ray_validate_structures.py`: Validate protein structures
- `ray_prepare_visualization.py`: Prepare structures for visualization

## Variables

Key variables you may want to customize:

- `aws_region`: AWS region for deployment
- `project_name`: Name of the project
- `environment`: Deployment environment (dev/staging/prod)
- `cpu_worker_count`: Number of CPU worker nodes in Ray cluster
- `gpu_worker_count`: Number of GPU worker nodes in Ray cluster

Refer to `variables.tf` for a complete list of variables.

## Incremental Deployment

If you prefer to create resources one at a time for testing or to manage dependencies manually:

### Step 1: Initialize and Validate

```bash
# Initialize Terraform
terraform init

# Validate the configuration
terraform validate
```

### Step 2: Deploy Core Infrastructure

Deploy networking and storage resources first:

```bash
# Deploy networking resources
terraform apply -target=module.networking
# Verify outputs
terraform output module.networking

# Deploy IAM resources (needed by other components)
terraform apply -target=module.iam
# Verify role ARNs are created
terraform output module.iam

# Deploy storage resources
terraform apply -target=module.storage
# Verify bucket names and other storage outputs
terraform output module.storage
```

### Step 3: Deploy Compute Resources

Once core infrastructure is in place:

```bash
# Deploy SageMaker resources (domains, notebooks)
terraform apply -target=module.sagemaker
# Verify SageMaker resources
terraform output module.sagemaker

# Deploy Ray cluster (start with gpu_worker_count=0 to reduce initial costs)
terraform apply -target=module.ray_cluster
# Verify Ray cluster setup
terraform output module.ray_cluster
```

### Step 4: Deploy Pipeline Components and Remaining Resources

```bash
# Deploy the SageMaker pipeline
terraform apply -target="aws_sagemaker_pipeline.protein_discovery_pipeline"

# Apply any remaining resources and ensure complete deployment
terraform apply
```

### Step 5: Verify Complete Deployment

```bash
# List all resources in the state
terraform state list

# Check for any resources that failed to deploy
terraform plan

# Output all values for reference
terraform output
```

### Tips for Incremental Deployment

- Use `terraform plan -target=MODULE_NAME` to preview changes before applying
- Set `gpu_worker_count = 0` initially to reduce costs during testing
- If a step fails, check dependencies with `terraform graph | dot -Tsvg > graph.svg`
- After each phase, verify that required outputs exist before proceeding
- Resources with cross-module dependencies may need to be created together
- The final `terraform apply` ensures any missed resources or dependencies are addressed

This incremental approach will implement the complete solution, creating all resources defined in the Terraform configuration in a logical order that respects dependencies.

## Resource Cleanup

This project provides multiple approaches to clean up resources, each suited for different scenarios.

### Standard Cleanup

For normal scenarios when all resources were created and managed through Terraform:

```bash
terraform destroy
```

This is the standard method that follows your Terraform state and properly handles resource dependencies.

### Advanced Cleanup Options

#### Option 1: Using the Cleanup Module

For cases where some resources are difficult to delete or have complex dependencies:

```bash
# Apply just the cleanup module
terraform apply -target=module.cleanup -auto-approve

# Then destroy the cleanup module
terraform destroy -target=module.cleanup -auto-approve

# Finally, destroy everything else
terraform destroy -auto-approve
```

This approach leverages a dedicated cleanup module that uses AWS Resource Groups Tagging API and null resources to systematically clean up resources using AWS CLI commands.

**When to use:** When the standard terraform destroy fails due to dependency or state issues, but resources are properly tagged.

#### Option 2: Force Cleanup Script

For more complex scenarios or when Terraform state is inconsistent, use the provided script:

```bash
# Make the script executable
chmod +x ./scripts/force_cleanup.sh

# Run the script
./scripts/force_cleanup.sh
```

The script will guide you through three options:
1. **Terraform-based cleanup**: Creates targeted resources for cleanup then destroys everything
2. **AWS CLI-based cleanup**: Uses AWS CLI directly to find and delete resources by name/tag
3. **Abort**: Cancels the operation

**When to use:** When resources cannot be cleaned up through standard Terraform operations, especially if:
- Resources were modified outside of Terraform
- Terraform state is corrupted or lost
- Resource dependencies prevent normal destruction
- You need to verify that all resources are truly removed

### Cleanup Features

The provided cleanup solutions include several advanced features:

- **Automatic resource discovery** using AWS tags and name patterns
- **Timeout handling** for resources that take long to delete
- **Retry mechanisms** for failed deletion attempts
- **Dependency ordering** to handle resources in the correct sequence
- **State verification** to confirm resources are actually deleted
- **Comprehensive logging** for debugging cleanup issues

### Cleanup Parameters

The cleanup module can be customized with the following parameters in `terraform.tfvars`:

```terraform
# Cleanup configuration
cleanup_timeout = 900          # Timeout in seconds for cleanup operations
max_cleanup_retries = 5        # Maximum number of retry attempts for cleanup
cleanup_dry_run = false        # Set to true to preview without deleting
```

### Troubleshooting Cleanup Issues

If you encounter persistent resources after cleanup attempts:

1. **Check AWS Console**: Look for resources with names containing your project name
2. **Verify Tags**: Ensure resources have the expected `caylent:project` and `caylent:workload` tags
3. **S3 Buckets**: For versioned buckets, ensure object versions and delete markers are removed
4. **IAM Roles**: Check that all policy attachments are removed before deleting roles
5. **Locked Resources**: Some resources like SageMaker domains may be in a "deleting" state for extended periods
6. **Run Script in AWS CLI Mode**: If Terraform-based cleanup fails, try the AWS CLI-based option

**Note:** All cleanup methods will permanently delete resources and data. Always ensure you have backups of important data before proceeding.
