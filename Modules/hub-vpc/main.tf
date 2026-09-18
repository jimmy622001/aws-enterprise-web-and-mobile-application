#=============================================================================
# HUB VPC MODULE
# modules/hub-vpc/main.tf
#
# Based on Architecture Diagram - Hub VPC in Networking Account
# Components: Internet Gateway, Inbound Resolver, VPC Endpoint, NAT Gateway
#             Core Security (Security Hub, Secrets Manager, KMS, Private CA)
#=============================================================================

#-----------------------------------------------------------------------------
# LOCAL VALUES
#-----------------------------------------------------------------------------
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # Hub VPC has connectivity to all other VPCs via Transit Gateway
  hub_vpc_tags = merge(var.tags, {
    VPC     = "hub"
    Account = "networking"
    Purpose = "Central connectivity and security services"
  })
}

#-----------------------------------------------------------------------------
# HUB VPC
#-----------------------------------------------------------------------------
resource "aws_vpc" "hub" {
  cidr_block           = var.hub_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-vpc"
  })
}

#-----------------------------------------------------------------------------
# INTERNET GATEWAY
# Provides internet connectivity for the Hub VPC
#-----------------------------------------------------------------------------
resource "aws_internet_gateway" "hub" {
  vpc_id = aws_vpc.hub.id

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-igw"
  })
}

#-----------------------------------------------------------------------------
# SUBNETS - Public, Private, and TGW Attachment
#-----------------------------------------------------------------------------

# Public Subnets (for NAT Gateways and Internet-facing resources)
resource "aws_subnet" "hub_public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.hub.id
  cidr_block              = cidrsubnet(var.hub_vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-public-${var.availability_zones[count.index]}"
    Tier = "public"
  })
}

# Private Subnets (for VPC Endpoints, Resolvers, Security Services)
resource "aws_subnet" "hub_private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.hub.id
  cidr_block        = cidrsubnet(var.hub_vpc_cidr, 4, count.index + 4)
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-private-${var.availability_zones[count.index]}"
    Tier = "private"
  })
}

# Transit Gateway Attachment Subnets
resource "aws_subnet" "hub_tgw" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.hub.id
  cidr_block        = cidrsubnet(var.hub_vpc_cidr, 6, count.index + 48)
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-tgw-${var.availability_zones[count.index]}"
    Tier = "tgw-attachment"
  })
}

#-----------------------------------------------------------------------------
# NAT GATEWAYS
# One per AZ for high availability
#-----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-nat-eip-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.hub]
}

resource "aws_nat_gateway" "hub" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.hub_public[count.index].id

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-nat-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.hub]
}

#-----------------------------------------------------------------------------
# ROUTE TABLES
#-----------------------------------------------------------------------------

# Public Route Table
resource "aws_route_table" "hub_public" {
  vpc_id = aws_vpc.hub.id

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-public-rt"
  })
}

resource "aws_route" "hub_public_internet" {
  route_table_id         = aws_route_table.hub_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.hub.id
}

resource "aws_route_table_association" "hub_public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.hub_public[count.index].id
  route_table_id = aws_route_table.hub_public.id
}

# Private Route Tables (one per AZ for NAT Gateway routing)
resource "aws_route_table" "hub_private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.hub.id

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-private-rt-${var.availability_zones[count.index]}"
  })
}

resource "aws_route" "hub_private_nat" {
  count                  = length(var.availability_zones)
  route_table_id         = aws_route_table.hub_private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.hub[count.index].id
}

resource "aws_route_table_association" "hub_private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.hub_private[count.index].id
  route_table_id = aws_route_table.hub_private[count.index].id
}

# TGW Route Table
resource "aws_route_table" "hub_tgw" {
  vpc_id = aws_vpc.hub.id

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-tgw-rt"
  })
}

resource "aws_route_table_association" "hub_tgw" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.hub_tgw[count.index].id
  route_table_id = aws_route_table.hub_tgw.id
}

#-----------------------------------------------------------------------------
# ROUTE 53 INBOUND RESOLVER
# Allows on-premises DNS queries to resolve AWS private hosted zones
#-----------------------------------------------------------------------------
resource "aws_security_group" "inbound_resolver" {
  name        = "${local.name_prefix}-inbound-resolver-sg"
  description = "Security group for Route 53 Inbound Resolver"
  vpc_id      = aws_vpc.hub.id

  ingress {
    description = "DNS TCP from internal networks"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = var.internal_cidr_blocks
  }

  ingress {
    description = "DNS UDP from internal networks"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = var.internal_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-inbound-resolver-sg"
  })
}

