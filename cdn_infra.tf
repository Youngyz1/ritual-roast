# =========================================================
# Providers
# =========================================================
provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

# =========================================================
# S3 STATIC SITE BUCKET (STABLE NAME)
# =========================================================
resource "aws_s3_bucket" "ritual_roast_static" {
  bucket = "${var.site_bucket_name}-${var.env}"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project = "ritual-roast"
    Env     = var.env
  }
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

# =========================================================
# CLOUDFRONT ORIGIN ACCESS CONTROL (REQUIRED)
# =========================================================
resource "aws_cloudfront_origin_access_control" "ritual_roast_oac" {
  name                              = "ritual-roast-oac-prod"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# =========================================================
# ACM CERTIFICATE (US-EAST-1)
# =========================================================
resource "aws_acm_certificate" "ritual_roast_cert" {
  provider          = aws.virginia
  domain_name       = var.domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = true
  }

  tags = {
    Project = "ritual-roast"
    Env     = var.env
  }
}

locals {
  cert_validation_options = tolist(
    aws_acm_certificate.ritual_roast_cert.domain_validation_options
  )
}

# =========================================================
# ROUTE53 DNS VALIDATION
# =========================================================
resource "aws_route53_record" "ritual_roast_cert_validation" {
  count   = var.hosted_zone_id == "" ? 0 : 1
  zone_id = var.hosted_zone_id
  name    = local.cert_validation_options[0].resource_record_name
  type    = local.cert_validation_options[0].resource_record_type
  ttl     = 300
  records = [local.cert_validation_options[0].resource_record_value]
}

resource "aws_acm_certificate_validation" "ritual_roast_validation" {
  provider                = aws.virginia
  count                   = var.hosted_zone_id == "" ? 0 : 1
  certificate_arn         = aws_acm_certificate.ritual_roast_cert.arn
  validation_record_fqdns = [aws_route53_record.ritual_roast_cert_validation[0].fqdn]
}

# =========================================================
# CLOUDFRONT DISTRIBUTION
# =========================================================
resource "aws_cloudfront_distribution" "ritual_roast_cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = compact([
    var.domain,
    var.subdomain != "@" ? "${var.subdomain}.${var.domain}" : null
  ])

  origin {
    domain_name              = aws_s3_bucket.ritual_roast_static.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.ritual_roast_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-origin"
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

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Project = "ritual-roast"
    Env     = var.env
  }
}

# =========================================================
# S3 BUCKET POLICY (SECURE OAC)
# =========================================================
resource "aws_s3_bucket_policy" "ritual_roast_policy" {
  bucket = aws_s3_bucket.ritual_roast_static.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontOAC"
      Effect = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action   = "s3:GetObject"
      Resource = "${aws_s3_bucket.ritual_roast_static.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.ritual_roast_cdn.arn
        }
      }
    }]
  })
}

# =========================================================
# WAF (MANUAL – NOT MANAGED BY TERRAFORM)
# =========================================================
# Intentionally commented

# =========================================================
# WAF (GLOBAL, STABLE)
# =========================================================
# Commented for import if already exists
# resource "aws_wafv2_web_acl" "ritual_roast_waf" {
#   name  = "ritual-roast-waf"
#   scope = "CLOUDFRONT"
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
#     name     = "AWS-Bot-Control"
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
#
#   lifecycle {
#     prevent_destroy = true
#   }
# }
#
# resource "aws_wafv2_web_acl_association" "ritual_roast_waf_attach" {
#   resource_arn = aws_cloudfront_distribution.ritual_roast_cdn.arn
#   web_acl_arn  = aws_wafv2_web_acl.ritual_roast_waf.arn
# }
