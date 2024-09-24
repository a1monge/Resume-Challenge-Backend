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

# ACM
resource "aws_acm_certificate" "almonge_resume_certificate" {
  domain_name       = "almonge-resume.com"
  validation_method = "DNS"
}

# Route 53 Hosted Zone for the domain
resource "aws_route53_zone" "almonge_resume_zone" {
  name = "almonge-resume.com"
}

# A record for CloudFront distribution
resource "aws_route53_record" "a_record" {
  zone_id = aws_route53_zone.almonge_resume_zone.zone_id
  name    = "almonge-resume.com"
  type    = "A"

  alias {
    name                   = "d14o4qhuqrhqgm.cloudfront.net"
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront zone ID
    evaluate_target_health = false
  }
}

# NS records (Name Servers)
resource "aws_route53_record" "ns_record" {
  zone_id = aws_route53_zone.almonge_resume_zone.zone_id
  name    = "almonge-resume.com"
  type    = "NS"
  ttl     = 172800

  records = [
    "ns-254.awsdns-31.com.",
    "ns-1418.awsdns-49.org.",
    "ns-704.awsdns-24.net.",
    "ns-1823.awsdns-35.co.uk."
  ]
}

# SOA record
resource "aws_route53_record" "soa_record" {
  zone_id = aws_route53_zone.almonge_resume_zone.zone_id
  name    = "almonge-resume.com"
  type    = "SOA"
  ttl     = 900

  records = [
    "ns-254.awsdns-31.com. awsdns-hostmaster.amazon.com. 1 7200 900 1209600 86400"
  ]
}

# CNAME record for ACM validation
resource "aws_route53_record" "acm_validation_record" {
  zone_id = aws_route53_zone.almonge_resume_zone.zone_id
  name    = "_0b4406fd06eafb06d971d06a7705e443.almonge-resume.com"
  type    = "CNAME"
  ttl     = 300

  records = [
    "_0f173f263a5d186ff8dd64ed46c7979b.djqtsrsxkq.acm-validations.aws."
  ]
}

# API Gateway
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
  rest_api_id   = aws_api_gateway_rest_api.counter_api.id
  resource_id   = aws_api_gateway_resource.increment_counter.id
  http_method   = "GET"
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
    "method.response.header.Access-Control-Allow-Origin" = "'*'" # Or your specific origin
  }
}


resource "aws_api_gateway_stage" "prod_stage" {
  rest_api_id   = aws_api_gateway_rest_api.counter_api.id
  stage_name    = "prod"
  description   = "Production stage"
  deployment_id = "7ifs29" # Use the actual deployment ID
}

# Lambda Function
resource "aws_lambda_function" "visitor_counter" {
  function_name = "LmbdaVistiorCounter"
  role          = "arn:aws:iam::851725284012:role/DynamoDBFull"
  handler       = "lambda_function.lambda_handler" # Your handler function
  runtime       = "python3.12"                     # Your runtime

  # Specify the local path to your packaged Lambda code
  filename = "./LmbdaVistiorCounter.zip" # Update with the correct path

  source_code_hash = filebase64sha256("./LmbdaVistiorCounter.zip") # Update with the same path
}

resource "aws_dynamodb_table" "VisitorCounter" {
  name         = "VisitorCounter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "CounterID"

  attribute {
    name = "CounterID"
    type = "S"
  }

  stream_enabled = false
  ttl {
    enabled = false
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "VisitorCounter"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Cloudfront Distribution
resource "aws_cloudfront_distribution" "distribution" {
  aliases         = ["almonge-resume.com"]
  enabled         = true
  price_class     = "PriceClass_100"
  http_version    = "http2and3"
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    target_origin_id       = "almonge.com.s3-website-us-east-1.amazonaws.com"
  }

  origin {
    domain_name = "almonge.com.s3-website-us-east-1.amazonaws.com"
    origin_id   = "almonge.com.s3-website-us-east-1.amazonaws.com"
    origin_path = "/build"

    custom_origin_config {
      origin_protocol_policy = "http-only"
      http_port              = 80
      https_port             = 443
      origin_ssl_protocols   = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none" # Allows access from all countries
    }
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:851725284012:certificate/6b943c78-d702-4e92-85f8-9866e297f473"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}













