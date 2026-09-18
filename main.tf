#====================================================================
# ROOT MODULE - MAIN.TF
# AWS Infrastructure - Enterprise Web and Mobile Architecture
# Multi-Account Architecture: Networking, Workload, Shared Services
# Region: eu-west-1 (Ireland)
#====================================================================

# Note: Terraform and Provider configurations have been moved to providers.tf

#====================================================================
# DATA SOURCES
#====================================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

#====================================================================
# LOCAL VALUES
#====================================================================

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

  common_tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

#====================================================================
# NETWORKING ACCOUNT MODULES
#====================================================================

#--------------------------------------------------------------------
# Route 53 & DNS Firewall
#--------------------------------------------------------------------
module "networking_dns" {
  source = "./modules/networking-dns"

  providers = {
    aws = aws.networking
  }

  project_name        = var.project_name
  environment         = var.environment
  public_domain_name  = var.public_hosted_zone_name
  private_domain_name = var.private_hosted_zone_name

  vpc_ids_for_private_zone = [module.hub_vpc.vpc_id]
  dns_firewall_enabled     = true

  tags = local.common_tags
}

#--------------------------------------------------------------------
# Hub VPC
#--------------------------------------------------------------------
module "hub_vpc" {
  source = "./modules/hub-vpc"

  providers = {
    aws = aws.networking
  }

  project_name       = var.project_name
  environment        = var.environment
  hub_vpc_cidr       = var.hub_vpc_cidr
  availability_zones = local.availability_zones

  # Account IDs
  networking_account_id      = var.networking_account_id
  workload_account_id        = var.workload_account_id
  shared_services_account_id = var.shared_services_account_id

  tags = local.common_tags
}

#--------------------------------------------------------------------
# Private Ingress VPC (Client VPN)
#--------------------------------------------------------------------
module "private_ingress_vpc" {
  source = "./modules/private-ingress-vpc"

  providers = {
    aws = aws.networking
  }

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.private_ingress_vpc_cidr
  availability_zones = local.availability_zones
  transit_gateway_id = module.transit_gateway.transit_gateway_id

  # Account ID
  networking_account_id = var.networking_account_id

  # Client VPN Configuration
  client_vpn_cidr         = var.client_vpn_cidr_block
  split_tunnel_enabled    = var.client_vpn_split_tunnel
  session_timeout_hours   = var.client_vpn_session_timeout_hours
  server_certificate_body = var.client_vpn_server_certificate_body
  server_private_key      = var.client_vpn_server_private_key
  okta_saml_metadata      = var.okta_saml_metadata

  tags = local.common_tags
}

#--------------------------------------------------------------------
# Inspection VPC (Network Firewall)
#--------------------------------------------------------------------
module "inspection_vpc" {
  source = "./modules/inspection-vpc"

  providers = {
    aws = aws.networking
  }

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.inspection_vpc_cidr
  transit_gateway_id = module.transit_gateway.transit_gateway_id

  # Network Firewall Configuration
  enable_firewall_policy_change_protection = var.network_firewall_delete_protection
  allowed_domains                          = var.network_firewall_allowed_domains

  tags = local.common_tags
}

#--------------------------------------------------------------------
# Transit Gateway
#--------------------------------------------------------------------
module "transit_gateway" {
  source = "./modules/transit-gateway"

  providers = {
    aws                 = aws.networking
    aws.workload        = aws.workload
    aws.shared_services = aws.shared_services
  }

  project_name = var.project_name
  environment  = var.environment

  # Transit Gateway Configuration
  transit_gateway_asn = var.transit_gateway_asn
  kms_key_arn         = module.hub_vpc.kms_key_arn

  # Account IDs
  networking_account_id      = var.networking_account_id
  workload_account_id        = var.workload_account_id
  shared_services_account_id = var.shared_services_account_id

  # Hub VPC
  hub_vpc_id             = module.hub_vpc.vpc_id
  hub_vpc_cidr           = var.hub_vpc_cidr
  hub_vpc_tgw_subnet_ids = module.hub_vpc.tgw_subnet_ids

  # Private Ingress VPC
  private_ingress_vpc_id             = module.private_ingress_vpc.vpc_id
  private_ingress_vpc_cidr           = var.private_ingress_vpc_cidr
  private_ingress_vpc_tgw_subnet_ids = module.private_ingress_vpc.tgw_attachment_subnet_ids

  # Inspection VPC
  inspection_vpc_id             = module.inspection_vpc.vpc_id
  inspection_vpc_cidr           = var.inspection_vpc_cidr
  inspection_vpc_tgw_subnet_ids = module.inspection_vpc.tgw_attachment_subnet_ids

