# =========================================
# Route 53 Public Hosted Zone
# =========================================
resource "aws_route53_zone" "ritusroast" {
  name = "ritusroast.online"

  tags = {
    Name = "ritusroast.online"
  }
}
