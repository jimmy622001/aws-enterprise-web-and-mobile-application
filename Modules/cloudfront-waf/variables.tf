#====================================================================
# CLOUDFRONT & WAF MODULE - VARIABLES
#====================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

#====================================================================
# CLOUDFRONT CONFIGURATION
#====================================================================

variable "web_domain_aliases" {
  description = "Domain aliases for Web CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "cms_domain_aliases" {
  description = "Domain aliases for CMS CloudFront distribution"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn_us_east_1" {
  description = "ACM certificate ARN in us-east-1 for CloudFront"
  type        = string
}

variable "acm_certificate_arn_regional" {
  description = "ACM certificate ARN in regional region for API Gateway"
  type        = string
}

variable "ingress_alb_dns_name" {
  description = "DNS name of the Ingress ALB"
  type        = string
}

variable "ingress_nlb_dns_name" {
  description = "DNS name of the Ingress NLB"
  type        = string
}

variable "ingress_nlb_arn" {
  description = "ARN of the Ingress NLB for VPC Link"
  type        = string
}

variable "cloudfront_custom_header_value" {
  description = "Custom header value for CloudFront to ALB verification"
  type        = string
  default     = "X-Verify-CloudFront-Origin"
  sensitive   = true
}

#====================================================================
# WAF CONFIGURATION
#====================================================================

variable "blocked_countries" {
  description = "List of country codes to block"
  type        = list(string)
  default     = ["RU", "CN", "KP", "IR"]
}

#====================================================================
# API GATEWAY CONFIGURATION
#====================================================================

variable "api_domain_name" {
  description = "Custom domain name for API Gateway"
  type        = string
  default     = ""
}

variable "api_throttling_burst_limit" {
  description = "API Gateway throttling burst limit"
  type        = number
  default     = 5000
}

variable "api_throttling_rate_limit" {
  description = "API Gateway throttling rate limit"
  type        = number
  default     = 10000
}

#====================================================================
# S3 LOGGING CONFIGURATION
#====================================================================

variable "access_logs_bucket_name" {
  description = "Central S3 access logs bucket name"
  type        = string
  default     = ""
}