  # Workload VPC
  workload_vpc_id             = module.workload_vpc.vpc_id
  workload_vpc_cidr           = var.workload_vpc_cidr
  workload_vpc_tgw_subnet_ids = module.workload_vpc.tgw_subnet_ids

  # Ingress VPC
  ingress_vpc_id             = module.ingress_vpc.vpc_id
  ingress_vpc_cidr           = var.ingress_vpc_cidr
  ingress_vpc_tgw_subnet_ids = module.ingress_vpc.tgw_subnet_ids

  # Data VPC
  data_vpc_id             = module.data_vpc.vpc_id
  data_vpc_cidr           = var.data_vpc_cidr
  data_vpc_tgw_subnet_ids = module.data_vpc.tgw_subnet_ids

  # Shared Services VPC
  shared_services_vpc_id             = module.shared_services.vpc_id
  shared_services_vpc_cidr           = var.shared_services_vpc_cidr
  shared_services_vpc_tgw_subnet_ids = module.shared_services.tgw_subnet_ids

  # VPN Configuration (On-premises connectivity)
  onprem_gateway_ip = var.vpn_customer_gateway_ip
  onprem_bgp_asn    = var.vpn_customer_gateway_bgp_asn

  tags = local.common_tags
}

#====================================================================
# WORKLOAD ACCOUNT MODULES
#====================================================================

#--------------------------------------------------------------------
# Workload VPC (EKS, Aurora, MSK, Lambda, Cognito)
#--------------------------------------------------------------------
module "workload_vpc" {
  source = "./modules/workload-vpc"

  providers = {
    aws = aws.workload
  }

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.workload_vpc_cidr
  transit_gateway_id = module.transit_gateway.transit_gateway_id

  # Cognito Configuration
  cognito_callback_urls = var.cognito_callback_urls
  cognito_logout_urls   = var.cognito_logout_urls

  # MSK Configuration
  msk_version         = var.msk_version
  msk_instance_type   = var.msk_instance_type
  msk_broker_count    = var.msk_broker_count
  msk_ebs_volume_size = var.msk_ebs_volume_size

  # Aurora Configuration
  aurora_engine_version  = var.aurora_engine_version
  aurora_instance_class  = var.aurora_instance_class
  aurora_instance_count  = var.aurora_instance_count
  aurora_database_name   = var.aurora_database_name
  aurora_master_username = var.aurora_master_username

  # S3 Access Logging
  access_logs_bucket_name = module.shared_services.access_logs_bucket_name

  tags = local.common_tags
}

#--------------------------------------------------------------------
# Ingress VPC (ALB, NLB, ECS Fargate, NGINX)
#--------------------------------------------------------------------
module "ingress_vpc" {
  source = "./modules/ingress-vpc"

  providers = {
    aws = aws.workload
  }

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.ingress_vpc_cidr
  transit_gateway_id = module.transit_gateway.transit_gateway_id

  # ACM Certificate for HTTPS
  acm_certificate_arn = var.acm_certificate_arn_regional

  tags = local.common_tags
}

#--------------------------------------------------------------------
# Data VPC (Glue, Airflow, Lake Formation, DataZone)
#--------------------------------------------------------------------
module "data_vpc" {
  source = "./modules/data-vpc"

  providers = {
    aws = aws.workload
  }

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.data_vpc_cidr
  transit_gateway_id = module.transit_gateway.transit_gateway_id

  # Glue Configuration
  glue_worker_type       = var.glue_worker_type
  glue_number_of_workers = var.glue_number_of_workers

  # Airflow Configuration
  airflow_version           = var.airflow_version
  airflow_environment_class = var.airflow_environment_class
  airflow_max_workers       = var.airflow_max_workers
  airflow_min_workers       = var.airflow_min_workers

  tags = local.common_tags
}

#--------------------------------------------------------------------
# CloudFront, WAF, Shield Advanced, API Gateway
#--------------------------------------------------------------------
module "cloudfront_waf" {
  source = "./modules/cloudfront-waf"

  providers = {
    aws           = aws.workload
    aws.us-east-1 = aws.us_east_1
  }

  project_name = var.project_name
  environment  = var.environment

  # CloudFront Configuration
  web_domain_aliases = var.web_domain_aliases
  cms_domain_aliases = var.cms_domain_aliases

  # ACM Certificates
  acm_certificate_arn_us_east_1 = var.acm_certificate_arn_us_east_1
  acm_certificate_arn_regional  = var.acm_certificate_arn_regional

