output "alb_dns_name" {
  description = "Public DNS of the ALB"
  value       = aws_lb.app.dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for Ritual Roast image"
  value       = aws_ecr_repository.ritual.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.ritual_service.name
}

output "db_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.mysql.address
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = aws_cloudfront_distribution.ritual_roast_cdn.domain_name
}
