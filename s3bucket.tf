# Generate a random suffix to ensure the bucket name is globally unique
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket for ALB access logs
resource "aws_s3_bucket" "rr_alb_logs" {
  bucket        = "ritual-roast-alb-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "ritual-roast-alb-logs"
  }
}

# Block public access settings must be defined separately
resource "aws_s3_bucket_public_access_block" "rr_alb_logs_block" {
  bucket                  = aws_s3_bucket.rr_alb_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
