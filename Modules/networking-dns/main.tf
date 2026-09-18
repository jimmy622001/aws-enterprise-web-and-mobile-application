#------------------------------------------------------------------------------
# NETWORKING DNS MODULE
# Purpose: Route 53, Public/Private Hosted Zones, DNS Firewall
# Location: modules/networking-dns/main.tf
#------------------------------------------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

#------------------------------------------------------------------------------
# VARIABLES
#------------------------------------------------------------------------------

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "public_domain_name" {
  description = "Public domain name for Route 53 hosted zone"
  type        = string
}

variable "private_domain_name" {
  description = "Private domain name for Route 53 hosted zone"
  type        = string
}

variable "vpc_ids_for_private_zone" {
  description = "List of VPC IDs to associate with private hosted zone"
  type        = list(string)
  default     = []
}

variable "dns_firewall_enabled" {
  description = "Enable DNS Firewall"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

#------------------------------------------------------------------------------
# ROUTE 53 - PUBLIC HOSTED ZONE
# Purpose: DNS resolution for public-facing services (CloudFront, ALB, etc.)
#------------------------------------------------------------------------------

resource "aws_route53_zone" "public" {
  name    = var.public_domain_name
  comment = "${var.project_name} public hosted zone - ${var.environment}"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-public-zone"
    Environment = var.environment
    Type        = "public"
  })
}

#------------------------------------------------------------------------------
# ROUTE 53 - PRIVATE HOSTED ZONE
# Purpose: Internal DNS resolution for private resources across VPCs
#------------------------------------------------------------------------------

resource "aws_route53_zone" "private" {
  name    = var.private_domain_name
  comment = "${var.project_name} private hosted zone - ${var.environment}"

  # Associate with Hub VPC initially - more VPCs added via association resources
  dynamic "vpc" {
    for_each = length(var.vpc_ids_for_private_zone) > 0 ? [var.vpc_ids_for_private_zone[0]] : []
    content {
      vpc_id = vpc.value
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-private-zone"
    Environment = var.environment
    Type        = "private"
  })

  lifecycle {
    ignore_changes = [vpc]
  }
}

# Additional VPC associations for private hosted zone
resource "aws_route53_zone_association" "private_vpc_associations" {
  count   = length(var.vpc_ids_for_private_zone) > 1 ? length(var.vpc_ids_for_private_zone) - 1 : 0
  zone_id = aws_route53_zone.private.zone_id
  vpc_id  = var.vpc_ids_for_private_zone[count.index + 1]
}

#------------------------------------------------------------------------------
# DNS FIREWALL - DOMAIN LISTS
# Purpose: Define allowed and blocked domains for DNS filtering
#------------------------------------------------------------------------------

# AWS Managed Domain List - Malware Domains
resource "aws_route53_resolver_firewall_domain_list" "aws_malware" {
  count = var.dns_firewall_enabled ? 1 : 0
  name  = "${var.project_name}-aws-malware-domains"

  tags = merge(var.tags, {
    Name = "${var.project_name}-aws-malware-domains"
  })
}

# AWS Managed Domain List - Botnet Domains
resource "aws_route53_resolver_firewall_domain_list" "aws_botnet" {
  count = var.dns_firewall_enabled ? 1 : 0
  name  = "${var.project_name}-aws-botnet-domains"

  tags = merge(var.tags, {
    Name = "${var.project_name}-aws-botnet-domains"
  })
}

# Custom Blocked Domains List
resource "aws_route53_resolver_firewall_domain_list" "blocked_domains" {
  count = var.dns_firewall_enabled ? 1 : 0
  name  = "${var.project_name}-blocked-domains"
  domains = [
    "*.malware.com",
    "*.phishing.net",
    "*.cryptomining.org"
  ]

  tags = merge(var.tags, {
    Name = "${var.project_name}-blocked-domains"
  })
}

# Custom Allowed Domains List (for override scenarios)
resource "aws_route53_resolver_firewall_domain_list" "allowed_domains" {
  count = var.dns_firewall_enabled ? 1 : 0
  name  = "${var.project_name}-allowed-domains"
  domains = [
    "*.amazonaws.com",
    "*.aws.amazon.com",
    var.public_domain_name,
    "*.${var.public_domain_name}"
  ]

  tags = merge(var.tags, {
    Name = "${var.project_name}-allowed-domains"
  })
}

#------------------------------------------------------------------------------
# DNS FIREWALL - RULE GROUP
# Purpose: Define firewall rules for DNS query filtering
#------------------------------------------------------------------------------

resource "aws_route53_resolver_firewall_rule_group" "main" {
  count = var.dns_firewall_enabled ? 1 : 0
  name  = "${var.project_name}-dns-firewall-rule-group"

  tags = merge(var.tags, {
    Name = "${var.project_name}-dns-firewall-rule-group"
  })
}

# Rule 1: Allow trusted domains (highest priority)
resource "aws_route53_resolver_firewall_rule" "allow_trusted" {
  count                   = var.dns_firewall_enabled ? 1 : 0
  name                    = "allow-trusted-domains"
  action                  = "ALLOW"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.allowed_domains[0].id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.main[0].id
  priority                = 100
}

