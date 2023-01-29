terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket  = "tf-states-backup-nameistaken"
    region  = "eu-central-1"
    key     = "dynamodb-full-text-search/terraform.tfstate"
    profile = "personal"
  }
}

provider "aws" {
  region                   = "eu-central-1"
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = "personal"
}
