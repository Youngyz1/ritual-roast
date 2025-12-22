# =========================================
# ACM Certificate
# =========================================
resource "aws_acm_certificate" "ritual_roast_cert" {
  domain_name       = "ritusroast.online"
  validation_method = "DNS"

  subject_alternative_names = [
    "www.ritusroast.online"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "ritual-roast-cert"
  }
}

# =========================================
# Route 53 DNS Validation Records
# =========================================
resource "aws_route53_record" "ritual_roast_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ritual_roast_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.ritusroast.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# =========================================
# ACM Certificate Validation
# =========================================
resource "aws_acm_certificate_validation" "ritual_roast_cert_validation" {
  certificate_arn = aws_acm_certificate.ritual_roast_cert.arn
  validation_record_fqdns = [
    for record in aws_route53_record.ritual_roast_cert_validation :
    record.fqdn
  ]
}

# =========================================
# HTTP → HTTPS Redirect Listener
# =========================================
resource "aws_lb_listener" "ritual_roast_http" {
  load_balancer_arn = aws_lb.ritual_roast_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# =========================================
# HTTPS Listener (ACM)
# =========================================
resource "aws_lb_listener" "ritual_roast_https" {
  load_balancer_arn = aws_lb.ritual_roast_alb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.ritual_roast_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ritual_roast_tg.arn
  }

  depends_on = [
    aws_acm_certificate_validation.ritual_roast_cert_validation
  ]
}
