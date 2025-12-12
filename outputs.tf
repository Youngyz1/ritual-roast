output "alb_dns_name" {
  description = "Public DNS of the ALB"
  value       = try(aws_lb.app.dns_name, null)
}

output "ecr_repository_url" {
  description = "ECR repository URL for Ritual Roast image"
  value       = try(aws_ecr_repository.ritual.repository_url, null)
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = try(aws_ecs_cluster.this.name, null)
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = try(aws_ecs_service.ritual_service.name, null)
}

output "db_endpoint" {
  description = "RDS MySQL endpoint"
  value       = try(aws_db_instance.mysql.address, null)
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = try(aws_cloudfront_distribution.ritual_roast_cdn.domain_name, null)
}
