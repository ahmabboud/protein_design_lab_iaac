#!/bin/bash

# Check if terraform.tfvars exists
if [ ! -f terraform.tfvars ]; then
    echo "Error: terraform.tfvars file not found. Please create it and try again."
    exit 1
fi

# Fixed extraction using cut to get values between quotes
BUCKET_BASE_NAME=$(grep -E '^[[:space:]]*project_name[[:space:]]*=' terraform.tfvars | cut -d '"' -f 2)
REGION=$(grep -E '^[[:space:]]*aws_region[[:space:]]*=' terraform.tfvars | cut -d '"' -f 2)
ACCOUNT_ID=$(grep -E '^[[:space:]]*account_id[[:space:]]*=' terraform.tfvars | cut -d '"' -f 2)

# Log extracted values for debugging
echo "Extracted project_name: $BUCKET_BASE_NAME"
echo "Extracted aws_region: $REGION"
echo "Extracted account_id: $ACCOUNT_ID"

# Validate extracted values (remain unchanged)
if [ -z "$BUCKET_BASE_NAME" ]; then
    echo "Error: 'project_name' is not defined in terraform.tfvars."
    exit 1
fi
if [ -z "$REGION" ]; then
    echo "Error: 'aws_region' is not defined in terraform.tfvars."
    exit 1
fi
if [ -z "$ACCOUNT_ID" ]; then
    echo "Error: 'account_id' is not defined in terraform.tfvars."
    exit 1
fi

# Correct the bucket name computation
BUCKET_NAME="${BUCKET_BASE_NAME}-terraform-state-${ACCOUNT_ID}"

# Log bucket name for debugging
echo "Computed bucket name: $BUCKET_NAME"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null
then
    echo "Error: AWS CLI is not installed. Please install it and try again."
    exit 1
fi

# Create the S3 bucket
# Ensure LocationConstraint is passed correctly without unnecessary characters or quotes
if [ "$REGION" == "us-east-1" ]; then
    echo "Creating S3 bucket: $BUCKET_NAME in region: $REGION (no LocationConstraint required)"
    if ! aws s3api create-bucket --bucket "$BUCKET_NAME"; then
        echo "Error: Failed to create bucket $BUCKET_NAME."
        exit 1
    fi
else
    echo "Creating S3 bucket: $BUCKET_NAME in region: $REGION"
    if ! aws s3api create-bucket --bucket "$BUCKET_NAME" \
        --create-bucket-configuration LocationConstraint=$REGION; then
        echo "Error: Failed to create bucket $BUCKET_NAME."
        exit 1
    fi
fi

# Enable versioning on the bucket
echo "Enabling versioning on bucket: $BUCKET_NAME"
if ! aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled; then
    echo "Error: Failed to enable versioning on bucket $BUCKET_NAME."
    exit 1
fi

echo "S3 bucket setup complete. You can now run 'terraform init'."