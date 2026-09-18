#===============================================================================
# PRIVATE INGRESS VPC MODULE
# Purpose: Client VPN access with Okta SAML authentication
# Location: modules/private-ingress-vpc/main.tf
#===============================================================================

#-------------------------------------------------------------------------------
# VPC CONFIGURATION
#-------------------------------------------------------------------------------
resource "aws_vpc" "private_ingress" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-ingress-vpc"
  })
}

#-------------------------------------------------------------------------------
# SUBNETS - Client VPN Target Subnets (3 AZs)
#-------------------------------------------------------------------------------
resource "aws_subnet" "client_vpn" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.private_ingress.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-client-vpn-subnet-${count.index + 1}"
    Type = "client-vpn"
  })
}

#-------------------------------------------------------------------------------
# SUBNETS - VPC Endpoint Subnets (3 AZs)
#-------------------------------------------------------------------------------
resource "aws_subnet" "vpc_endpoints" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.private_ingress.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 3)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpce-subnet-${count.index + 1}"
    Type = "vpc-endpoint"
  })
}

#-------------------------------------------------------------------------------
# SUBNETS - Transit Gateway Attachment Subnets (3 AZs)
#-------------------------------------------------------------------------------
resource "aws_subnet" "tgw_attachment" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.private_ingress.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 6)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-attachment-subnet-${count.index + 1}"
    Type = "tgw-attachment"
  })
}

#-------------------------------------------------------------------------------
# ROUTE TABLES
#-------------------------------------------------------------------------------
resource "aws_route_table" "client_vpn" {
  vpc_id = aws_vpc.private_ingress.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-client-vpn-rt"
  })
}

resource "aws_route_table" "vpc_endpoints" {
  vpc_id = aws_vpc.private_ingress.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpce-rt"
  })
}

resource "aws_route_table" "tgw_attachment" {
  vpc_id = aws_vpc.private_ingress.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-attachment-rt"
  })
}

#-------------------------------------------------------------------------------
# ROUTE TABLE ASSOCIATIONS
#-------------------------------------------------------------------------------
resource "aws_route_table_association" "client_vpn" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.client_vpn[count.index].id
  route_table_id = aws_route_table.client_vpn.id
}

resource "aws_route_table_association" "vpc_endpoints" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.vpc_endpoints[count.index].id
  route_table_id = aws_route_table.vpc_endpoints.id
}

resource "aws_route_table_association" "tgw_attachment" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.tgw_attachment[count.index].id
  route_table_id = aws_route_table.tgw_attachment.id
}

#-------------------------------------------------------------------------------
# ROUTES TO TRANSIT GATEWAY
#-------------------------------------------------------------------------------
resource "aws_route" "client_vpn_to_tgw" {
  route_table_id         = aws_route_table.client_vpn.id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route" "vpce_to_tgw" {
  route_table_id         = aws_route_table.vpc_endpoints.id
  destination_cidr_block = "10.0.0.0/8"
  transit_gateway_id     = var.transit_gateway_id
}

