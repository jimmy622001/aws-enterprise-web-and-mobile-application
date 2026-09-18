#==============================================================================
# TRANSIT GATEWAY MODULE - VARIABLES
#==============================================================================

#------------------------------------------------------------------------------
# GENERAL VARIABLES
#------------------------------------------------------------------------------
variable "project_name" {
  description = "Name of the project"
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

#------------------------------------------------------------------------------
# TRANSIT GATEWAY CONFIGURATION
#------------------------------------------------------------------------------
variable "transit_gateway_asn" {
  description = "Amazon side ASN for Transit Gateway"
  type        = number
  default     = 64512
}

variable "flow_logs_retention_days" {
  description = "Retention period for TGW flow logs"
  type        = number
  default     = 90
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting flow logs"
  type        = string
}

#------------------------------------------------------------------------------
# ACCOUNT IDS
#------------------------------------------------------------------------------
variable "networking_account_id" {
  description = "Networking Account ID"
  type        = string
}

variable "workload_account_id" {
  description = "Workload Account ID"
  type        = string
}

variable "shared_services_account_id" {
  description = "Shared Services Account ID"
  type        = string
}

#------------------------------------------------------------------------------
# HUB VPC CONFIGURATION
#------------------------------------------------------------------------------
variable "hub_vpc_id" {
  description = "Hub VPC ID"
  type        = string
}

variable "hub_vpc_cidr" {
  description = "Hub VPC CIDR block"
  type        = string
}

variable "hub_vpc_tgw_subnet_ids" {
  description = "List of subnet IDs in Hub VPC for TGW attachment"
  type        = list(string)
}

#------------------------------------------------------------------------------
# PRIVATE INGRESS VPC CONFIGURATION (CLIENT VPN)
#------------------------------------------------------------------------------
variable "private_ingress_vpc_id" {
  description = "Private Ingress VPC ID"
  type        = string
}

variable "private_ingress_vpc_cidr" {
  description = "Private Ingress VPC CIDR block"
  type        = string
}

variable "private_ingress_vpc_tgw_subnet_ids" {
  description = "List of subnet IDs in Private Ingress VPC for TGW attachment"
  type        = list(string)
}

#------------------------------------------------------------------------------
# INSPECTION VPC CONFIGURATION (NETWORK FIREWALL)
#------------------------------------------------------------------------------
variable "inspection_vpc_id" {
  description = "Inspection VPC ID"
  type        = string
}

variable "inspection_vpc_cidr" {
  description = "Inspection VPC CIDR block"
  type        = string
}

variable "inspection_vpc_tgw_subnet_ids" {
  description = "List of subnet IDs in Inspection VPC for TGW attachment"
  type        = list(string)
}

#------------------------------------------------------------------------------
# WORKLOAD VPC CONFIGURATION
#------------------------------------------------------------------------------
variable "workload_vpc_id" {
  description = "Workload VPC ID"
  type        = string
}

variable "workload_vpc_cidr" {
  description = "Workload VPC CIDR block"
  type        = string
}

variable "workload_vpc_tgw_subnet_ids" {
  description = "List of subnet IDs in Workload VPC for TGW attachment"
  type        = list(string)
}

#------------------------------------------------------------------------------
# INGRESS VPC CONFIGURATION (NGINX/ECS FARGATE)
#------------------------------------------------------------------------------
variable "ingress_vpc_id" {
  description = "Ingress VPC ID"
  type        = string
}

variable "ingress_vpc_cidr" {
  description = "Ingress VPC CIDR block"
  type        = string
}

variable "ingress_vpc_tgw_subnet_ids" {
  description = "List of subnet IDs in Ingress VPC for TGW attachment"
  type        = list(string)
}

#------------------------------------------------------------------------------
# DATA VPC CONFIGURATION
#------------------------------------------------------------------------------
variable "data_vpc_id" {
  description = "Data VPC ID"
  type        = string
}

variable "data_vpc_cidr" {
  description = "Data VPC CIDR block"
  type        = string
}

variable "data_vpc_tgw_subnet_ids" {
  description = "List of subnet IDs in Data VPC for TGW attachment"
  type        = list(string)
}

#------------------------------------------------------------------------------
# SHARED SERVICES VPC CONFIGURATION
#------------------------------------------------------------------------------
variable "shared_services_vpc_id" {
  description = "Shared Services VPC ID"
  type        = string
}

variable "shared_services_vpc_cidr" {
  description = "Shared Services VPC CIDR block"
  type        = string
}

variable "shared_services_vpc_tgw_subnet_ids" {
  description = "List of subnet IDs in Shared Services VPC for TGW attachment"
  type        = list(string)
}

#------------------------------------------------------------------------------
# SITE-TO-SITE VPN CONFIGURATION (ON-PREMISES CONNECTIVITY)
#------------------------------------------------------------------------------
variable "onprem_bgp_asn" {
  description = "BGP ASN for on-premises network"
  type        = number
  default     = 65000
}

variable "onprem_gateway_ip" {
  description = "Public IP address of on-premises VPN gateway"
  type        = string
}

variable "onprem_cidr_blocks" {
  description = "List of on-premises CIDR blocks"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

#------------------------------------------------------------------------------
# MULTI-REGION PEERING (OPTIONAL)
#------------------------------------------------------------------------------
variable "enable_cross_region_peering" {
  description = "Enable cross-region Transit Gateway peering"
  type        = bool
  default     = false
}

variable "peer_region" {
  description = "AWS region for TGW peering"
  type        = string
  default     = ""
}

variable "peer_transit_gateway_id" {
  description = "Transit Gateway ID in peer region"
  type        = string
  default     = ""
}
