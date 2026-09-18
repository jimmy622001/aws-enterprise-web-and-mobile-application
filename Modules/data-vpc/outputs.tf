#====================================================================
# DATA VPC MODULE - OUTPUTS
#====================================================================

output "vpc_id" {
  description = "Data VPC ID"
  value       = aws_vpc.data.id
}

output "vpc_cidr" {
  description = "Data VPC CIDR block"
  value       = aws_vpc.data.cidr_block
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "tgw_subnet_ids" {
  description = "Transit Gateway attachment subnet IDs"
  value       = aws_subnet.tgw[*].id
}

# S3 Buckets
output "data_ingestion_bucket_arn" {
  description = "Data ingestion S3 bucket ARN"
  value       = aws_s3_bucket.data_ingestion.arn
}

output "data_ingestion_bucket_name" {
  description = "Data ingestion S3 bucket name"
  value       = aws_s3_bucket.data_ingestion.id
}

output "data_raw_bucket_arn" {
  description = "Raw data S3 bucket ARN"
  value       = aws_s3_bucket.data_raw.arn
}

output "data_raw_bucket_name" {
  description = "Raw data S3 bucket name"
  value       = aws_s3_bucket.data_raw.id
}

output "data_curated_bucket_arn" {
  description = "Curated data S3 bucket ARN"
  value       = aws_s3_bucket.data_curated.arn
}

output "data_curated_bucket_name" {
  description = "Curated data S3 bucket name"
  value       = aws_s3_bucket.data_curated.id
}

output "data_processed_bucket_arn" {
  description = "Processed data S3 bucket ARN"
  value       = aws_s3_bucket.data_processed.arn
}

output "data_processed_bucket_name" {
  description = "Processed data S3 bucket name"
  value       = aws_s3_bucket.data_processed.id
}

# Glue
output "glue_catalog_database_name" {
  description = "Glue catalog database name"
  value       = aws_glue_catalog_database.main.name
}

output "glue_workflow_name" {
  description = "Glue workflow name"
  value       = aws_glue_workflow.data_pipeline.name
}

output "glue_custom_etl_job_name" {
  description = "Custom ETL Glue job name"
  value       = aws_glue_job.custom_etl.name
}

output "glue_aggregation_job_name" {
  description = "Aggregation Glue job name"
  value       = aws_glue_job.aggregation.name
}

output "glue_extract_job_name" {
  description = "Extract to file Glue job name"
  value       = aws_glue_job.extract_to_file.name
}

output "glue_role_arn" {
  description = "Glue IAM role ARN"
  value       = aws_iam_role.glue_role.arn
}

# Airflow
output "airflow_environment_arn" {
  description = "MWAA Airflow environment ARN"
  value       = aws_mwaa_environment.airflow.arn
}

output "airflow_webserver_url" {
  description = "MWAA Airflow webserver URL"
  value       = aws_mwaa_environment.airflow.webserver_url
}

# Lake Formation
output "lakeformation_admin_role_arn" {
  description = "Lake Formation admin role ARN"
  value       = aws_iam_role.lakeformation_admin.arn
}

# DataZone
output "datazone_domain_id" {
  description = "DataZone domain ID"
  value       = aws_datazone_domain.main.id
}

output "datazone_domain_arn" {
  description = "DataZone domain ARN"
  value       = aws_datazone_domain.main.arn
}

# EventBridge
output "event_bus_name" {
  description = "EventBridge event bus name"
  value       = aws_cloudwatch_event_bus.data_events.name
}

output "event_bus_arn" {
  description = "EventBridge event bus ARN"
  value       = aws_cloudwatch_event_bus.data_events.arn
}

# Security
output "kms_key_arn" {
  description = "Data KMS key ARN"
  value       = aws_kms_key.data.arn
}

output "kms_key_id" {
  description = "Data KMS key ID"
  value       = aws_kms_key.data.key_id
}

output "guardduty_detector_id" {
  description = "GuardDuty detector ID"
  value       = aws_guardduty_detector.data.id
}

output "lambda_security_group_id" {
  description = "Lambda security group ID"
  value       = aws_security_group.lambda.id
}

output "lambda_role_arn" {
  description = "Lambda IAM role ARN"
  value       = aws_iam_role.lambda_role.arn
}