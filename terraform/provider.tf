provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "Terraform-Project"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}