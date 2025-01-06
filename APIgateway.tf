resource "aws_api_gateway_rest_api" "dynamodb-api" {
  name        = "dynamodb-API"
  description = "This is my API for posting and getting comments"
}

resource "aws_api_gateway_resource" "comments" {
  rest_api_id = aws_api_gateway_rest_api.dynamodb-api.id
  parent_id   = aws_api_gateway_rest_api.dynamodb-api.root_resource_id
  path_part   = "comments"
}
resource "aws_api_gateway_resource" "post" {
    rest_api_id = aws_api_gateway_rest_api.dynamodb-api.id
    parent_id   =  aws_api_gateway_resource.comments.id
    path_part = "post"
}
resource "aws_api_gateway_method" "put-item-method" {
  rest_api_id = aws_api_gateway_rest_api.dynamodb-api.id
  resource_id = aws_api_gateway_resource.comments.id
  http_method = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "put-item-integration" {
  rest_api_id          = aws_api_gateway_rest_api.dynamodb-api.id
  resource_id          = aws_api_gateway_resource.comments.id
  http_method          = aws_api_gateway_method.put-item-method.http_method
  type                 = "AWS"
  uri   = "arn:aws:apigateway:${var.region}:dynamodb:action/PutItem"
  credentials = aws_iam_policy.put_item_policy.arn
  request_templates = {
     "application/json" = jsonencode({
    TableName = "comments",
    Item = {
      commentId = { S = "$context.requestId" },
      postId    = { S = "$input.path('$.postId')" },
      userName  = { S = "$input.path('$.userName')" },
      comment   = { S = "$input.path('$.comment')" }
    }
  })
}
}

resource "aws_api_gateway_method" "get-comment-method" {
  rest_api_id   = aws_api_gateway_rest_api.dynamodb-api.id
  resource_id   = aws_api_gateway_resource.comments.id  
  http_method   = "POST"  
  authorization = "NONE"  
}

resource "aws_api_gateway_integration" "get-comments-integration" {
  rest_api_id             = aws_api_gateway_rest_api.dynamodb-api.id
  resource_id             = aws_api_gateway_resource.comments.id
  http_method             = aws_api_gateway_method.get-comment-method.http_method
  integration_http_method = "POST" #it's also POST according to AWS docs where it has been said that all dynamodb queries are POST
  type                    = "AWS"  
  credentials = aws_iam_policy.query_comments_policy.arn
  uri = "arn:aws:apigateway:${var.region}:dynamodb:action/Query"
 request_templates = {
  "application/json" = jsonencode({
    TableName               = "Comments",
    IndexName              = "postId-index",
    KeyConditionExpression = "postId = :v1",
    ExpressionAttributeValues = {
      ":v1" = {
        S = "$input.params('postId')"
      }
    }
  })
}
}

resource "aws_api_gateway_integration_response" "get_comments_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.dynamodb-api.id
  resource_id = aws_api_gateway_resource.comments.id
  http_method = "POST"
  status_code = "200"

  response_templates = {
  "application/json" = <<EOF
{
  "comments": [
    #foreach($comment in $input.path('$.Items')) {
      "commentId": "$comment.commentId.S",
      "userName": "$comment.userName.S",
      "comment": "$comment.comment.S" }
    #if($foreach.hasNext),#end
    #end
  ]
}
EOF
}
}

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.dynamodb-api.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.dynamodb-api.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deploy.id
  rest_api_id   = aws_api_gateway_rest_api.dynamodb-api.id
  stage_name    = "dev"
}

