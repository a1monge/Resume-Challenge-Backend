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


