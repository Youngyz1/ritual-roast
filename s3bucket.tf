resource "aws_s3_bucket" "rr_alb_logs" {
  bucket        = "ritual-roast-alb-logs-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name = "ritual-roast-alb-logs"
  }
}

resource "aws_s3_bucket_acl" "rr_alb_logs_acl" {
  bucket = aws_s3_bucket.rr_alb_logs.id
  acl    = "private"
}
