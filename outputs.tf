#====================================================================
# ROOT MODULE OUTPUTS - POC VERSION
# Simplified outputs for quick POC deployment
#====================================================================

#====================================================================
# NETWORKING ACCOUNT OUTPUTS
#====================================================================

# Hub VPC
output "hub_vpc_id" {
  description = "Hub VPC ID"
  value       = module.hub_vpc.vpc_id
}

# Transit Gateway
output "transit_gateway_id" {
  description = "Transit Gateway ID"
  value       = module.transit_gateway.transit_gateway_id
}

output "transit_gateway_arn" {
  description = "Transit Gateway ARN"
  value       = module.transit_gateway.transit_gateway_arn
}

#====================================================================
# WORKLOAD ACCOUNT OUTPUTS
#====================================================================

# Workload VPC
output "workload_vpc_id" {
  description = "Workload VPC ID"
  value       = module.workload_vpc.vpc_id
}

output "workload_vpc_cidr" {
  description = "Workload VPC CIDR block"
  value       = module.workload_vpc.vpc_cidr
}

# Ingress VPC
output "ingress_vpc_id" {
  description = "Ingress VPC ID"
  value       = module.ingress_vpc.vpc_id
}

output "ingress_alb_dns_name" {
  description = "Ingress ALB DNS name"
  value       = module.ingress_vpc.alb_dns_name
}

output "ingress_nlb_dns_name" {
  description = "Ingress NLB DNS name"
  value       = module.ingress_vpc.nlb_dns_name
}

# Data VPC
output "data_vpc_id" {
  description = "Data VPC ID"
  value       = module.data_vpc.vpc_id
}

output "data_vpc_cidr" {
  description = "Data VPC CIDR block"
  value       = module.data_vpc.vpc_cidr
}

# EKS Cluster - Temporarily disabled for POC
# output "eks_cluster_name" {
#   description = "EKS cluster name"
#   value       = module.eks.cluster_name
# }
# 
# output "eks_cluster_endpoint" {
#   description = "EKS cluster API endpoint"
#   value       = module.eks.cluster_endpoint
#   sensitive   = true
# }

#====================================================================
# SHARED SERVICES ACCOUNT OUTPUTS
#====================================================================

# Shared Services VPC
output "shared_services_vpc_id" {
  description = "Shared Services VPC ID"
  value       = module.shared_services.vpc_id
}

output "shared_services_vpc_cidr" {
  description = "Shared Services VPC CIDR block"
  value       = module.shared_services.vpc_cidr
}

#====================================================================
# KUBECTL CONFIGURATION
#====================================================================

output "kubectl_config" {
  description = "Commands to configure kubectl for EKS cluster - EKS module disabled for POC"
  value       = "EKS module is currently disabled for POC validation"
}
