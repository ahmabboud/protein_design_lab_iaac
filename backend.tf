terraform {
  backend "s3" {
    bucket         = "${var.project_name}-terraform-state-${var.account_id}"  # Dynamic bucket name
    key            = "terraform.tfstate"
    region         = "${var.aws_region}"  # Use variable for region
    dynamodb_table = "protein-discovery-terraform-lock"  # Hardcoded table name remains
    encrypt        = true
  }
}
