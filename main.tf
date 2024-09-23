provider "aws" {
  region     = "us-east-1"
}

# S3 Bucket Resource (no ACL or website configuration here)
resource "aws_s3_bucket" "my_resume_bucket" {
  bucket = "almonge.com"
}

# S3 Bucket Versioning Resource
resource "aws_s3_bucket_versioning" "my_resume_bucket_versioning" {
  bucket = aws_s3_bucket.my_resume_bucket.bucket

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Policy Resource
resource "aws_s3_bucket_policy" "my_resume_bucket_policy" {
  bucket = aws_s3_bucket.my_resume_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "PublicReadGetObject",
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "arn:aws:s3:::almonge.com/*"
      }
    ]
  })
}

resource "aws_api_gateway_rest_api" "counter_api" {
  name        = "Counter"
  description = "API for counting visitors"
}

resource "aws_api_gateway_resource" "increment_counter" {
  rest_api_id = aws_api_gateway_rest_api.counter_api.id
  parent_id   = aws_api_gateway_rest_api.counter_api.root_resource_id
  path_part   = "incrementCounter"
  
}

resource "aws_api_gateway_method" "get_increment_counter" {
  rest_api_id = aws_api_gateway_rest_api.counter_api.id
  resource_id = aws_api_gateway_resource.increment_counter.id
  http_method = "GET"
  authorization = "NONE"

   request_parameters = {
    "method.request.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.counter_api.id
  resource_id = aws_api_gateway_resource.increment_counter.id
  http_method = aws_api_gateway_method.get_increment_counter.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"  # Or your specific origin
  }
}


resource "aws_api_gateway_stage" "prod_stage" {
  rest_api_id   = aws_api_gateway_rest_api.counter_api.id
  stage_name    = "prod"
  description    = "Production stage"
  deployment_id = "7ifs29"  # Use the actual deployment ID
}

resource "aws_lambda_function" "visitor_counter" {
  function_name = "LmbdaVistiorCounter"
  role          = "arn:aws:iam::851725284012:role/DynamoDBFull"
  handler       = "lambda_function.lambda_handler" # Your handler function
  runtime       = "python3.12"                      # Your runtime

  # Specify the local path to your packaged Lambda code
  filename      = "./LmbdaVistiorCounter.zip"    # Update with the correct path

  source_code_hash = filebase64sha256("./LmbdaVistiorCounter.zip")  # Update with the same path
}













