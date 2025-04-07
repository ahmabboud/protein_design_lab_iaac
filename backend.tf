terraform {
  backend "s3" {
    key            = "terraform.tfstate"
    dynamodb_table = "protein-discovery-terraform-lock"
    encrypt        = true
  }
}
