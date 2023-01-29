resource "aws_dynamodb_table" "dynamo_table" {
  name             = "${terraform.workspace}-dynamodb-full-text-search-table"
  billing_mode     = "PROVISIONED"
  write_capacity   = 1
  read_capacity    = 1
  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  hash_key  = "pk"
  range_key = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }
}
