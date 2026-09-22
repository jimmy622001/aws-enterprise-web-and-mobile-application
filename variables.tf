#====================================================================
# ROOT MODULE VARIABLES
# AWS Infrastructure - Enterprise Web and Mobile Architecture
# All values should be set in terraform.tfvars
#====================================================================

#====================================================================
# DISASTER RECOVERY CONFIGURATION
#====================================================================

variable "enable_dr" {
  description = "Enable disaster recovery infrastructure in secondary region"
  type        = bool
  default     = false
}

variable "dr_region" {
  description = "AWS region for disaster recovery (e.g., eu-west-2 for London)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.dr_region))
    error_message = "DR region must be a valid AWS region format (e.g., eu-west-2)."
  }
}

variable "dr_strategy" {
  description = "Disaster recovery strategy (pilot-light, warm-standby, or active-active)"
  type        = string

  validation {
    condition     = contains(["pilot-light", "warm-standby", "active-active"], var.dr_strategy)
    error_message = "DR strategy must be one of: pilot-light, warm-standby, active-active."
  }
}

variable "dr_rto_hours" {
  description = "Recovery Time Objective in hours"
  type        = number

  validation {
    condition     = var.dr_rto_hours >= 1 && var.dr_rto_hours <= 72
    error_message = "RTO must be between 1 and 72 hours."
  }
}

variable "dr_rpo_hours" {
  description = "Recovery Point Objective in hours (data loss tolerance)"
  type        = number

  validation {
    condition     = var.dr_rpo_hours >= 0 && var.dr_rpo_hours <= 24
    error_message = "RPO must be between 0 and 24 hours."
  }
}

variable "dr_failover_mode" {
  description = "Failover mode (manual or automatic)"
  type        = string

  validation {
    condition     = contains(["manual", "automatic"], var.dr_failover_mode)
    error_message = "Failover mode must be either 'manual' or 'automatic'."
  }
}

# DR VPC CIDR Blocks (different from primary)
variable "dr_hub_vpc_cidr" {
  description = "CIDR block for DR Hub VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.dr_hub_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "dr_workload_vpc_cidr" {
  description = "CIDR block for DR Workload VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.dr_workload_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "dr_data_vpc_cidr" {
  description = "CIDR block for DR Data VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.dr_data_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "dr_shared_services_vpc_cidr" {
  description = "CIDR block for DR Shared Services VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.dr_shared_services_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

# DR Sizing Configuration
variable "dr_aurora_instance_class" {
  description = "Instance class for DR Aurora (typically smaller than primary)"
  type        = string
}

variable "dr_aurora_instance_count" {
  description = "Number of Aurora instances in DR region (pilot light = 1)"
  type        = number
}

variable "dr_eks_node_desired_size" {
  description = "Desired EKS node count in DR (pilot light = 0, warm standby = 2)"
  type        = number
}

variable "dr_postgres_instance_class" {
  description = "Instance class for DR PostgreSQL (typically smaller than primary)"
  type        = string
}

#====================================================================
# FEATURE FLAGS (Optional - Default to true)
# Use these to conditionally enable/disable major components
#====================================================================

variable "enable_client_vpn" {
  description = "Enable Client VPN in Private Ingress VPC (requires Okta SAML configuration)"
  type        = bool
  default     = true
}

variable "enable_eks" {
  description = "Enable EKS cluster deployment in Workload VPC"
  type        = bool
  default     = true
}

variable "enable_msk" {
  description = "Enable Kafka MSK cluster in Data VPC"
  type        = bool
  default     = true
}

variable "enable_airflow" {
  description = "Enable Apache Airflow (MWAA) in Data VPC"
  type        = bool
  default     = true
}

#====================================================================
# GENERAL CONFIGURATION (REQUIRED - No Defaults)
#====================================================================

variable "project_name" {
  description = "Project name for resource naming (e.g., example)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., poc, dev, staging, uat, prod)"
  type        = string

  validation {
    condition     = contains(["poc", "dev", "staging", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: poc, dev, staging, uat, prod."
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., eu-west-1)."
  }
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
}

#====================================================================
# AWS ACCOUNT IDS (REQUIRED - No Defaults)
#====================================================================

variable "networking_account_id" {
  description = "AWS Account ID for Networking Account"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.networking_account_id))
    error_message = "AWS Account ID must be a 12-digit number."
  }
}

variable "workload_account_id" {
  description = "AWS Account ID for Workload Account"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.workload_account_id))
    error_message = "AWS Account ID must be a 12-digit number."
  }
}

variable "shared_services_account_id" {
  description = "AWS Account ID for Shared Services Account"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.shared_services_account_id))
    error_message = "AWS Account ID must be a 12-digit number."
  }
}

#====================================================================
# VPC CIDR BLOCKS (REQUIRED - No Defaults)
#====================================================================

