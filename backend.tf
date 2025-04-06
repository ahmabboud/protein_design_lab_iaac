terraform {
  backend "s3" {
    bucket         = "protein-discovery-terraform-state"  # Hardcoded bucket name
    key            = "terraform.tfstate"
    region         = "us-east-1"  # Hardcoded region
    dynamodb_table = "protein-discovery-terraform-lock"  # Hardcoded table name
    encrypt        = true
  }
}
