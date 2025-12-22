# =========================================
# Route 53 Public Hosted Zone
# =========================================
resource "aws_route53_zone" "ritusroast" {
  name = "ritualroast.online"

  tags = {
    Name = "ritualroast.online"
  }
}