#-------------------------------------------------------------------------------
# OKTA SAML IDENTITY PROVIDER
#-------------------------------------------------------------------------------
# COMMENTED OUT FOR POC - Requires Okta SAML metadata
# Uncomment and configure when Okta integration is ready
#
# resource "aws_iam_saml_provider" "okta" {
#   name                   = "${var.project_name}-${var.environment}-okta-saml-provider"
#   saml_metadata_document = var.okta_saml_metadata
#
#   tags = merge(var.tags, {
#     Name = "${var.project_name}-${var.environment}-okta-saml-provider"
#   })
# }
#
# #-------------------------------------------------------------------------------
# # ACM CERTIFICATES FOR CLIENT VPN
# #-------------------------------------------------------------------------------
# # Server Certificate
# resource "aws_acm_certificate" "client_vpn_server" {
#   private_key       = var.server_private_key
#   certificate_body  = var.server_certificate_body
#   certificate_chain = var.server_certificate_chain
#
#   tags = merge(var.tags, {
#     Name = "${var.project_name}-${var.environment}-client-vpn-server-cert"
#   })
#
#   lifecycle {
#     create_before_destroy = true
#   }
# }
#
# #-------------------------------------------------------------------------------
# # CLIENT VPN ENDPOINT - Okta SAML Authentication
# #-------------------------------------------------------------------------------
# resource "aws_ec2_client_vpn_endpoint" "main" {
#   description            = "${var.project_name}-${var.environment}-client-vpn"
#   server_certificate_arn = aws_acm_certificate.client_vpn_server.arn
#   client_cidr_block      = var.client_vpn_cidr
#   split_tunnel           = var.split_tunnel_enabled
#   dns_servers            = var.dns_servers
#   transport_protocol     = "udp"
#   vpn_port               = 443
#   session_timeout_hours  = var.session_timeout_hours
#   self_service_portal    = "enabled"
#
#   # Okta SAML Authentication
#   authentication_options {
#     type                           = "federated-authentication"
#     saml_provider_arn              = aws_iam_saml_provider.okta.arn
#     self_service_saml_provider_arn = aws_iam_saml_provider.okta.arn
#   }
#
#   # Connection Logging
#   connection_log_options {
#     enabled               = true
#     cloudwatch_log_group  = aws_cloudwatch_log_group.client_vpn.name
#     cloudwatch_log_stream = aws_cloudwatch_log_stream.client_vpn.name
#   }
#
#   # Security Group
#   security_group_ids = [aws_security_group.client_vpn_endpoint.id]
#   vpc_id             = aws_vpc.private_ingress.id
#
#   tags = merge(var.tags, {
#     Name = "${var.project_name}-${var.environment}-client-vpn"
#   })
# }
#
# #-------------------------------------------------------------------------------
# # CLIENT VPN NETWORK ASSOCIATIONS (3 AZs)
# #-------------------------------------------------------------------------------
# resource "aws_ec2_client_vpn_network_association" "main" {
#   count                  = length(var.availability_zones)
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
#   subnet_id              = aws_subnet.client_vpn[count.index].id
# }
#
# #-------------------------------------------------------------------------------
# # CLIENT VPN AUTHORIZATION RULES
# #-------------------------------------------------------------------------------
# # Allow access to all internal networks
# resource "aws_ec2_client_vpn_authorization_rule" "all_internal" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
#   target_network_cidr    = "10.0.0.0/8"
#   authorize_all_groups   = true
#   description            = "Allow access to all internal networks"
# }
#
# # Allow access to Private Ingress VPC
# resource "aws_ec2_client_vpn_authorization_rule" "vpc" {
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
#   target_network_cidr    = var.vpc_cidr
#   authorize_all_groups   = true
#   description            = "Allow access to Private Ingress VPC"
# }
#
# #-------------------------------------------------------------------------------
# # CLIENT VPN ROUTES
# #-------------------------------------------------------------------------------
# resource "aws_ec2_client_vpn_route" "to_tgw" {
#   count                  = length(var.availability_zones)
#   client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
#   destination_cidr_block = "10.0.0.0/8"
#   target_vpc_subnet_id   = aws_subnet.client_vpn[count.index].id
#   description            = "Route to internal networks via TGW"
#
#   depends_on = [aws_ec2_client_vpn_network_association.main]
# }

#-------------------------------------------------------------------------------
# SECURITY GROUP - Client VPN Endpoint
#-------------------------------------------------------------------------------
# COMMENTED OUT FOR POC - Only needed when Client VPN is enabled
#
# resource "aws_security_group" "client_vpn_endpoint" {
#   name        = "${var.project_name}-${var.environment}-client-vpn-endpoint-sg"
#   description = "Security group for Client VPN endpoint"
#   vpc_id      = aws_vpc.private_ingress.id
#
#   # Allow inbound from VPN clients
#   ingress {
#     description = "Allow all traffic from VPN clients"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = [var.client_vpn_cidr]
#   }
#
#   # Allow all outbound
#   egress {
#     description = "Allow all outbound traffic"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = merge(var.tags, {
#     Name = "${var.project_name}-${var.environment}-client-vpn-endpoint-sg"
#   })
# }

#-------------------------------------------------------------------------------
# SECURITY GROUP - VPC Endpoints
#-------------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-${var.environment}-vpce-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.private_ingress.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, var.client_vpn_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpce-sg"
  })
}

#-------------------------------------------------------------------------------
# VPC ENDPOINTS - Interface Endpoints
#-------------------------------------------------------------------------------
# SSM Endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.private_ingress.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.vpc_endpoints[*].id
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
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ssm-endpoint"
  })
}