  # Origin Configuration
  ingress_alb_dns_name           = module.ingress_vpc.alb_dns_name
  ingress_nlb_dns_name           = module.ingress_vpc.nlb_dns_name
  ingress_nlb_arn                = module.ingress_vpc.nlb_arn
  cloudfront_custom_header_value = var.cloudfront_custom_header_value

  # WAF Configuration
  blocked_countries = var.waf_blocked_countries

  # API Gateway Configuration
  api_domain_name            = var.api_gateway_domain_name
  api_throttling_burst_limit = var.api_throttling_burst_limit
  api_throttling_rate_limit  = var.api_throttling_rate_limit

  tags = local.common_tags
}

#--------------------------------------------------------------------
# EKS Cluster (with Istio Service Mesh)
#--------------------------------------------------------------------
# Temporarily disabled for POC - Enable after fixing Helm chart syntax
# module "eks" {
#   source = "./modules/eks"
# 
#   providers = {
#     aws = aws.workload
#   }
# 
#   project_name       = var.project_name
#   environment        = var.environment
#   vpc_id             = module.workload_vpc.vpc_id
#   vpc_cidr           = var.workload_vpc_cidr
#   private_subnet_ids = module.workload_vpc.private_subnet_ids
# 
#   # EKS Configuration
#   eks_version       = var.eks_version
#   eks_public_access = var.eks_public_access
# 
#   # System Node Group
#   system_node_instance_types = var.system_node_instance_types
#   system_node_desired_size   = var.system_node_desired_size
#   system_node_min_size       = var.system_node_min_size
#   system_node_max_size       = var.system_node_max_size
# 
#   # Application Node Group
#   app_node_instance_types = var.app_node_instance_types
#   app_node_desired_size   = var.app_node_desired_size
#   app_node_min_size       = var.app_node_min_size
#   app_node_max_size       = var.app_node_max_size
#   app_node_capacity_type  = var.app_node_capacity_type
# 
#   # EKS Admin Access
#   eks_admin_role_arns = var.eks_admin_role_arns
# 
#   # Istio Version
#   istio_version = var.istio_version
# 
#   # External Resources
#   cms_assets_bucket_arn = module.cloudfront_waf.cms_assets_bucket_arn
#   kms_key_arn           = module.workload_vpc.kms_key_arn
# 
#   tags = local.common_tags
# }

#--------------------------------------------------------------------
# Security Module - Workload Account
#--------------------------------------------------------------------
module "security_workload" {
  source = "./modules/security"

  providers = {
    aws = aws.workload
  }

  project_name = var.project_name
  environment  = var.environment

  # Cross-account access
  cross_account_principals = var.cross_account_principals
  audit_principals         = var.audit_principals

  # Security Alerts
  security_alert_email = var.security_alert_email

  tags = local.common_tags
}

#====================================================================
# SHARED SERVICES ACCOUNT MODULES
#====================================================================

#--------------------------------------------------------------------
# Shared Services (Transfer Family, ECR, SES, SNS, Postgres)
#--------------------------------------------------------------------
module "shared_services" {
  source = "./modules/shared-services"

  providers = {
    aws = aws.shared_services
  }

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.shared_services_vpc_cidr
  transit_gateway_id = module.transit_gateway.transit_gateway_id

  # Cross-account Configuration
  networking_account_id = var.networking_account_id
  workload_account_id   = var.workload_account_id

  # ECR Configuration
  ecr_repositories = var.ecr_repositories

  # Postgres Configuration
  postgres_version               = var.postgres_version
  postgres_instance_class        = var.postgres_instance_class
  postgres_allocated_storage     = var.postgres_allocated_storage
  postgres_max_allocated_storage = var.postgres_max_allocated_storage

  # SES Configuration
  ses_domain = var.ses_domain

  tags = local.common_tags
}

#--------------------------------------------------------------------
# Security Module - Shared Services Account
#--------------------------------------------------------------------
module "security_shared" {
  source = "./modules/security"

  providers = {
    aws = aws.shared_services
  }

  project_name = var.project_name
  environment  = var.environment

  # Cross-account access
  cross_account_principals = var.cross_account_principals
  audit_principals         = var.audit_principals

  # Security Alerts
  security_alert_email = var.security_alert_email

  tags = local.common_tags
}

#====================================================================
# NETWORKING ACCOUNT SECURITY
#====================================================================

#--------------------------------------------------------------------
# Security Module - Networking Account
#--------------------------------------------------------------------
module "security_networking" {
  source = "./modules/security"

  providers = {
    aws = aws.networking
  }

  project_name = var.project_name
  environment  = var.environment

  # Cross-account access
  cross_account_principals = var.cross_account_principals
  audit_principals         = var.audit_principals

  # Security Alerts
  security_alert_email = var.security_alert_email

  tags = local.common_tags
}