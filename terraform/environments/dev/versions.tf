terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.30.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13.0"
    }
  }

  # Backend para remote state (descomente quando configurar)
  # backend "s3" {
  #   bucket         = "qag-terraform-state"
  #   key            = "eks/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "qag-terraform-locks"
  # }
}
