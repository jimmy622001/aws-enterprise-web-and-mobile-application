#===============================================================================
# PRIVATE INGRESS VPC MODULE - VARIABLES
# Location: modules/private-ingress-vpc/variables.tf
#===============================================================================

#-------------------------------------------------------------------------------
# GENERAL VARIABLES
#-------------------------------------------------------------------------------
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

variable "networking_account_id" {
  description = "AWS Account ID for Networking Account"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

#-------------------------------------------------------------------------------
# VPC CONFIGURATION
#-------------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for Private Ingress VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

#-------------------------------------------------------------------------------
# TRANSIT GATEWAY
#-------------------------------------------------------------------------------
variable "transit_gateway_id" {
  description = "Transit Gateway ID for VPC attachment"
  type        = string
}

#-------------------------------------------------------------------------------
# CLIENT VPN CONFIGURATION
#-------------------------------------------------------------------------------
variable "client_vpn_cidr" {
  description = "CIDR block for Client VPN connections"
  type        = string
  default     = "172.16.0.0/16"
}

variable "split_tunnel_enabled" {
  description = "Enable split tunnel for Client VPN"
  type        = bool
  default     = true
}

variable "session_timeout_hours" {
  description = "Session timeout in hours for Client VPN"
  type        = number
  default     = 8
}

variable "dns_servers" {
  description = "DNS servers for Client VPN"
  type        = list(string)
  default     = ["10.0.0.2"]
}

#-------------------------------------------------------------------------------
# OKTA SAML CONFIGURATION
#-------------------------------------------------------------------------------
variable "okta_saml_metadata" {
  description = "SAML metadata document from Okta IDP"
  type        = string
  sensitive   = true
}

#-------------------------------------------------------------------------------
# CERTIFICATES
#-------------------------------------------------------------------------------
variable "server_private_key" {
  description = "Private key for Client VPN server certificate"
  type        = string
  sensitive   = true
}

variable "server_certificate_body" {
  description = "Certificate body for Client VPN server"
  type        = string
  sensitive   = true
}

variable "server_certificate_chain" {
  description = "Certificate chain for Client VPN server"
  type        = string
  sensitive   = true
  default     = ""
}

#-------------------------------------------------------------------------------
# LOGGING
#-------------------------------------------------------------------------------
variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}