# SSM Messages Endpoint
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.private_ingress.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.vpc_endpoints[*].id
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
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ssmmessages-endpoint"
  })
}

# EC2 Messages Endpoint
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.private_ingress.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.vpc_endpoints[*].id
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
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ec2messages-endpoint"
  })
}

# CloudWatch Logs Endpoint
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.private_ingress.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.vpc_endpoints[*].id
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
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-logs-endpoint"
  })
}

# STS Endpoint
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.private_ingress.id
  service_name        = "com.amazonaws.${var.aws_region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.vpc_endpoints[*].id
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
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-sts-endpoint"
  })
}

# KMS Endpoint
resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.private_ingress.id
  service_name        = "com.amazonaws.${var.aws_region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.vpc_endpoints[*].id
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
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-kms-endpoint"
  })
}

#-------------------------------------------------------------------------------
# CLOUDWATCH LOG GROUP - Client VPN Connection Logs
#-------------------------------------------------------------------------------
# COMMENTED OUT FOR POC - Only needed when Client VPN is enabled
#
# resource "aws_cloudwatch_log_group" "client_vpn" {
#   name              = "/aws/client-vpn/${var.project_name}-${var.environment}"
#   retention_in_days = var.log_retention_days
#   kms_key_id        = aws_kms_key.client_vpn_logs.arn
#
#   tags = merge(var.tags, {
#     Name = "${var.project_name}-${var.environment}-client-vpn-logs"
#   })
# }
#
# resource "aws_cloudwatch_log_stream" "client_vpn" {
#   name           = "connection-logs"
#   log_group_name = aws_cloudwatch_log_group.client_vpn.name
# }
#
# #-------------------------------------------------------------------------------
# # KMS KEY - Client VPN Logs Encryption
# #-------------------------------------------------------------------------------
# resource "aws_kms_key" "client_vpn_logs" {
#   description             = "KMS key for Client VPN logs encryption"
#   deletion_window_in_days = 30
#   enable_key_rotation     = true
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "Enable IAM User Permissions"
#         Effect = "Allow"
#         Principal = {
#           AWS = "arn:aws:iam::${var.networking_account_id}:root"
#         }
#         Action   = "kms:*"
#         Resource = "*"
#       },
#       {
#         Sid    = "Allow CloudWatch Logs"
#         Effect = "Allow"
#         Principal = {
#           Service = "logs.${var.aws_region}.amazonaws.com"
#         }
#         Action = [
#           "kms:Encrypt*",
#           "kms:Decrypt*",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:Describe*"
#         ]
#         Resource = "*"
#         Condition = {
#           ArnLike = {
#             "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${var.networking_account_id}:*"
#           }
#         }
#       }
#     ]
#   })
#
#   tags = merge(var.tags, {
#     Name = "${var.project_name}-${var.environment}-client-vpn-logs-kms"
#   })
# }
#
# resource "aws_kms_alias" "client_vpn_logs" {
#   name          = "alias/${var.project_name}-${var.environment}-client-vpn-logs"
#   target_key_id = aws_kms_key.client_vpn_logs.key_id
# }

#-------------------------------------------------------------------------------
# VPC FLOW LOGS
#-------------------------------------------------------------------------------
resource "aws_flow_log" "private_ingress" {
  vpc_id                   = aws_vpc.private_ingress.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn             = aws_iam_role.vpc_flow_logs.arn
  max_aggregation_interval = 60

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-ingress-flow-logs"
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project_name}-${var.environment}-private-ingress"
  retention_in_days = var.log_retention_days
  # KMS encryption removed for POC - Can be added back later
  # kms_key_id        = aws_kms_key.vpc_flow_logs.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-ingress-flow-logs"
  })
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-private-ingress-flow-logs-role"

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

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-ingress-flow-logs-role"
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-private-ingress-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

#-------------------------------------------------------------------------------
# NETWORK ACLS
#-------------------------------------------------------------------------------
resource "aws_network_acl" "client_vpn" {
  vpc_id     = aws_vpc.private_ingress.id
  subnet_ids = aws_subnet.client_vpn[*].id

  # Allow inbound from VPN CIDR
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.client_vpn_cidr
    from_port  = 0
    to_port    = 0
  }

  # Allow inbound from internal networks
  ingress {
    protocol   = -1
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 0
    to_port    = 0
  }

  # Allow all outbound
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-client-vpn-nacl"
  })
}
