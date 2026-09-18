#====================================================================
# SHARED SERVICES MODULE - VARIABLES
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
  description = "CIDR block for Shared Services VPC"
  type        = string
  default     = "10.50.0.0/16"
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

variable "organization_name" {
  description = "Organization name for Private CA"
  type        = string
  default     = "West Brom"
}

#====================================================================
# CROSS-ACCOUNT CONFIGURATION
#====================================================================

variable "networking_account_id" {
  description = "Networking account ID for cross-account access"
  type        = string
}

variable "workload_account_id" {
  description = "Workload account ID for cross-account access"
  type        = string
}

#====================================================================
# ECR CONFIGURATION
#====================================================================

variable "ecr_repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default = [
    "nginx-proxy",
    "strapi",
    "api-gateway",
    "worker",
    "web-app"
  ]
}

#====================================================================
# POSTGRES CONFIGURATION
#====================================================================

variable "postgres_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "postgres_instance_class" {
  description = "RDS instance class for PostgreSQL"
  type        = string
  default     = "db.r6g.large"
}

variable "postgres_allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 100
}

variable "postgres_max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling in GB"
  type        = number
  default     = 500
}

variable "postgres_database_name" {
  description = "Default database name"
  type        = string
  default     = "sharedservices"
}

variable "postgres_master_username" {
  description = "Master username for PostgreSQL"
  type        = string
  default     = "dbadmin"
}

variable "postgres_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

#====================================================================
# SES CONFIGURATION
#====================================================================

variable "ses_domain" {
  description = "Domain for SES email service"
  type        = string
}