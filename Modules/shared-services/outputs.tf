#====================================================================
# SHARED SERVICES MODULE - OUTPUTS
#====================================================================

# VPC Outputs
output "vpc_id" {
  description = "Shared Services VPC ID"
  value       = aws_vpc.shared_services.id
}

output "vpc_cidr" {
  description = "Shared Services VPC CIDR block"
  value       = aws_vpc.shared_services.cidr_block
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

# Transfer Family Outputs
output "transfer_server_id" {
  description = "AWS Transfer Family server ID"
  value       = aws_transfer_server.sftp.id
}

output "transfer_server_endpoint" {
  description = "AWS Transfer Family server endpoint"
  value       = aws_transfer_server.sftp.endpoint
}

output "transfer_bucket_arn" {
  description = "Transfer Family S3 bucket ARN"
  value       = aws_s3_bucket.transfer.arn
}

output "transfer_bucket_name" {
  description = "Transfer Family S3 bucket name"
  value       = aws_s3_bucket.transfer.id
}

# ECR Outputs
output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = { for k, v in aws_ecr_repository.main : k => v.repository_url }
}

output "ecr_repository_arns" {
  description = "ECR repository ARNs"
  value       = { for k, v in aws_ecr_repository.main : k => v.arn }
}

# Postgres Outputs
output "postgres_endpoint" {
  description = "PostgreSQL endpoint"
  value       = aws_db_instance.postgres.endpoint
}

output "postgres_address" {
  description = "PostgreSQL address"
  value       = aws_db_instance.postgres.address
}

output "postgres_port" {
  description = "PostgreSQL port"
  value       = aws_db_instance.postgres.port
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = aws_db_instance.postgres.db_name
}

# SES Outputs
output "ses_domain_identity_arn" {
  description = "SES domain identity ARN"
  value       = aws_ses_domain_identity.main.arn
}

output "ses_domain_identity_verification_token" {
  description = "SES domain identity verification token"
  value       = aws_ses_domain_identity.main.verification_token
}

output "ses_dkim_tokens" {
  description = "SES DKIM tokens for DNS configuration"
  value       = aws_ses_domain_dkim.main.dkim_tokens
}

output "ses_configuration_set_name" {
  description = "SES configuration set name"
  value       = aws_ses_configuration_set.main.name
}

# SNS Outputs
output "notifications_topic_arn" {
  description = "SNS notifications topic ARN"
  value       = aws_sns_topic.notifications.arn
}

output "alerts_topic_arn" {
  description = "SNS alerts topic ARN"
  value       = aws_sns_topic.alerts.arn
}

# S3 Outputs
output "access_logs_bucket_arn" {
  description = "Central S3 access logs bucket ARN"
  value       = aws_s3_bucket.access_logs.arn
}

output "access_logs_bucket_name" {
  description = "Central S3 access logs bucket name"
  value       = aws_s3_bucket.access_logs.id
}

output "shared_data_bucket_arn" {
  description = "Shared data S3 bucket ARN"
  value       = aws_s3_bucket.shared_data.arn
}

output "shared_data_bucket_name" {
  description = "Shared data S3 bucket name"
  value       = aws_s3_bucket.shared_data.id
}

# Security Outputs
output "kms_key_arn" {
  description = "Shared Services KMS key ARN"
  value       = aws_kms_key.shared_services.arn
}

output "kms_key_id" {
  description = "Shared Services KMS key ID"
  value       = aws_kms_key.shared_services.key_id
}

output "private_ca_arn" {
  description = "Private CA ARN"
  value       = aws_acmpca_certificate_authority.shared.arn
}

output "shared_credentials_secret_arn" {
  description = "Shared credentials Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.shared_credentials.arn
}

# Security Groups
output "transfer_security_group_id" {
  description = "Transfer Family security group ID"
  value       = aws_security_group.transfer.id
}

output "postgres_security_group_id" {
  description = "PostgreSQL security group ID"
  value       = aws_security_group.postgres.id
}

output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}