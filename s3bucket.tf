# Random suffix to avoid bucket name collision
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 bucket for ALB access logs
resource "aws_s3_bucket" "rr_alb_logs" {
  bucket = "ritual-roast-alb-logs-${random_id.bucket_suffix.hex}"
  acl    = "private"

  force_destroy = true  # optional, allows Terraform to delete bucket even if it has objects

  tags = {
    Name = "ritual-roast-alb-logs"
  }
}
