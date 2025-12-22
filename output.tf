# Output the VPC ID after creation
output "vpc_id" {
  value       = aws_vpc.ritual_roast_vpc.id
  description = "The ID of the ritual roast VPC"
}

# Output the Public Subnet IDs
output "public_subnet_ids" {
  value = [
    aws_subnet.rr_public_subnet_1a.id,
    aws_subnet.rr_public_subnet_1b.id
  ]
  description = "The IDs of the public subnets"
}

# Output the Private Subnet IDs
output "private_app_subnet_ids" {
  value = [
    aws_subnet.rr_app_subnet_1a.id,
    aws_subnet.rr_app_subnet_1b.id
  ]
  description = "The IDs of the app (private) subnets"
}

output "private_data_subnet_ids" {
  value = [
    aws_subnet.rr_data_subnet_1a.id,
    aws_subnet.rr_data_subnet_1b.id
  ]
  description = "The IDs of the data (private) subnets"
}

# Output the NAT Gateway IDs
output "nat_gateway_ids" {
  value = [
    aws_nat_gateway.rr_nat_1a.id,
    aws_nat_gateway.rr_nat_1b.id
  ]
  description = "The IDs of the NAT gateways"
}

# Output the Security Group IDs
output "security_group_ids" {
  value = [
    aws_security_group.rr_alb_sg.id,
    aws_security_group.rr_app_sg.id,
    aws_security_group.rr_data_sg.id
  ]
  description = "The IDs of the security groups"
}

# Output the ECR Repository URI
output "ecr_repository_uri" {
  value       = aws_ecr_repository.ritual_roast.repository_url
  description = "The URI of the ECR repository to push Docker images"
}

# Output the ECS Cluster ID
output "ecs_cluster_id" {
  value       = aws_ecs_cluster.ritual_roast_ecs_cluster.id
  description = "The ID of the ECS cluster"
}

# Output the ECS Task Definition ARN
output "ecs_task_definition_arn" {
  value       = aws_ecs_task_definition.ritual_roast_task_definition.arn
  description = "The ARN of the ECS task definition"
}

# Output the ECS Service ARN
output "ecs_service_arn" {
  value       = aws_ecs_service.ritual_roast_service.id
  description = "The ARN of the ECS service"
}

# Output the ECS Service Name
output "ecs_service_name" {
  value       = aws_ecs_service.ritual_roast_service.name
  description = "The name of the ECS service"
}

# Output the ECS Task Role ARN
output "ecs_task_role_arn" {
  value       = aws_iam_role.ritual_roast_ecs_task_role.arn
  description = "The ARN of the ECS task role"
}

output "route53_nameservers" {
  description = "Nameservers to add in Namecheap"
  value       = aws_route53_zone.ritusroast.name_servers
}

output "alb_dns_name" {
  description = "Public ALB DNS name"
  value       = aws_lb.ritual_roast_alb.dns_name
}

output "certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.ritual_roast_cert.arn
}
