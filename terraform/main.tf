terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket = "unleash-tf-bucket-sabrina"
    key    = "terraform.tfstate"
    region = "ap-southeast-2"
    encrypt = true
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.34.0"
    }
    archive = {
      source = "hashicorp/archive"
      version = "2.7.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}