variable "hub_vpc_cidr" {
  description = "CIDR block for Hub VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.hub_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "private_ingress_vpc_cidr" {
  description = "CIDR block for Private Ingress VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.private_ingress_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "inspection_vpc_cidr" {
  description = "CIDR block for Inspection VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.inspection_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "workload_vpc_cidr" {
  description = "CIDR block for Workload VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.workload_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "ingress_vpc_cidr" {
  description = "CIDR block for Ingress VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.ingress_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "data_vpc_cidr" {
  description = "CIDR block for Data VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.data_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "shared_services_vpc_cidr" {
  description = "CIDR block for Shared Services VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.shared_services_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

#====================================================================
# TRANSIT GATEWAY (REQUIRED - No Defaults)
#====================================================================

variable "transit_gateway_asn" {
  description = "BGP ASN for Transit Gateway"
  type        = number

  validation {
    condition     = var.transit_gateway_asn >= 64512 && var.transit_gateway_asn <= 65534
    error_message = "Transit Gateway ASN must be in the private range (64512-65534)."
  }
}

variable "transit_gateway_cidr_blocks" {
  description = "CIDR blocks for Transit Gateway"
  type        = list(string)
}

variable "vpn_customer_gateway_ip" {
  description = "Public IP address of on-premises VPN device"
  type        = string

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.vpn_customer_gateway_ip))
    error_message = "Must be a valid IPv4 address."
  }
}

variable "vpn_customer_gateway_bgp_asn" {
  description = "BGP ASN for customer gateway"
  type        = number

  validation {
    condition     = var.vpn_customer_gateway_bgp_asn >= 64512 && var.vpn_customer_gateway_bgp_asn <= 65534
    error_message = "BGP ASN must be in the private range (64512-65534)."
  }
}

variable "network_firewall_delete_protection" {
  description = "Enable delete protection for Network Firewall"
  type        = bool
  default     = false
}

variable "network_firewall_allowed_domains" {
  description = "List of allowed domains for Network Firewall"
  type        = list(string)
  default     = [".amazonaws.com", ".aws.amazon.com"]
}

#====================================================================
# ROUTE 53 & DNS (REQUIRED - No Defaults)
#====================================================================

variable "public_hosted_zone_name" {
  description = "Public hosted zone domain name"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-\\.]+[a-z0-9]$", var.public_hosted_zone_name))
    error_message = "Must be a valid domain name."
  }
}

variable "private_hosted_zone_name" {
  description = "Private hosted zone domain name"
  type        = string
}

variable "dns_firewall_blocked_domains" {
  description = "List of blocked domains for DNS Firewall"
  type        = list(string)
  default     = []
}

variable "dns_firewall_allowed_domains" {
  description = "List of allowed domains for DNS Firewall"
  type        = list(string)
  default     = []
}

#====================================================================
# CLIENT VPN (REQUIRED - No Defaults)
#====================================================================

variable "client_vpn_cidr_block" {
  description = "CIDR block for Client VPN"
  type        = string

  validation {
    condition     = can(cidrhost(var.client_vpn_cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "client_vpn_split_tunnel" {
  description = "Enable split tunnel for Client VPN"
  type        = bool
  default     = true
}

variable "client_vpn_session_timeout_hours" {
  description = "Session timeout in hours for Client VPN"
  type        = number
  default     = 8
}

variable "client_vpn_server_certificate_body" {
  description = "Certificate body for Client VPN server"
  type        = string
  sensitive   = true
  default     = ""
}

variable "client_vpn_server_private_key" {
  description = "Private key for Client VPN server certificate"
  type        = string
  sensitive   = true
  default     = ""
}

variable "okta_saml_metadata" {
  description = "SAML metadata document from Okta IDP"
  type        = string
  sensitive   = true
  default     = ""
}

variable "okta_saml_provider_arn" {
  description = "ARN of Okta SAML provider in IAM"
  type        = string
}

variable "client_vpn_server_certificate_arn" {
  description = "ACM certificate ARN for Client VPN server"
  type        = string
}

#====================================================================
# CLOUDFRONT & WAF (REQUIRED - No Defaults)
#====================================================================

variable "web_domain_aliases" {
  description = "Domain aliases for Web CloudFront distribution"
  type        = list(string)
}

variable "cms_domain_aliases" {
  description = "Domain aliases for CMS CloudFront distribution"
  type        = list(string)
}

variable "acm_certificate_arn_us_east_1" {
  description = "ACM certificate ARN in us-east-1 for CloudFront"
  type        = string
}

variable "acm_certificate_arn_regional" {
  description = "ACM certificate ARN in regional region for ALB/API Gateway"
  type        = string
}

variable "cloudfront_custom_header_value" {
  description = "Custom header value for CloudFront to ALB verification"
  type        = string
  sensitive   = true
}

#====================================================================
# API GATEWAY (Optional - Have Defaults)
#====================================================================

variable "api_gateway_domain_name" {
  description = "Custom domain name for API Gateway"
  type        = string
  default     = ""
}

variable "api_throttling_burst_limit" {
  description = "API Gateway throttling burst limit"
  type        = number
  default     = 5000
}

variable "api_throttling_rate_limit" {
  description = "API Gateway throttling rate limit"
  type        = number
  default     = 10000
}

#====================================================================
# SES (REQUIRED - No Defaults)
#====================================================================

variable "ses_domain" {
  description = "Domain for SES email service"
  type        = string
}

#====================================================================
# SECURITY (REQUIRED - No Defaults)
#====================================================================

variable "security_alert_email" {
  description = "Email address for security alerts"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.security_alert_email))
    error_message = "Must be a valid email address."
  }
}

variable "cross_account_principals" {
  description = "List of cross-account IAM principals for access"
  type        = list(string)
}

variable "audit_principals" {
  description = "List of IAM principals for security audit access"
  type        = list(string)
}

#====================================================================
# EKS CLUSTER (Optional - Have Defaults)
#====================================================================

variable "eks_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.29"
}