resource "aws_route53_resolver_endpoint" "inbound" {
  name               = "${local.name_prefix}-inbound-resolver"
  direction          = "INBOUND"
  security_group_ids = [aws_security_group.inbound_resolver.id]

  dynamic "ip_address" {
    for_each = aws_subnet.hub_private
    content {
      subnet_id = ip_address.value.id
    }
  }

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-inbound-resolver"
  })
}

#-----------------------------------------------------------------------------
# ROUTE 53 OUTBOUND RESOLVER
# Allows AWS to forward DNS queries to on-premises DNS servers
#-----------------------------------------------------------------------------
resource "aws_route53_resolver_endpoint" "outbound" {
  name               = "${local.name_prefix}-outbound-resolver"
  direction          = "OUTBOUND"
  security_group_ids = [aws_security_group.inbound_resolver.id]

  dynamic "ip_address" {
    for_each = aws_subnet.hub_private
    content {
      subnet_id = ip_address.value.id
    }
  }

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-outbound-resolver"
  })
}

#-----------------------------------------------------------------------------
# VPC ENDPOINTS
# Centralized VPC Endpoints for AWS services
#-----------------------------------------------------------------------------

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${local.name_prefix}-hub-vpce-sg"
  description = "Security group for Hub VPC Endpoints"
  vpc_id      = aws_vpc.hub.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.hub_vpc_cidr]
  }

  ingress {
    description = "HTTPS from internal networks"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.internal_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-vpce-sg"
  })
}

# Data source for S3 prefix list
data "aws_prefix_list" "s3" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${var.aws_region}.s3"]
  }
}

# S3 Gateway Endpoint with Policy
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.hub.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [aws_route_table.hub_public.id],
    aws_route_table.hub_private[*].id
  )

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Access"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "arn:aws:s3:::*"
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = var.networking_account_id
          }
        }
      }
    ]
  })

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-s3-endpoint"
  })
}

# DynamoDB Gateway Endpoint with Policy
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.hub.id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids = concat(
    [aws_route_table.hub_public.id],
    aws_route_table.hub_private[*].id
  )

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowDynamoDBAccess"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.aws_region}:${var.networking_account_id}:table/*"
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = var.networking_account_id
          }
        }
      }
    ]
  })

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-dynamodb-endpoint"
  })
}

# Interface Endpoints for Core Services
locals {
  interface_endpoints = [
    "ec2",
    "ec2messages",
    "ssm",
    "ssmmessages",
    "logs",
    "monitoring",
    "kms",
    "secretsmanager",
    "sts",
    "elasticloadbalancing",
    "autoscaling",
    "ecr.api",
    "ecr.dkr"
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id              = aws_vpc.hub.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.hub_private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAll"
        Effect    = "Allow"
        Principal = "*"
        Action    = "*"
        Resource  = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = [
              var.networking_account_id,
              var.workload_account_id,
              var.shared_services_account_id
            ]
          }
        }
      }
    ]
  })

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-${each.value}-endpoint"
  })
}

#-----------------------------------------------------------------------------
# CORE SECURITY - KMS
# Customer Managed Keys for encryption
#-----------------------------------------------------------------------------
resource "aws_kms_key" "hub_main" {
  description             = "Hub VPC main encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.networking_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Cross-Account Access"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.workload_account_id}:root",
            "arn:aws:iam::${var.shared_services_account_id}:root"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow AWS Services"
        Effect = "Allow"
        Principal = {
          Service = [
            "logs.${var.aws_region}.amazonaws.com",
            "secretsmanager.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-main-kms"
  })
}

resource "aws_kms_alias" "hub_main" {
  name          = "alias/${local.name_prefix}-hub-main"
  target_key_id = aws_kms_key.hub_main.key_id
}

#-----------------------------------------------------------------------------
# CORE SECURITY - SECRETS MANAGER
# Centralized secrets management
#-----------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "hub_credentials" {
  name                    = "${local.name_prefix}/hub/credentials"
  description             = "Hub VPC service credentials"
  kms_key_id              = aws_kms_key.hub_main.arn
  recovery_window_in_days = 30

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-credentials"
  })
}

