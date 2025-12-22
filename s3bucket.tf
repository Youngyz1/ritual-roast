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

  # Optional: enable block public access for safety
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
