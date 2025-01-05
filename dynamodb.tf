resource "aws_dynamodb_table" "comment" {
  name           = "comments"
  billing_mode   = "PAY_PER_REQUEST"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "commentId"

  attribute {
    name = "commentId"
    type = "S"
  }
   global_secondary_index {
    name               = "post"
    hash_key           = "postId"
    write_capacity     = 5
    read_capacity      = 5
    projection_type    = "INCLUDE"
    non_key_attributes = ["postId", "userName", "comment"]
  }
}