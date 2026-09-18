#====================================================================
# WORKLOAD VPC MODULE - OUTPUTS
#====================================================================

output "vpc_id" {
  description = "Workload VPC ID"
  value       = aws_vpc.workload.id
}

output "vpc_cidr" {
  description = "Workload VPC CIDR block"
  value       = aws_vpc.workload.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = aws_subnet.database[*].id
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

output "nlb_arn" {
  description = "Network Load Balancer ARN"
  value       = aws_lb.network.arn
}

output "nlb_dns_name" {
  description = "Network Load Balancer DNS name"
  value       = aws_lb.network.dns_name
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.web.id
}

output "cognito_user_pool_domain" {
  description = "Cognito User Pool Domain"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "msk_cluster_arn" {
  description = "MSK Kafka cluster ARN"
  value       = aws_msk_cluster.main.arn
}

output "msk_bootstrap_brokers_tls" {
  description = "MSK bootstrap brokers TLS connection string"
  value       = aws_msk_cluster.main.bootstrap_brokers_tls
}

output "aurora_cluster_endpoint" {
  description = "Aurora cluster endpoint"
  value       = aws_rds_cluster.aurora.endpoint
}

output "aurora_cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "aurora_cluster_id" {
  description = "Aurora cluster identifier"
  value       = aws_rds_cluster.aurora.id
}

output "eks_nodes_security_group_id" {
  description = "EKS nodes security group ID"
  value       = aws_security_group.eks_nodes.id
}

output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}

output "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_execution.arn
}

output "kms_key_arn" {
  description = "Workload KMS key ARN"
  value       = aws_kms_key.workload.arn
}

output "kms_key_id" {
  description = "Workload KMS key ID"
  value       = aws_kms_key.workload.key_id
}