resource "aws_iam_role" "api_gateway_dynamodb_role" {
  name = "api-gateway-dynamodb-role"


  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Service : "apigateway.amazonaws.com"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "put_item_policy" {
  name = "put-item-comments-policy"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : "dynamodb:PutItem",
        Resource : "arn:aws:dynamodb:${var.region}:${var.account_id}:table/Comments"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "put-policy-attachment" {
  role       = aws_iam_role.api_gateway_dynamodb_role.name
  policy_arn = aws_iam_policy.put_item_policy.arn
}

resource "aws_iam_policy" "query_comments_policy" {
  name = "query-comments-policy"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "dynamodb:Query",
        Resource = "arn:aws:dynamodb:${var.region}:${var.account_id}:table/comments"
      },
      {
        Effect   = "Allow",
        Action   = "dynamodb:Query",
        Resource = "arn:aws:dynamodb:${var.region}:${var.account_id}:table/comments/index/postId-index"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "query-policy-attachment" {
  role       = aws_iam_role.api_gateway_dynamodb_role.name
  policy_arn = aws_iam_policy.query_comments_policy.arn
}