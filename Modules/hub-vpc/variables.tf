#=============================================================================
# HUB VPC MODULE - VARIABLES
# modules/hub-vpc/variables.tf
#=============================================================================

#-----------------------------------------------------------------------------
# GENERAL VARIABLES
#-----------------------------------------------------------------------------
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-west-1"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

#-----------------------------------------------------------------------------
# ACCOUNT IDs
#-----------------------------------------------------------------------------
variable "networking_account_id" {
  description = "AWS Account ID for Networking Account"
  type        = string
}

variable "workload_account_id" {
  description = "AWS Account ID for Workload Account"
  type        = string
}

variable "shared_services_account_id" {
  description = "AWS Account ID for Shared Services Account"
  type        = string
}

#-----------------------------------------------------------------------------
# VPC CONFIGURATION
#-----------------------------------------------------------------------------
variable "hub_vpc_cidr" {
  description = "CIDR block for Hub VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "internal_cidr_blocks" {
  description = "List of internal CIDR blocks for security groups"
  type        = list(string)
  default = [
    "10.0.0.0/8",    # RFC 1918
    "172.16.0.0/12", # RFC 1918
    "192.168.0.0/16" # RFC 1918
  ]
}

#-----------------------------------------------------------------------------
# ORGANIZATION DETAILS
#-----------------------------------------------------------------------------
variable "organization_name" {
  description = "Organization name for Private CA"
  type        = string
  default     = "West Brom Building Society"
}

#-----------------------------------------------------------------------------
# TRANSIT GATEWAY
#-----------------------------------------------------------------------------
variable "transit_gateway_id" {
  description = "Transit Gateway ID for VPC attachment"
  type        = string
  default     = ""
}