# Resource policy for cross-account access
resource "aws_secretsmanager_secret_policy" "hub_credentials" {
  secret_arn = aws_secretsmanager_secret.hub_credentials.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.workload_account_id}:root",
            "arn:aws:iam::${var.shared_services_account_id}:root"
          ]
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

#-----------------------------------------------------------------------------
# CORE SECURITY - AWS PRIVATE CA
# Private Certificate Authority for internal TLS
#-----------------------------------------------------------------------------
resource "aws_acmpca_certificate_authority" "hub" {
  type = "ROOT"

  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name         = "${var.project_name}.internal"
      country             = "GB"
      organization        = var.organization_name
      organizational_unit = "Infrastructure"
      state               = "England"
      locality            = "London"
    }
  }

  revocation_configuration {
    crl_configuration {
      enabled            = true
      expiration_in_days = 7
      s3_bucket_name     = aws_s3_bucket.pca_crl.id
      s3_object_acl      = "BUCKET_OWNER_FULL_CONTROL"
    }
  }

  permanent_deletion_time_in_days = 30

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-private-ca"
  })
}

# S3 bucket for CRL distribution
resource "aws_s3_bucket" "pca_crl" {
  bucket = "${local.name_prefix}-hub-pca-crl-${var.networking_account_id}"

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-pca-crl"
  })
}

resource "aws_s3_bucket_versioning" "pca_crl" {
  bucket = aws_s3_bucket.pca_crl.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pca_crl" {
  bucket = aws_s3_bucket.pca_crl.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.hub_main.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "pca_crl" {
  bucket = aws_s3_bucket.pca_crl.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "pca_crl" {
  bucket = aws_s3_bucket.pca_crl.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowACMPCAAccess"
        Effect = "Allow"
        Principal = {
          Service = "acm-pca.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.pca_crl.arn,
          "${aws_s3_bucket.pca_crl.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.networking_account_id
          }
        }
      }
    ]
  })
}

#-----------------------------------------------------------------------------
# CORE SECURITY - SECURITY HUB
# Centralized security findings and compliance
#-----------------------------------------------------------------------------
resource "aws_securityhub_account" "hub" {}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  depends_on    = [aws_securityhub_account.hub]
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.hub]
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.4.0"
}

resource "aws_securityhub_standards_subscription" "pci_dss" {
  depends_on    = [aws_securityhub_account.hub]
  standards_arn = "arn:aws:securityhub:${var.aws_region}::standards/pci-dss/v/3.2.1"
}

#-----------------------------------------------------------------------------
# VPC FLOW LOGS
#-----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "hub_flow_logs" {
  name              = "/aws/vpc/${local.name_prefix}-hub-flow-logs"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.hub_main.arn

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-flow-logs"
  })
}

resource "aws_iam_role" "hub_flow_logs" {
  name = "${local.name_prefix}-hub-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.hub_vpc_tags
}

resource "aws_iam_role_policy" "hub_flow_logs" {
  name = "${local.name_prefix}-hub-flow-logs-policy"
  role = aws_iam_role.hub_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "hub" {
  vpc_id                   = aws_vpc.hub.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.hub_flow_logs.arn
  iam_role_arn             = aws_iam_role.hub_flow_logs.arn
  max_aggregation_interval = 60

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-flow-log"
  })
}

#-----------------------------------------------------------------------------
# NETWORK ACLs
#-----------------------------------------------------------------------------
resource "aws_network_acl" "hub_private" {
  vpc_id     = aws_vpc.hub.id
  subnet_ids = aws_subnet.hub_private[*].id

  # Allow HTTPS from internal networks
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 443
    to_port    = 443
  }
  
  # Allow DNS from internal networks
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 53
    to_port    = 53
  }
  
  ingress {
    protocol   = "udp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 53
    to_port    = 53
  }
  
  # Allow inbound ephemeral ports from internal networks only
  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow HTTPS outbound
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  
  # Allow DNS outbound
  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }
  
  egress {
    protocol   = "udp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 53
    to_port    = 53
  }
  
  # Allow ephemeral ports for responses
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.hub_vpc_tags, {
    Name = "${local.name_prefix}-hub-private-nacl"
  })
}
