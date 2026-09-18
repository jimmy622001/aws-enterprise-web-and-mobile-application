#===============================================================================
# INSPECTION VPC MODULE - MAIN CONFIGURATION
# AWS Network Firewall with 3 AZ deployment (FW AZ-1, FW AZ-2, FW AZ-3)
# As shown in the architecture diagram - Networking Account
#===============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#===============================================================================
# DATA SOURCES
#===============================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

#===============================================================================
# INSPECTION VPC
#===============================================================================

resource "aws_vpc" "inspection" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-inspection-vpc"
  })
}

#===============================================================================
# INTERNET GATEWAY (for NAT Gateway outbound traffic)
#===============================================================================

resource "aws_internet_gateway" "inspection" {
  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-inspection-igw"
  })
}

#===============================================================================
# SUBNETS - Firewall Subnets (FW AZ-1, FW AZ-2, FW AZ-3)
#===============================================================================

resource "aws_subnet" "firewall" {
  count             = 3
  vpc_id            = aws_vpc.inspection.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-fw-az-${count.index + 1}"
    Type = "firewall"
  })
}

#===============================================================================
# SUBNETS - TGW Attachment Subnets
#===============================================================================

resource "aws_subnet" "tgw_attachment" {
  count             = 3
  vpc_id            = aws_vpc.inspection.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-inspection-tgw-${count.index + 1}"
    Type = "tgw-attachment"
  })
}

#===============================================================================
# SUBNETS - NAT Gateway Subnets (Public)
#===============================================================================

resource "aws_subnet" "nat_gateway" {
  count                   = 3
  vpc_id                  = aws_vpc.inspection.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 6)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-inspection-nat-${count.index + 1}"
    Type = "public"
  })
}

#===============================================================================
# ELASTIC IPs FOR NAT GATEWAYS
#===============================================================================

resource "aws_eip" "nat" {
  count  = 3
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-inspection-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.inspection]
}

#===============================================================================
# NAT GATEWAYS
#===============================================================================

resource "aws_nat_gateway" "inspection" {
  count         = 3
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.nat_gateway[count.index].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-inspection-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.inspection]
}

#===============================================================================
# AWS NETWORK FIREWALL - FIREWALL POLICY
#===============================================================================

resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${var.project_name}-${var.environment}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateless_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.stateless_rules.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_domain_rules.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful_suricata_rules.arn
    }

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-firewall-policy"
  })
}

#===============================================================================
# STATELESS RULE GROUP
#===============================================================================

resource "aws_networkfirewall_rule_group" "stateless_rules" {
  capacity = 100
  name     = "${var.project_name}-${var.environment}-stateless-rules"
  type     = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        # Allow established TCP connections
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              protocols = [6] # TCP
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }

        # Allow UDP traffic
        stateless_rule {
          priority = 2
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              protocols = [17] # UDP
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }

        # Allow ICMP for diagnostics
        stateless_rule {
          priority = 3
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              protocols = [1] # ICMP
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-stateless-rules"
  })
}

#===============================================================================
# STATEFUL RULE GROUP - DOMAIN FILTERING
#===============================================================================

resource "aws_networkfirewall_rule_group" "stateful_domain_rules" {
  capacity = 100
  name     = "${var.project_name}-${var.environment}-domain-rules"
  type     = "STATEFUL"

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [var.vpc_cidr, "10.0.0.0/8"]
        }
      }
    }

    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets = [
          # AWS Services
          ".amazonaws.com",
          ".aws.amazon.com",
          # Internal domains
          ".${var.private_domain}",
          # Third party integrations from diagram
          ".salesforce.com",
          ".okta.com",
          ".dynatrace.com",
          ".alfresco.com",
          # Package repositories
          ".docker.io",
          ".docker.com",
          ".github.com",
          ".githubusercontent.com"
        ]
      }
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-domain-rules"
  })
}

#===============================================================================
# STATEFUL RULE GROUP - SURICATA IPS RULES
#===============================================================================

resource "aws_networkfirewall_rule_group" "stateful_suricata_rules" {
  capacity = 200
  name     = "${var.project_name}-${var.environment}-suricata-rules"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<EOF
# Block known malicious domains
drop http any any -> any any (msg:"Block malicious domain"; http.host; content:"malware"; sid:1000001; rev:1;)
drop tls any any -> any any (msg:"Block malicious TLS"; tls.sni; content:"malware"; sid:1000002; rev:1;)

# Allow HTTPS outbound
pass tls $HOME_NET any -> any 443 (msg:"Allow HTTPS outbound"; flow:to_server; sid:1000003; rev:1;)

# Allow HTTP outbound (with inspection)
pass http $HOME_NET any -> any 80 (msg:"Allow HTTP outbound"; flow:to_server; sid:1000004; rev:1;)

# Allow DNS
pass udp $HOME_NET any -> any 53 (msg:"Allow DNS UDP"; sid:1000005; rev:1;)
pass tcp $HOME_NET any -> any 53 (msg:"Allow DNS TCP"; sid:1000006; rev:1;)

# Allow NTP
pass udp $HOME_NET any -> any 123 (msg:"Allow NTP"; sid:1000007; rev:1;)

# Block SSH to external (security control)
drop tcp $HOME_NET any -> !$HOME_NET 22 (msg:"Block external SSH"; sid:1000008; rev:1;)

# Block RDP to external (security control)
drop tcp $HOME_NET any -> !$HOME_NET 3389 (msg:"Block external RDP"; sid:1000009; rev:1;)

# Allow internal traffic
pass ip $HOME_NET any -> $HOME_NET any (msg:"Allow internal traffic"; sid:1000010; rev:1;)
EOF
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-suricata-rules"
  })
}

