resource "aws_dynamodb_table" "greeting" {
  for_each = var.regions
  region   = each.key

  name         = "GreetingLogs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ID"

  attribute {
    name = "ID"
    type = "S"
  }
}