variable "eks_public_access" {
  description = "Enable public access to EKS API endpoint"
  type        = bool
  default     = false
}

variable "system_node_instance_types" {
  description = "Instance types for system node group"
  type        = list(string)
  default     = ["m6i.large", "m5.large"]
}

variable "system_node_desired_size" {
  description = "Desired size of system node group"
  type        = number
  default     = 3
}

variable "system_node_min_size" {
  description = "Minimum size of system node group"
  type        = number
  default     = 2
}

variable "system_node_max_size" {
  description = "Maximum size of system node group"
  type        = number
  default     = 5
}

variable "app_node_instance_types" {
  description = "Instance types for application node group"
  type        = list(string)
  default     = ["m6i.xlarge", "m5.xlarge"]
}

variable "app_node_desired_size" {
  description = "Desired size of application node group"
  type        = number
  default     = 3
}

variable "app_node_min_size" {
  description = "Minimum size of application node group"
  type        = number
  default     = 2
}

variable "app_node_max_size" {
  description = "Maximum size of application node group"
  type        = number
  default     = 20
}

variable "app_node_capacity_type" {
  description = "Capacity type for application nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "eks_admin_role_arns" {
  description = "IAM role ARNs for EKS cluster admin access"
  type        = list(string)
  default     = []
}

#====================================================================
# EKS ADDONS (Optional - Have Defaults)
#====================================================================

variable "vpc_cni_version" {
  description = "VPC CNI addon version"
  type        = string
  default     = "v1.16.0-eksbuild.1"
}

variable "coredns_version" {
  description = "CoreDNS addon version"
  type        = string
  default     = "v1.11.1-eksbuild.6"
}

variable "kube_proxy_version" {
  description = "Kube Proxy addon version"
  type        = string
  default     = "v1.29.0-eksbuild.2"
}

variable "ebs_csi_version" {
  description = "EBS CSI Driver addon version"
  type        = string
  default     = "v1.27.0-eksbuild.1"
}

#====================================================================
# ISTIO (Optional - Have Defaults)
#====================================================================

variable "istio_version" {
  description = "Istio Helm chart version"
  type        = string
  default     = "1.20.2"
}

#====================================================================
# AURORA RDS (Optional - Have Defaults)
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
# COGNITO (Optional - Have Defaults)
#====================================================================

variable "cognito_callback_urls" {
  description = "Callback URLs for Cognito user pool"
  type        = list(string)
  default     = []
}

variable "cognito_logout_urls" {
  description = "Logout URLs for Cognito user pool"
  type        = list(string)
  default     = []
}

#====================================================================
# KAFKA MSK (Optional - Have Defaults)
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
# DATA PLATFORM (Optional - Have Defaults)
#====================================================================

variable "glue_worker_type" {
  description = "Glue worker type"
  type        = string
  default     = "G.1X"
}

variable "glue_number_of_workers" {
  description = "Number of Glue workers"
  type        = number
  default     = 2
}

variable "airflow_version" {
  description = "MWAA Airflow version"
  type        = string
  default     = "2.7.2"
}

variable "airflow_environment_class" {
  description = "MWAA environment class"
  type        = string
  default     = "mw1.medium"
}

variable "airflow_max_workers" {
  description = "Maximum number of Airflow workers"
  type        = number
  default     = 10
}

variable "airflow_min_workers" {
  description = "Minimum number of Airflow workers"
  type        = number
  default     = 1
}

#====================================================================
# SHARED SERVICES (Optional - Have Defaults)
#====================================================================

variable "ecr_repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default = [
    "nginx-proxy",
    "strapi",
    "api-service",
    "worker-service",
    "web-app"
  ]
}

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

#====================================================================
# WAF (Optional - Have Defaults)
#====================================================================

variable "waf_blocked_countries" {
  description = "List of country codes to block"
  type        = list(string)
  default     = ["RU", "CN", "KP", "IR"]
}

#====================================================================
# LOGGING (Optional - Have Defaults)
#====================================================================

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "cloudtrail_log_retention_days" {
  description = "CloudTrail log retention in days"
  type        = number
  default     = 365
}

#====================================================================
# ORGANIZATION (Optional - Have Defaults)
#====================================================================

variable "organization_name" {
  description = "Organization name for Private CA and tags"
  type        = string
  default     = "Example Organization"
}