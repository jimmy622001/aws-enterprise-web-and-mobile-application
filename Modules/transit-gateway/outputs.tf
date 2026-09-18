#==============================================================================
# TRANSIT GATEWAY MODULE - OUTPUTS
#==============================================================================

#------------------------------------------------------------------------------
# TRANSIT GATEWAY OUTPUTS
#------------------------------------------------------------------------------
output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = aws_ec2_transit_gateway.main.id
}

output "transit_gateway_arn" {
  description = "Transit Gateway ARN"
  value       = aws_ec2_transit_gateway.main.arn
}

output "transit_gateway_owner_id" {
  description = "Transit Gateway owner account ID"
  value       = aws_ec2_transit_gateway.main.owner_id
}

output "transit_gateway_asn" {
  description = "Transit Gateway Amazon side ASN"
  value       = aws_ec2_transit_gateway.main.amazon_side_asn
}

#------------------------------------------------------------------------------
# ROUTE TABLE OUTPUTS
#------------------------------------------------------------------------------
output "hub_route_table_id" {
  description = "Hub VPC Transit Gateway route table ID"
  value       = aws_ec2_transit_gateway_route_table.hub.id
}

output "inspection_route_table_id" {
  description = "Inspection VPC Transit Gateway route table ID"
  value       = aws_ec2_transit_gateway_route_table.inspection.id
}

output "spoke_route_table_id" {
  description = "Spoke VPCs Transit Gateway route table ID"
  value       = aws_ec2_transit_gateway_route_table.spoke.id
}

output "shared_services_route_table_id" {
  description = "Shared Services VPC Transit Gateway route table ID"
  value       = aws_ec2_transit_gateway_route_table.shared_services.id
}

output "private_ingress_route_table_id" {
  description = "Private Ingress VPC Transit Gateway route table ID"
  value       = aws_ec2_transit_gateway_route_table.private_ingress.id
}

#------------------------------------------------------------------------------
# VPC ATTACHMENT OUTPUTS - NETWORKING ACCOUNT
#------------------------------------------------------------------------------
output "hub_vpc_attachment_id" {
  description = "Hub VPC Transit Gateway attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.hub.id
}

output "private_ingress_vpc_attachment_id" {
  description = "Private Ingress VPC Transit Gateway attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.private_ingress.id
}

output "inspection_vpc_attachment_id" {
  description = "Inspection VPC Transit Gateway attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.inspection.id
}

#------------------------------------------------------------------------------
# VPC ATTACHMENT OUTPUTS - WORKLOAD ACCOUNT
#------------------------------------------------------------------------------
output "workload_vpc_attachment_id" {
  description = "Workload VPC Transit Gateway attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.workload.id
}

output "ingress_vpc_attachment_id" {
  description = "Ingress VPC Transit Gateway attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.ingress.id
}

output "data_vpc_attachment_id" {
  description = "Data VPC Transit Gateway attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.data.id
}

#------------------------------------------------------------------------------
# VPC ATTACHMENT OUTPUTS - SHARED SERVICES ACCOUNT
#------------------------------------------------------------------------------
output "shared_services_vpc_attachment_id" {
  description = "Shared Services VPC Transit Gateway attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.shared_services.id
}

#------------------------------------------------------------------------------
# VPN OUTPUTS
#------------------------------------------------------------------------------
output "vpn_connection_id" {
  description = "Site-to-Site VPN connection ID"
  value       = aws_vpn_connection.onprem.id
}

output "vpn_connection_tunnel1_address" {
  description = "VPN Tunnel 1 public IP address"
  value       = aws_vpn_connection.onprem.tunnel1_address
  sensitive   = true
}

output "vpn_connection_tunnel2_address" {
  description = "VPN Tunnel 2 public IP address"
  value       = aws_vpn_connection.onprem.tunnel2_address
  sensitive   = true
}

output "customer_gateway_id" {
  description = "Customer Gateway ID for on-premises"
  value       = aws_customer_gateway.onprem.id
}

#------------------------------------------------------------------------------
# RAM RESOURCE SHARE OUTPUTS
#------------------------------------------------------------------------------
output "ram_resource_share_arn" {
  description = "RAM Resource Share ARN for Transit Gateway"
  value       = aws_ram_resource_share.transit_gateway.arn
}

#------------------------------------------------------------------------------
# FLOW LOGS OUTPUTS
#------------------------------------------------------------------------------
output "flow_logs_log_group_arn" {
  description = "CloudWatch Log Group ARN for TGW flow logs"
  value       = aws_cloudwatch_log_group.tgw_flow_logs.arn
}

output "flow_logs_role_arn" {
  description = "IAM Role ARN for TGW flow logs"
  value       = aws_iam_role.tgw_flow_logs.arn
}