#===============================================================================
# AWS NETWORK FIREWALL - MAIN FIREWALL (FW AZ-1, FW AZ-2, FW AZ-3)
#===============================================================================

resource "aws_networkfirewall_firewall" "main" {
  name                = "${var.project_name}-${var.environment}-network-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
  vpc_id              = aws_vpc.inspection.id

  # Deploy firewall endpoints in all 3 AZs (FW AZ-1, FW AZ-2, FW AZ-3)
  dynamic "subnet_mapping" {
    for_each = aws_subnet.firewall
    content {
      subnet_id = subnet_mapping.value.id
    }
  }

  delete_protection                 = var.environment == "prod" ? true : false
  firewall_policy_change_protection = var.environment == "prod" ? true : false
  subnet_change_protection          = var.environment == "prod" ? true : false

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-network-firewall"
  })
}

#===============================================================================
# CLOUDWATCH LOG GROUP FOR FIREWALL LOGS
#===============================================================================

resource "aws_kms_key" "firewall_logs" {
  description             = "KMS key for Network Firewall logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true

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
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-firewall-logs-kms"
  })
}

resource "aws_kms_alias" "firewall_logs" {
  name          = "alias/${var.project_name}-${var.environment}-firewall-logs"
  target_key_id = aws_kms_key.firewall_logs.key_id
}

resource "aws_cloudwatch_log_group" "firewall_alert" {
  name              = "/aws/network-firewall/${var.project_name}-${var.environment}/alert"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.firewall_logs.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-firewall-alert-logs"
  })
}

resource "aws_cloudwatch_log_group" "firewall_flow" {
  name              = "/aws/network-firewall/${var.project_name}-${var.environment}/flow"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.firewall_logs.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-firewall-flow-logs"
  })
}

#===============================================================================
# NETWORK FIREWALL LOGGING CONFIGURATION
#===============================================================================

resource "aws_networkfirewall_logging_configuration" "main" {
  firewall_arn = aws_networkfirewall_firewall.main.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_alert.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }

    log_destination_config {
      log_destination = {
        logGroup = aws_cloudwatch_log_group.firewall_flow.name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}

#===============================================================================
# ROUTE TABLES - Firewall Subnets
#===============================================================================

resource "aws_route_table" "firewall" {
  count  = 3
  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-fw-rt-${count.index + 1}"
  })
}

resource "aws_route" "firewall_to_nat" {
  count                  = 3
  route_table_id         = aws_route_table.firewall[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.inspection[count.index].id
}

resource "aws_route_table_association" "firewall" {
  count          = 3
  subnet_id      = aws_subnet.firewall[count.index].id
  route_table_id = aws_route_table.firewall[count.index].id
}

#===============================================================================
# ROUTE TABLES - TGW Attachment Subnets
#===============================================================================

resource "aws_route_table" "tgw_attachment" {
  count  = 3
  vpc_id = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-tgw-rt-${count.index + 1}"
  })
}

# Route to firewall endpoint for internet-bound traffic
resource "aws_route" "tgw_to_firewall" {
  count                  = 3
  route_table_id         = aws_route_table.tgw_attachment[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = [for ep in aws_networkfirewall_firewall.main.firewall_status[0].sync_states : ep.attachment[0].endpoint_id if ep.availability_zone == data.aws_availability_zones.available.names[count.index]][0]

  depends_on = [aws_networkfirewall_firewall.main]
}

resource "aws_route_table_association" "tgw_attachment" {
  count          = 3
  subnet_id      = aws_subnet.tgw_attachment[count.index].id
  route_table_id = aws_route_table.tgw_attachment[count.index].id
}

#===============================================================================
# ROUTE TABLES - NAT Gateway Subnets (Public)
#===============================================================================

resource "aws_route_table" "nat_gateway" {
  vpc_id = aws_vpc.inspection.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.inspection.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-inspection-nat-rt"
  })
}

resource "aws_route_table_association" "nat_gateway" {
  count          = 3
  subnet_id      = aws_subnet.nat_gateway[count.index].id
  route_table_id = aws_route_table.nat_gateway.id
}

#===============================================================================
# VPC FLOW LOGS
#===============================================================================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/${var.project_name}-${var.environment}-inspection/flow-logs"
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.firewall_logs.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-inspection-vpc-flow-logs"
  })
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-inspection-vpc-flow-logs-role"

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

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-inspection-vpc-flow-logs-policy"
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

resource "aws_flow_log" "inspection" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.inspection.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-inspection-vpc-flow-log"
  })
}

#===============================================================================
# CLOUDWATCH ALARMS FOR FIREWALL
#===============================================================================

resource "aws_cloudwatch_metric_alarm" "firewall_dropped_packets" {
  alarm_name          = "${var.project_name}-${var.environment}-firewall-dropped-packets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DroppedPackets"
  namespace           = "AWS/NetworkFirewall"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "Alarm when firewall drops more than 1000 packets in 5 minutes"

  dimensions = {
    FirewallName = aws_networkfirewall_firewall.main.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "firewall_passed_packets" {
  alarm_name          = "${var.project_name}-${var.environment}-firewall-high-traffic"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "PassedPackets"
  namespace           = "AWS/NetworkFirewall"
  period              = 300
  statistic           = "Sum"
  threshold           = 10000000
  alarm_description   = "Alarm when firewall passes more than 10M packets in 5 minutes"

  dimensions = {
    FirewallName = aws_networkfirewall_firewall.main.name
  }

  tags = var.tags
}
