provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# --------------------------------------------------------
# S3 STATIC SITE BUCKET
# --------------------------------------------------------
resource "aws_s3_bucket" "ritual_roast_static" {
  bucket = "ritual-roast-static-${var.env}"
}

resource "aws_s3_bucket_versioning" "ritual_roast_versioning" {
  bucket = aws_s3_bucket.ritual_roast_static.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "ritual_roast_public" {
  bucket                  = aws_s3_bucket.ritual_roast_static.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------------------
# CLOUD FRONT ORIGIN ACCESS CONTROL
# --------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "ritual_roast_oac" {
  name                              = "ritual-roast-oac-${var.env}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# --------------------------------------------------------
# ACM CERTIFICATE (in us-east-1 region)
# --------------------------------------------------------
resource "aws_acm_certificate" "ritual_roast_cert" {
  provider          = aws.virginia
  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  cert_validation_options = tolist(aws_acm_certificate.ritual_roast_cert.domain_validation_options)
}

# --------------------------------------------------------
# ROUTE53 DNS VALIDATION
# --------------------------------------------------------
resource "aws_route53_record" "ritual_roast_cert_validation" {
  count = var.hosted_zone_id == "" ? 0 : 1

  zone_id = var.hosted_zone_id
  name    = local.cert_validation_options[0].resource_record_name
  type    = local.cert_validation_options[0].resource_record_type
  ttl     = 300
  records = [local.cert_validation_options[0].resource_record_value]
}

resource "aws_acm_certificate_validation" "ritual_roast_validation" {
  provider = aws.virginia
  count    = var.hosted_zone_id == "" ? 0 : 1

  certificate_arn         = aws_acm_certificate.ritual_roast_cert.arn
  validation_record_fqdns = [aws_route53_record.ritual_roast_cert_validation[0].fqdn]
}

# --------------------------------------------------------
# NAMECHEAP MANUAL VALIDATION OUTPUT
# --------------------------------------------------------
output "acm_dns_validation_cname" {
  description = "Add this CNAME in Namecheap to validate ACM certificate"
  value       = local.cert_validation_options
}

# --------------------------------------------------------
# CLOUDFRONT DISTRIBUTION
# --------------------------------------------------------
resource "aws_cloudfront_distribution" "ritual_roast_cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name              = aws_s3_bucket.ritual_roast_static.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.ritual_roast_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.ritual_roast_cert.arn
    ssl_support_method  = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# --------------------------------------------------------
# S3 BUCKET POLICY (FIXED FOR OAC + CLOUDFRONT)
# --------------------------------------------------------
resource "aws_s3_bucket_policy" "ritual_roast_policy" {
  bucket = aws_s3_bucket.ritual_roast_static.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.ritual_roast_static.arn}/*"

        Condition = {
          StringEquals = {
            # CORRECT CLOUDFRONT ARN (global, no account ID)
            "AWS:SourceArn" = aws_cloudfront_distribution.ritual_roast_cdn.arn
          }
        }
      }
    ]
  })
}

# --------------------------------------------------------
# WAF ACL (GLOBAL FOR CLOUDFRONT)
# --------------------------------------------------------
# resource "aws_wafv2_web_acl" "ritual_roast_waf" {
#   name        = "ritual-roast-waf"
#   description = "WAF for CloudFront"
#   scope       = "CLOUDFRONT"
#
#   default_action {
#     allow {}
#   }
#
#   visibility_config {
#     metric_name                = "ritual-roast-waf"
#     cloudwatch_metrics_enabled = true
#     sampled_requests_enabled   = true
#   }
#
#   rule {
#     name     = "AWS-Auto-Block-Bad-Bots"
#     priority = 1
#
#     statement {
#       managed_rule_group_statement {
#         vendor_name = "AWS"
#         name        = "AWSManagedRulesBotControlRuleSet"
#       }
#     }
#
#     override_action {
#       none {}
#     }
#
#     visibility_config {
#       metric_name                = "bot-control"
#       cloudwatch_metrics_enabled = true
#       sampled_requests_enabled   = true
#     }
#   }
# }
#
# --------------------------------------------------------
# WAF → CLOUDFRONT ASSOCIATION (FIXED)
# --------------------------------------------------------
# resource "aws_wafv2_web_acl_association" "ritual_roast_waf_attach" {
#   depends_on = [aws_cloudfront_distribution.ritual_roast_cdn]
#
#   # CORRECT CLOUDFRONT ARN (no account ID)
#   resource_arn = aws_cloudfront_distribution.ritual_roast_cdn.arn
#   web_acl_arn  = aws_wafv2_web_acl.ritual_roast_waf.arn
# }
