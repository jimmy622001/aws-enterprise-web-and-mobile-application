#=============================================================================
# HUB VPC MODULE - OUTPUTS
# modules/hub-vpc/outputs.tf
#=============================================================================

#-----------------------------------------------------------------------------
# VPC OUTPUTS
#-----------------------------------------------------------------------------
output "vpc_id" {
  description = "Hub VPC ID"
  value       = aws_vpc.hub.id
}

output "vpc_cidr_block" {
  description = "Hub VPC CIDR block"
  value       = aws_vpc.hub.cidr_block
}

output "vpc_arn" {
  description = "Hub VPC ARN"
  value       = aws_vpc.hub.arn
}

#-----------------------------------------------------------------------------
# SUBNET OUTPUTS
#-----------------------------------------------------------------------------
output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.hub_public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.hub_private[*].id
}

output "tgw_subnet_ids" {
  description = "List of Transit Gateway attachment subnet IDs"
  value       = aws_subnet.hub_tgw[*].id
}

output "public_subnet_cidrs" {
  description = "List of public subnet CIDR blocks"
  value       = aws_subnet.hub_public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks"
  value       = aws_subnet.hub_private[*].cidr_block
}

#-----------------------------------------------------------------------------
# GATEWAY OUTPUTS
#-----------------------------------------------------------------------------
output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.hub.id
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.hub[*].id
}

output "nat_gateway_public_ips" {
  description = "List of NAT Gateway public IPs"
  value       = aws_eip.nat[*].public_ip
}

#-----------------------------------------------------------------------------
# ROUTE TABLE OUTPUTS
#-----------------------------------------------------------------------------
output "public_route_table_id" {
  description = "Public route table ID"
  value       = aws_route_table.hub_public.id
}

output "private_route_table_ids" {
  description = "List of private route table IDs"
  value       = aws_route_table.hub_private[*].id
}

output "tgw_route_table_id" {
  description = "Transit Gateway route table ID"
  value       = aws_route_table.hub_tgw.id
}

#-----------------------------------------------------------------------------
# RESOLVER OUTPUTS
#-----------------------------------------------------------------------------
output "inbound_resolver_id" {
  description = "Route 53 Inbound Resolver ID"
  value       = aws_route53_resolver_endpoint.inbound.id
}

output "inbound_resolver_ips" {
  description = "Route 53 Inbound Resolver IP addresses"
  value       = aws_route53_resolver_endpoint.inbound.ip_address
}

output "outbound_resolver_id" {
  description = "Route 53 Outbound Resolver ID"
  value       = aws_route53_resolver_endpoint.outbound.id
}

#-----------------------------------------------------------------------------
# VPC ENDPOINT OUTPUTS
#-----------------------------------------------------------------------------
output "s3_endpoint_id" {
  description = "S3 VPC Endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_endpoint_id" {
  description = "DynamoDB VPC Endpoint ID"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "interface_endpoint_ids" {
  description = "Map of interface endpoint IDs"
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "vpc_endpoints_security_group_id" {
  description = "Security group ID for VPC endpoints"
  value       = aws_security_group.vpc_endpoints.id
}

#-----------------------------------------------------------------------------
# SECURITY OUTPUTS
#-----------------------------------------------------------------------------
output "kms_key_id" {
  description = "Hub VPC KMS key ID"
  value       = aws_kms_key.hub_main.id
}

output "kms_key_arn" {
  description = "Hub VPC KMS key ARN"
  value       = aws_kms_key.hub_main.arn
}

output "secrets_manager_secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.hub_credentials.arn
}

output "private_ca_arn" {
  description = "Private CA ARN"
  value       = aws_acmpca_certificate_authority.hub.arn
}

output "private_ca_certificate" {
  description = "Private CA certificate"
  value       = aws_acmpca_certificate_authority.hub.certificate
}

#-----------------------------------------------------------------------------
# FLOW LOG OUTPUTS
#-----------------------------------------------------------------------------
output "flow_log_id" {
  description = "VPC Flow Log ID"
  value       = aws_flow_log.hub.id
}

output "flow_log_log_group_name" {
  description = "CloudWatch Log Group name for VPC Flow Logs"
  value       = aws_cloudwatch_log_group.hub_flow_logs.name
}