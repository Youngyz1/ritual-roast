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