# Rule 2: Block malware domains
resource "aws_route53_resolver_firewall_rule" "block_malware" {
  count                   = var.dns_firewall_enabled ? 1 : 0
  name                    = "block-malware-domains"
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.aws_malware[0].id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.main[0].id
  priority                = 200
}

# Rule 3: Block botnet domains
resource "aws_route53_resolver_firewall_rule" "block_botnet" {
  count                   = var.dns_firewall_enabled ? 1 : 0
  name                    = "block-botnet-domains"
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.aws_botnet[0].id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.main[0].id
  priority                = 300
}

# Rule 4: Block custom blocked domains
resource "aws_route53_resolver_firewall_rule" "block_custom" {
  count                   = var.dns_firewall_enabled ? 1 : 0
  name                    = "block-custom-domains"
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.blocked_domains[0].id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.main[0].id
  priority                = 400
}

#------------------------------------------------------------------------------
# DNS FIREWALL - VPC ASSOCIATIONS
# Purpose: Associate DNS Firewall rule group with VPCs
#------------------------------------------------------------------------------

resource "aws_route53_resolver_firewall_rule_group_association" "vpc_associations" {
  count                  = var.dns_firewall_enabled ? length(var.vpc_ids_for_private_zone) : 0
  name                   = "${var.project_name}-dns-fw-assoc-${count.index}"
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.main[0].id
  priority               = 101
  vpc_id                 = var.vpc_ids_for_private_zone[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-dns-fw-assoc-${count.index}"
  })
}

#------------------------------------------------------------------------------
# DNS QUERY LOGGING
# Purpose: Log DNS queries for security analysis and compliance
#------------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "dns_query_logs" {
  name              = "/aws/route53/${var.project_name}-dns-query-logs"
  retention_in_days = 90

  tags = merge(var.tags, {
    Name = "${var.project_name}-dns-query-logs"
  })
}

resource "aws_route53_resolver_query_log_config" "main" {
  name            = "${var.project_name}-dns-query-log-config"
  destination_arn = aws_cloudwatch_log_group.dns_query_logs.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-dns-query-log-config"
  })
}

resource "aws_route53_resolver_query_log_config_association" "vpc_associations" {
  count                        = length(var.vpc_ids_for_private_zone)
  resolver_query_log_config_id = aws_route53_resolver_query_log_config.main.id
  resource_id                  = var.vpc_ids_for_private_zone[count.index]
}

#------------------------------------------------------------------------------
# DNSSEC FOR PUBLIC ZONE
# Purpose: Enable DNSSEC signing for the public hosted zone
#------------------------------------------------------------------------------

resource "aws_kms_key" "dnssec" {
  customer_master_key_spec = "ECC_NIST_P256"
  deletion_window_in_days  = 7
  key_usage                = "SIGN_VERIFY"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Route 53 DNSSEC Service"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action = [
          "kms:DescribeKey",
          "kms:GetPublicKey",
          "kms:Sign"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:route53:::hostedzone/*"
          }
        }
      },
      {
        Sid    = "Allow Route 53 DNSSEC to CreateGrant"
        Effect = "Allow"
        Principal = {
          Service = "dnssec-route53.amazonaws.com"
        }
        Action   = "kms:CreateGrant"
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-dnssec-kms-key"
  })
}

resource "aws_kms_alias" "dnssec" {
  name          = "alias/${var.project_name}-dnssec"
  target_key_id = aws_kms_key.dnssec.key_id
}

resource "aws_route53_key_signing_key" "main" {
  hosted_zone_id             = aws_route53_zone.public.id
  key_management_service_arn = aws_kms_key.dnssec.arn
  name                       = "${var.project_name}-ksk"
}

resource "aws_route53_hosted_zone_dnssec" "main" {
  depends_on     = [aws_route53_key_signing_key.main]
  hosted_zone_id = aws_route53_zone.public.id
}

#------------------------------------------------------------------------------
# DATA SOURCES
#------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#------------------------------------------------------------------------------
# OUTPUTS
#------------------------------------------------------------------------------

output "public_zone_id" {
  description = "ID of the public hosted zone"
  value       = aws_route53_zone.public.zone_id
}

output "public_zone_name_servers" {
  description = "Name servers for the public hosted zone"
  value       = aws_route53_zone.public.name_servers
}

output "private_zone_id" {
  description = "ID of the private hosted zone"
  value       = aws_route53_zone.private.zone_id
}

output "dns_firewall_rule_group_id" {
  description = "ID of the DNS Firewall rule group"
  value       = var.dns_firewall_enabled ? aws_route53_resolver_firewall_rule_group.main[0].id : null
}

output "dns_query_log_config_id" {
  description = "ID of the DNS query log configuration"
  value       = aws_route53_resolver_query_log_config.main.id
}

output "dnssec_kms_key_arn" {
  description = "ARN of the KMS key used for DNSSEC"
  value       = aws_kms_key.dnssec.arn
}

output "public_domain_name" {
  description = "Public domain name"
  value       = var.public_domain_name
}

output "private_domain_name" {
  description = "Private domain name"
  value       = var.private_domain_name
}
