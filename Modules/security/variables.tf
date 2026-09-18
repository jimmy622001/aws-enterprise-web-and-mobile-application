#====================================================================
# SECURITY MODULE - VARIABLES
#====================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

#====================================================================
# CROSS-ACCOUNT CONFIGURATION
#====================================================================

variable "cross_account_principals" {
  description = "List of cross-account IAM principals for access"
  type        = list(string)
  default     = []
}

variable "audit_principals" {
  description = "List of IAM principals for security audit access"
  type        = list(string)
  default     = []
}

variable "is_organization_management_account" {
  description = "Whether this is the AWS Organizations management account"
  type        = bool
  default     = false
}

#====================================================================
# ALERTING CONFIGURATION
#====================================================================

variable "security_alert_email" {
  description = "Email address for security alerts"
  type        = string
  default     = ""
}