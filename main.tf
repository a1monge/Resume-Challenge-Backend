provider "aws" {
  region = "us-east-1"
}

# S3 Bucket Resource (no ACL or website configuration here)
resource "aws_s3_bucket" "my_resume_bucket" {
  bucket = "almonge.com"
}

# S3 Bucket ACL Resource (for setting the public-read ACL)
resource "aws_s3_bucket_acl" "my_resume_bucket_acl" {
  bucket = aws_s3_bucket.my_resume_bucket.id
  acl    = "public-read"
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "my_resume_bucket_website" {
  bucket = aws_s3_bucket.my_resume_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
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
