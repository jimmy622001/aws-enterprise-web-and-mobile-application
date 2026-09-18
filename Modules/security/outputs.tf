#====================================================================
# SECURITY MODULE - OUTPUTS
#====================================================================

# GuardDuty
output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.main.id
}

output "guardduty_findings_bucket_arn" {
  description = "GuardDuty findings S3 bucket ARN"
  value       = aws_s3_bucket.guardduty_findings.arn
}

# Security Hub
output "securityhub_account_id" {
  description = "Security Hub account ID"
  value       = aws_securityhub_account.main.id
}

# KMS
output "security_kms_key_arn" {
  description = "Security KMS key ARN"
  value       = aws_kms_key.security.arn
}

output "security_kms_key_id" {
  description = "Security KMS key ID"
  value       = aws_kms_key.security.key_id
}

# Secrets Manager
output "security_credentials_secret_arn" {
  description = "Security credentials Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.security_credentials.arn
}

# SNS
output "security_alerts_topic_arn" {
  description = "Security alerts SNS topic ARN"
  value       = aws_sns_topic.security_alerts.arn
}

# IAM Roles
output "cross_account_security_role_arn" {
  description = "Cross-account security role ARN"
  value       = aws_iam_role.cross_account_security.arn
}

output "security_admin_role_arn" {
  description = "Security admin role ARN"
  value       = aws_iam_role.security_admin.arn
}

output "security_audit_role_arn" {
  description = "Security audit role ARN"
  value       = aws_iam_role.security_audit.arn
}

# CloudTrail
output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = aws_cloudtrail.main.arn
}

output "cloudtrail_bucket_arn" {
  description = "CloudTrail S3 bucket ARN"
  value       = aws_s3_bucket.cloudtrail.arn
}

# Config
output "config_recorder_id" {
  description = "AWS Config recorder ID"
  value       = aws_config_configuration_recorder.main.id
}

output "config_bucket_arn" {
  description = "AWS Config S3 bucket ARN"
  value       = aws_s3_bucket.config.arn
}

# Access Analyzer
output "access_analyzer_arn" {
  description = "IAM Access Analyzer ARN"
  value       = aws_accessanalyzer_analyzer.main.arn
}