terraform {
  required_version = ">= 1.0.0"

  backend "s3" {
    bucket = "unleash-tf-bucket-sabrina"
    key    = "terraform.tfstate"
    region = "ap-southeast-2"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}