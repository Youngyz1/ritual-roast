# =========================================
# Route 53 Public Hosted Zone
# =========================================
resource "aws_route53_zone" "ritualroast" {
  name = "ritualroast.online"

  tags = {
    Name = "ritualroast.online"
  }
}

# =========================
# Route 53 A/ALIAS Records for ALB
# =========================

# Root domain
resource "aws_route53_record" "ritualroast_alb_alias" {
  zone_id = aws_route53_zone.ritualroast.zone_id
  name    = "ritualroast.online"
  type    = "A"

  alias {
    name                   = aws_lb.ritual_roast_alb.dns_name
    zone_id                = aws_lb.ritual_roast_alb.zone_id
    evaluate_target_health = true
  }
}

# www subdomain
resource "aws_route53_record" "www_ritualroast_alb_alias" {
  zone_id = aws_route53_zone.ritualroast.zone_id
  name    = "www.ritualroast.online"
  type    = "A"

  alias {
    name                   = aws_lb.ritual_roast_alb.dns_name
    zone_id                = aws_lb.ritual_roast_alb.zone_id
    evaluate_target_health = true
  }
}
