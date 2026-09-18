#====================================================================
# WORKLOAD VPC MODULE - VARIABLES
#====================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for Workload VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID for VPC attachment"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

#====================================================================
# COGNITO VARIABLES
#====================================================================

variable "cognito_callback_urls" {
  description = "Callback URLs for Cognito user pool client"
  type        = list(string)
  default     = ["https://localhost:3000/callback"]
}

variable "cognito_logout_urls" {
  description = "Logout URLs for Cognito user pool client"
  type        = list(string)
  default     = ["https://localhost:3000/logout"]
}

#====================================================================
# MSK KAFKA VARIABLES
#====================================================================

variable "msk_version" {
  description = "Kafka version for MSK cluster"
  type        = string
  default     = "3.5.1"
}

variable "msk_instance_type" {
  description = "Instance type for MSK brokers"
  type        = string
  default     = "kafka.m5.large"
}

variable "msk_broker_count" {
  description = "Number of MSK broker nodes"
  type        = number
  default     = 3
}

variable "msk_ebs_volume_size" {
  description = "EBS volume size in GB for MSK brokers"
  type        = number
  default     = 100
}

#====================================================================
# AURORA RDS VARIABLES
#====================================================================

variable "aurora_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "aurora_instance_class" {
  description = "Instance class for Aurora instances"
  type        = string
  default     = "db.r6g.large"
}

variable "aurora_instance_count" {
  description = "Number of Aurora instances"
  type        = number
  default     = 2
}

variable "aurora_database_name" {
  description = "Default database name"
  type        = string
  default     = "workload"
}

variable "aurora_master_username" {
  description = "Master username for Aurora cluster"
  type        = string
  default     = "dbadmin"
}

#====================================================================
# S3 LOGGING VARIABLES
#====================================================================

variable "access_logs_bucket_name" {
  description = "Central S3 access logs bucket name"
  type        = string
  default     = ""
}