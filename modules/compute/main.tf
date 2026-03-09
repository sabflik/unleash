locals {
  # A set of regions to deploy resources to
  regions = [
    "us-east-1",
    "eu-west-1",
  ]
}

resource "aws_dynamodb_table" "greeting" {
  for_each = toset(local.regions)
  region = each.key

  name         = "GreetingLogs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ID"

  attribute {
    name = "ID"
    type = "S"
  }
}

