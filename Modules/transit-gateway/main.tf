#==============================================================================
# TRANSIT GATEWAY MODULE - MAIN CONFIGURATION
# Central hub connecting all VPCs across Networking, Workload, and Shared Services accounts
# Region: eu-west-1 (Ireland)
#==============================================================================

#------------------------------------------------------------------------------
# TRANSIT GATEWAY
# Central routing hub for all VPC interconnectivity
#------------------------------------------------------------------------------
resource "aws_ec2_transit_gateway" "main" {
  description                     = "${var.project_name}-${var.environment}-tgw"
  amazon_side_asn                 = var.transit_gateway_asn
  auto_accept_shared_attachments  = "enable"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"
  multicast_support               = "disable"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw"
  })
}

#------------------------------------------------------------------------------
# TRANSIT GATEWAY ROUTE TABLES
# Separate route tables for different traffic patterns
#------------------------------------------------------------------------------

# Hub Route Table - For Hub VPC (Internet Gateway, NAT Gateway)
resource "aws_ec2_transit_gateway_route_table" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-rt-hub"
  })
}

# Inspection Route Table - For Network Firewall inspection
resource "aws_ec2_transit_gateway_route_table" "inspection" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-rt-inspection"
  })
}

# Spoke Route Table - For Workload, Ingress, Data VPCs
resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-rt-spoke"
  })
}

# Shared Services Route Table
resource "aws_ec2_transit_gateway_route_table" "shared_services" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-rt-shared-services"
  })
}

# Private Ingress Route Table - For Client VPN traffic
resource "aws_ec2_transit_gateway_route_table" "private_ingress" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-rt-private-ingress"
  })
}

#------------------------------------------------------------------------------
# TRANSIT GATEWAY VPC ATTACHMENTS - NETWORKING ACCOUNT
#------------------------------------------------------------------------------

# Hub VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "hub" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.hub_vpc_id
  subnet_ids         = var.hub_vpc_tgw_subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-attach-hub"
  })
}

# Private Ingress VPC Attachment (Client VPN)
resource "aws_ec2_transit_gateway_vpc_attachment" "private_ingress" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.private_ingress_vpc_id
  subnet_ids         = var.private_ingress_vpc_tgw_subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-attach-private-ingress"
  })
}

# Inspection VPC Attachment (Network Firewall)
resource "aws_ec2_transit_gateway_vpc_attachment" "inspection" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.inspection_vpc_id
  subnet_ids         = var.inspection_vpc_tgw_subnet_ids

  dns_support                                     = "enable"
  appliance_mode_support                          = "enable" # Required for Network Firewall
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-attach-inspection"
  })
}

#------------------------------------------------------------------------------
# TRANSIT GATEWAY VPC ATTACHMENTS - WORKLOAD ACCOUNT (Cross-Account)
#------------------------------------------------------------------------------

# Workload VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "workload" {
  provider = aws.workload

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.workload_vpc_id
  subnet_ids         = var.workload_vpc_tgw_subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-attach-workload"
  })

  depends_on = [aws_ram_principal_association.workload_account]
}

# Ingress VPC Attachment (NGINX/ECS Fargate)
resource "aws_ec2_transit_gateway_vpc_attachment" "ingress" {
  provider = aws.workload

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.ingress_vpc_id
  subnet_ids         = var.ingress_vpc_tgw_subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-attach-ingress"
  })

  depends_on = [aws_ram_principal_association.workload_account]
}

# Data VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "data" {
  provider = aws.workload

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.data_vpc_id
  subnet_ids         = var.data_vpc_tgw_subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-attach-data"
  })

  depends_on = [aws_ram_principal_association.workload_account]
}

#------------------------------------------------------------------------------
# TRANSIT GATEWAY VPC ATTACHMENTS - SHARED SERVICES ACCOUNT (Cross-Account)
#------------------------------------------------------------------------------

# Shared Services VPC Attachment
resource "aws_ec2_transit_gateway_vpc_attachment" "shared_services" {
  provider = aws.shared_services

  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id             = var.shared_services_vpc_id
  subnet_ids         = var.shared_services_vpc_tgw_subnet_ids

  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-attach-shared-services"
  })

  depends_on = [aws_ram_principal_association.shared_services_account]
}

#------------------------------------------------------------------------------
# TRANSIT GATEWAY VPN ATTACHMENTS - CONNECTIVITY PATTERNS
#------------------------------------------------------------------------------

# Site-to-Site VPN Customer Gateway (On-premises)
resource "aws_customer_gateway" "onprem" {
  bgp_asn    = var.onprem_bgp_asn
  ip_address = var.onprem_gateway_ip
  type       = "ipsec.1"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cgw-onprem"
  })
}

# Site-to-Site VPN Connection
resource "aws_vpn_connection" "onprem" {
  customer_gateway_id = aws_customer_gateway.onprem.id
  transit_gateway_id  = aws_ec2_transit_gateway.main.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_dh_group_numbers      = [20, 21]
  tunnel1_phase1_encryption_algorithms = ["AES256-GCM-16"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [20, 21]
  tunnel1_phase2_encryption_algorithms = ["AES256-GCM-16"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]

  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_dh_group_numbers      = [20, 21]
  tunnel2_phase1_encryption_algorithms = ["AES256-GCM-16"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [20, 21]
  tunnel2_phase2_encryption_algorithms = ["AES256-GCM-16"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpn-onprem"
  })
}

#------------------------------------------------------------------------------
# TRANSIT GATEWAY ROUTE TABLE ASSOCIATIONS
#------------------------------------------------------------------------------

# Hub VPC Association
resource "aws_ec2_transit_gateway_route_table_association" "hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# Private Ingress VPC Association
resource "aws_ec2_transit_gateway_route_table_association" "private_ingress" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.private_ingress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.private_ingress.id
}

