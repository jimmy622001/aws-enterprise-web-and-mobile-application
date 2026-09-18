#====================================================================
# INGRESS VPC MODULE - OUTPUTS
#====================================================================

output "vpc_id" {
  description = "Ingress VPC ID"
  value       = aws_vpc.ingress.id
}

output "vpc_cidr" {
  description = "Ingress VPC CIDR block"
  value       = aws_vpc.ingress.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "tgw_subnet_ids" {
  description = "Transit Gateway attachment subnet IDs"
  value       = aws_subnet.tgw[*].id
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.application.arn
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.application.dns_name
}

output "alb_zone_id" {
  description = "Application Load Balancer zone ID"
  value       = aws_lb.application.zone_id
}

output "nlb_arn" {
  description = "Network Load Balancer ARN"
  value       = aws_lb.network.arn
}

output "nlb_dns_name" {
  description = "Network Load Balancer DNS name"
  value       = aws_lb.network.dns_name
}

output "nlb_zone_id" {
  description = "Network Load Balancer zone ID"
  value       = aws_lb.network.zone_id
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.nginx.id
}

output "ecs_cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.nginx.arn
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.nginx.name
}

output "nginx_target_group_arn" {
  description = "NGINX target group ARN"
  value       = aws_lb_target_group.nginx.arn
}

output "service_discovery_namespace_id" {
  description = "Service discovery namespace ID"
  value       = aws_service_discovery_private_dns_namespace.ingress.id
}

output "kms_key_arn" {
  description = "Ingress KMS key ARN"
  value       = aws_kms_key.ingress.arn
}

output "kms_key_id" {
  description = "Ingress KMS key ID"
  value       = aws_kms_key.ingress.key_id
}

output "ecs_security_group_id" {
  description = "ECS NGINX security group ID"
  value       = aws_security_group.ecs_nginx.id
}

output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}