terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.37.0"
    }
  }
}

# Provider Block
provider "aws" {
  region  = "ap-southeast-1"
}