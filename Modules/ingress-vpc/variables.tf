#====================================================================
# INGRESS VPC MODULE - VARIABLES
#====================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for Ingress VPC"
  type        = string
  default     = "10.30.0.0/16"
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID for VPC attachment"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

#====================================================================
# NGINX CONFIGURATION
#====================================================================

variable "nginx_image" {
  description = "Docker image for NGINX proxy"
  type        = string
  default     = "nginx:stable-alpine"
}

variable "nginx_cpu" {
  description = "CPU units for NGINX task"
  type        = string
  default     = "512"
}

variable "nginx_memory" {
  description = "Memory (MB) for NGINX task"
  type        = string
  default     = "1024"
}

variable "nginx_desired_count" {
  description = "Desired number of NGINX tasks"
  type        = number
  default     = 3
}

variable "nginx_min_count" {
  description = "Minimum number of NGINX tasks"
  type        = number
  default     = 2
}

variable "nginx_max_count" {
  description = "Maximum number of NGINX tasks"
  type        = number
  default     = 10
}

variable "upstream_host" {
  description = "Upstream host for NGINX proxy"
  type        = string
  default     = "workload-alb.internal"
}