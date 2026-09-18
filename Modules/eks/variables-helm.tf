#====================================================================
# HELM VARIABLES
#====================================================================

variable "istio_version" {
  description = "Istio Helm chart version"
  type        = string
  default     = "1.20.2"
}