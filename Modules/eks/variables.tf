#====================================================================
# EKS MODULE - VARIABLES
#====================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for EKS cluster"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

#====================================================================
# EKS CLUSTER CONFIGURATION
#====================================================================

variable "eks_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.29"
}

variable "eks_public_access" {
  description = "Enable public access to EKS API endpoint"
  type        = bool
  default     = false
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed for public access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_admin_role_arns" {
  description = "IAM role ARNs for EKS cluster admin access"
  type        = list(string)
  default     = []
}

#====================================================================
# EKS ADDONS VERSIONS
#====================================================================

variable "vpc_cni_version" {
  description = "VPC CNI addon version"
  type        = string
  default     = "v1.16.0-eksbuild.1"
}

variable "coredns_version" {
  description = "CoreDNS addon version"
  type        = string
  default     = "v1.11.1-eksbuild.6"
}

variable "kube_proxy_version" {
  description = "Kube Proxy addon version"
  type        = string
  default     = "v1.29.0-eksbuild.2"
}

variable "ebs_csi_version" {
  description = "EBS CSI Driver addon version"
  type        = string
  default     = "v1.27.0-eksbuild.1"
}

#====================================================================
# SYSTEM NODE GROUP CONFIGURATION
#====================================================================

variable "system_node_instance_types" {
  description = "Instance types for system node group"
  type        = list(string)
  default     = ["m6i.large", "m5.large"]
}

variable "system_node_desired_size" {
  description = "Desired size of system node group"
  type        = number
  default     = 3
}

variable "system_node_min_size" {
  description = "Minimum size of system node group"
  type        = number
  default     = 2
}

variable "system_node_max_size" {
  description = "Maximum size of system node group"
  type        = number
  default     = 5
}

#====================================================================
# APPLICATION NODE GROUP CONFIGURATION
#====================================================================

variable "app_node_instance_types" {
  description = "Instance types for application node group"
  type        = list(string)
  default     = ["m6i.xlarge", "m5.xlarge"]
}

variable "app_node_desired_size" {
  description = "Desired size of application node group"
  type        = number
  default     = 3
}

variable "app_node_min_size" {
  description = "Minimum size of application node group"
  type        = number
  default     = 2
}

variable "app_node_max_size" {
  description = "Maximum size of application node group"
  type        = number
  default     = 20
}

variable "app_node_capacity_type" {
  description = "Capacity type for application nodes (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

#====================================================================
# EXTERNAL RESOURCES
#====================================================================

variable "cms_assets_bucket_arn" {
  description = "ARN of CMS assets S3 bucket for Strapi"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}