# Inspection VPC Association
resource "aws_ec2_transit_gateway_route_table_association" "inspection" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
}

# Workload VPC Association
resource "aws_ec2_transit_gateway_route_table_association" "workload" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.workload.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# Ingress VPC Association
resource "aws_ec2_transit_gateway_route_table_association" "ingress" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ingress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# Data VPC Association
resource "aws_ec2_transit_gateway_route_table_association" "data" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.data.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# Shared Services VPC Association
resource "aws_ec2_transit_gateway_route_table_association" "shared_services" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_services.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services.id
}

# VPN Association
resource "aws_ec2_transit_gateway_route_table_association" "vpn" {
  transit_gateway_attachment_id  = aws_vpn_connection.onprem.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

#------------------------------------------------------------------------------
# TRANSIT GATEWAY ROUTE TABLE PROPAGATIONS
#------------------------------------------------------------------------------

# Propagate Hub VPC routes to all route tables
resource "aws_ec2_transit_gateway_route_table_propagation" "hub_to_spoke" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "hub_to_shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services.id
}

# Propagate Spoke VPC routes to Hub
resource "aws_ec2_transit_gateway_route_table_propagation" "workload_to_hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.workload.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "ingress_to_hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.ingress.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "data_to_hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.data.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# Propagate Shared Services routes
resource "aws_ec2_transit_gateway_route_table_propagation" "shared_to_spoke" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_services.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "shared_to_hub" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared_services.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# VPN propagations
resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_to_spoke" {
  transit_gateway_attachment_id  = aws_vpn_connection.onprem.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

#------------------------------------------------------------------------------
# TRANSIT GATEWAY STATIC ROUTES
#------------------------------------------------------------------------------

# Default route to Inspection VPC (Network Firewall) for spoke traffic
resource "aws_ec2_transit_gateway_route" "spoke_to_inspection" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# Route from Inspection to Hub for internet-bound traffic
resource "aws_ec2_transit_gateway_route" "inspection_to_hub" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.hub.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
}

# Route from Hub to Inspection for return traffic
resource "aws_ec2_transit_gateway_route" "hub_to_inspection_workload" {
  destination_cidr_block         = var.workload_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route" "hub_to_inspection_ingress" {
  destination_cidr_block         = var.ingress_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

resource "aws_ec2_transit_gateway_route" "hub_to_inspection_data" {
  destination_cidr_block         = var.data_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.hub.id
}

# Private Ingress routes to internal networks
resource "aws_ec2_transit_gateway_route" "private_ingress_to_workload" {
  destination_cidr_block         = var.workload_vpc_cidr
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inspection.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.private_ingress.id
}

#------------------------------------------------------------------------------
# AWS RESOURCE ACCESS MANAGER (RAM) - CROSS-ACCOUNT SHARING
#------------------------------------------------------------------------------

# RAM Resource Share for Transit Gateway
resource "aws_ram_resource_share" "transit_gateway" {
  name                      = "${var.project_name}-${var.environment}-tgw-share"
  allow_external_principals = false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-share"
  })
}

# Share Transit Gateway resource
resource "aws_ram_resource_association" "transit_gateway" {
  resource_arn       = aws_ec2_transit_gateway.main.arn
  resource_share_arn = aws_ram_resource_share.transit_gateway.arn
}

# Share with Workload Account
resource "aws_ram_principal_association" "workload_account" {
  principal          = var.workload_account_id
  resource_share_arn = aws_ram_resource_share.transit_gateway.arn
}

# Share with Shared Services Account
resource "aws_ram_principal_association" "shared_services_account" {
  principal          = var.shared_services_account_id
  resource_share_arn = aws_ram_resource_share.transit_gateway.arn
}

#------------------------------------------------------------------------------
# TRANSIT GATEWAY FLOW LOGS
#------------------------------------------------------------------------------

# CloudWatch Log Group for TGW Flow Logs
resource "aws_cloudwatch_log_group" "tgw_flow_logs" {
  name              = "/aws/tgw/${var.project_name}-${var.environment}-flow-logs"
  retention_in_days = var.flow_logs_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-flow-logs"
  })
}

# IAM Role for Flow Logs
resource "aws_iam_role" "tgw_flow_logs" {
  name = "${var.project_name}-${var.environment}-tgw-flow-logs-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy" "tgw_flow_logs" {
  name = "${var.project_name}-${var.environment}-tgw-flow-logs-policy"
  role = aws_iam_role.tgw_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.tgw_flow_logs.arn}:*"
      }
    ]
  })
}

#------------------------------------------------------------------------------
# TRANSIT GATEWAY PEERING (Optional - for multi-region)
#------------------------------------------------------------------------------

# Uncomment if multi-region peering is required
# resource "aws_ec2_transit_gateway_peering_attachment" "cross_region" {
#   peer_account_id         = var.networking_account_id
#   peer_region             = var.peer_region
#   peer_transit_gateway_id = var.peer_transit_gateway_id
#   transit_gateway_id      = aws_ec2_transit_gateway.main.id
#
#   tags = merge(var.tags, {
#     Name = "${var.project_name}-${var.environment}-tgw-peering"
#   })
# }
