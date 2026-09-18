#===============================================================================
# PRIVATE INGRESS VPC MODULE - OUTPUTS
# Location: modules/private-ingress-vpc/outputs.tf
#===============================================================================

#-------------------------------------------------------------------------------
# VPC OUTPUTS
#-------------------------------------------------------------------------------
output "vpc_id" {
  description = "ID of the Private Ingress VPC"
  value       = aws_vpc.private_ingress.id
}

output "vpc_cidr" {
  description = "CIDR block of the Private Ingress VPC"
  value       = aws_vpc.private_ingress.cidr_block
}

output "vpc_arn" {
  description = "ARN of the Private Ingress VPC"
  value       = aws_vpc.private_ingress.arn
}

#-------------------------------------------------------------------------------
# SUBNET OUTPUTS
#-------------------------------------------------------------------------------
output "client_vpn_subnet_ids" {
  description = "List of Client VPN subnet IDs"
  value       = aws_subnet.client_vpn[*].id
}

output "vpc_endpoint_subnet_ids" {
  description = "List of VPC Endpoint subnet IDs"
  value       = aws_subnet.vpc_endpoints[*].id
}

output "tgw_attachment_subnet_ids" {
  description = "List of Transit Gateway attachment subnet IDs"
  value       = aws_subnet.tgw_attachment[*].id
}

#-------------------------------------------------------------------------------
# CLIENT VPN OUTPUTS
#-------------------------------------------------------------------------------
# COMMENTED OUT FOR POC - Client VPN resources are disabled
#
# output "client_vpn_endpoint_id" {
#   description = "ID of the Client VPN endpoint"
#   value       = aws_ec2_client_vpn_endpoint.main.id
# }
#
# output "client_vpn_endpoint_arn" {
#   description = "ARN of the Client VPN endpoint"
#   value       = aws_ec2_client_vpn_endpoint.main.arn
# }
#
# output "client_vpn_endpoint_dns_name" {
#   description = "DNS name of the Client VPN endpoint"
#   value       = aws_ec2_client_vpn_endpoint.main.dns_name
# }
#
# output "client_vpn_self_service_portal_url" {
#   description = "Self-service portal URL for Client VPN"
#   value       = aws_ec2_client_vpn_endpoint.main.self_service_portal_url
# }

#-------------------------------------------------------------------------------
# SECURITY GROUP OUTPUTS
#-------------------------------------------------------------------------------
# COMMENTED OUT FOR POC - Client VPN security group is disabled
#
# output "client_vpn_security_group_id" {
#   description = "Security group ID for Client VPN endpoint"
#   value       = aws_security_group.client_vpn_endpoint.id
# }

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

#-------------------------------------------------------------------------------
# VPC ENDPOINT OUTPUTS
#-------------------------------------------------------------------------------
output "ssm_endpoint_id" {
  description = "ID of SSM VPC endpoint"
  value       = aws_vpc_endpoint.ssm.id
}

output "sts_endpoint_id" {
  description = "ID of STS VPC endpoint"
  value       = aws_vpc_endpoint.sts.id
}

output "kms_endpoint_id" {
  description = "ID of KMS VPC endpoint"
  value       = aws_vpc_endpoint.kms.id
}

output "logs_endpoint_id" {
  description = "ID of CloudWatch Logs VPC endpoint"
  value       = aws_vpc_endpoint.logs.id
}

#-------------------------------------------------------------------------------
# KMS OUTPUTS
#-------------------------------------------------------------------------------
# COMMENTED OUT FOR POC - Client VPN KMS key is disabled
#
# output "kms_key_id" {
#   description = "KMS key ID for Client VPN logs"
#   value       = aws_kms_key.client_vpn_logs.id
# }
#
# output "kms_key_arn" {
#   description = "KMS key ARN for Client VPN logs"
#   value       = aws_kms_key.client_vpn_logs.arn
# }

#-------------------------------------------------------------------------------
# CLOUDWATCH OUTPUTS
#-------------------------------------------------------------------------------
# COMMENTED OUT FOR POC - Client VPN CloudWatch logs are disabled
#
# output "client_vpn_log_group_name" {
#   description = "CloudWatch log group name for Client VPN"
#   value       = aws_cloudwatch_log_group.client_vpn.name
# }
#
# output "client_vpn_log_group_arn" {
#   description = "CloudWatch log group ARN for Client VPN"
#   value       = aws_cloudwatch_log_group.client_vpn.arn
# }

output "vpc_flow_logs_log_group_name" {
  description = "CloudWatch log group name for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}

#-------------------------------------------------------------------------------
# ROUTE TABLE OUTPUTS
#-------------------------------------------------------------------------------
output "client_vpn_route_table_id" {
  description = "Route table ID for Client VPN subnets"
  value       = aws_route_table.client_vpn.id
}

output "vpc_endpoints_route_table_id" {
  description = "Route table ID for VPC endpoint subnets"
  value       = aws_route_table.vpc_endpoints.id
}

output "tgw_attachment_route_table_id" {
  description = "Route table ID for TGW attachment subnets"
  value       = aws_route_table.tgw_attachment.id
}

#-------------------------------------------------------------------------------
# SAML PROVIDER OUTPUT
#-------------------------------------------------------------------------------
# COMMENTED OUT FOR POC - Okta SAML provider is disabled
#
# output "okta_saml_provider_arn" {
#   description = "ARN of the Okta SAML provider"
#   value       = aws_iam_saml_provider.okta.arn
# }
