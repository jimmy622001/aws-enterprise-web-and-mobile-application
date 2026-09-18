#====================================================================
# DATA VPC MODULE - VARIABLES
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
  description = "CIDR block for Data VPC"
  type        = string
  default     = "10.40.0.0/16"
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID for VPC attachment"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "organization_name" {
  description = "Organization name for Private CA"
  type        = string
  default     = "West Brom"
}

#====================================================================
# GLUE CONFIGURATION
#====================================================================

variable "glue_worker_type" {
  description = "Glue worker type"
  type        = string
  default     = "G.1X"
}

variable "glue_number_of_workers" {
  description = "Number of Glue workers"
  type        = number
  default     = 2
}

#====================================================================
# AIRFLOW CONFIGURATION
#====================================================================

variable "airflow_version" {
  description = "MWAA Airflow version"
  type        = string
  default     = "2.7.2"
}

variable "airflow_environment_class" {
  description = "MWAA environment class"
  type        = string
  default     = "mw1.medium"
}

variable "airflow_max_workers" {
  description = "Maximum number of Airflow workers"
  type        = number
  default     = 10
}

variable "airflow_min_workers" {
  description = "Minimum number of Airflow workers"
  type        = number
  default     = 1
}