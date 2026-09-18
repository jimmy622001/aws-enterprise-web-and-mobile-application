#===============================================================================
# INSPECTION VPC MODULE - VARIABLES
#===============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the Inspection VPC"
  type        = string
  default     = "10.2.0.0/16"
}

variable "private_domain" {
  description = "Private domain name for internal DNS"
  type        = string
  default     = "internal.example.com"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID for attachment"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_firewall_policy_change_protection" {
  description = "Enable firewall policy change protection"
  type        = bool
  default     = false
}

variable "enable_subnet_change_protection" {
  description = "Enable subnet change protection"
  type        = bool
  default     = false
}

variable "allowed_domains" {
  description = "List of allowed domains for egress traffic"
  type        = list(string)
  default = [
    ".amazonaws.com",
    ".aws.amazon.com"
  ]
}

variable "blocked_domains" {
  description = "List of blocked domains"
  type        = list(string)
  default = [
    "malware.com",
    "badsite.com"
  ]
}
