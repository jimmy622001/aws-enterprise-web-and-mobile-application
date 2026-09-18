#===============================================================================
# INSPECTION VPC MODULE - OUTPUTS
#===============================================================================

output "vpc_id" {
  description = "Inspection VPC ID"
  value       = aws_vpc.inspection.id
}

output "vpc_cidr" {
  description = "Inspection VPC CIDR block"
  value       = aws_vpc.inspection.cidr_block
}

output "firewall_subnet_ids" {
  description = "Firewall subnet IDs (FW AZ-1, FW AZ-2, FW AZ-3)"
  value       = aws_subnet.firewall[*].id
}

output "tgw_attachment_subnet_ids" {
  description = "TGW attachment subnet IDs"
  value       = aws_subnet.tgw_attachment[*].id
}

output "nat_gateway_subnet_ids" {
  description = "NAT gateway subnet IDs"
  value       = aws_subnet.nat_gateway[*].id
}

output "firewall_id" {
  description = "Network Firewall ID"
  value       = aws_networkfirewall_firewall.main.id
}

output "firewall_arn" {
  description = "Network Firewall ARN"
  value       = aws_networkfirewall_firewall.main.arn
}

output "firewall_name" {
  description = "Network Firewall name"
  value       = aws_networkfirewall_firewall.main.name
}

output "firewall_endpoint_ids" {
  description = "Network Firewall endpoint IDs by AZ"
  value = {
    for state in aws_networkfirewall_firewall.main.firewall_status[0].sync_states :
    state.availability_zone => state.attachment[0].endpoint_id
  }
}

output "firewall_policy_arn" {
  description = "Network Firewall policy ARN"
  value       = aws_networkfirewall_firewall_policy.main.arn
}

output "firewall_alert_log_group" {
  description = "CloudWatch log group for firewall alerts"
  value       = aws_cloudwatch_log_group.firewall_alert.name
}

output "firewall_flow_log_group" {
  description = "CloudWatch log group for firewall flow logs"
  value       = aws_cloudwatch_log_group.firewall_flow.name
}

output "kms_key_arn" {
  description = "KMS key ARN for firewall logs"
  value       = aws_kms_key.firewall_logs.arn
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs"
  value       = aws_nat_gateway.inspection[*].id
}

output "nat_gateway_public_ips" {
  description = "NAT Gateway public IPs"
  value       = aws_eip.nat[*].public_ip
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.inspection.id
}

output "firewall_route_table_ids" {
  description = "Firewall subnet route table IDs"
  value       = aws_route_table.firewall[*].id
}

output "tgw_route_table_ids" {
  description = "TGW attachment subnet route table IDs"
  value       = aws_route_table.tgw_attachment[*].id
}

output "vpc_flow_log_group" {
  description = "VPC Flow Log CloudWatch log group"
  value       = aws_cloudwatch_log_group.vpc_flow_logs.name
}