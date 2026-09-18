#====================================================================
# PROVIDERS CONFIGURATION
# AWS Infrastructure - Enterprise Web and Mobile Architecture
#====================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }

  # Backend configuration - uncomment and configure for your environment
  # backend "s3" {
  #   bucket         = "example-terraform-state"
  #   key            = "infrastructure/terraform.tfstate"
  #   region         = "eu-west-1"
  #   encrypt        = true
  #   dynamodb_table = "example-terraform-locks"
  # }
}

#====================================================================
# PROVIDER CONFIGURATIONS
#====================================================================

# Default provider - Networking Account
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }

  # Uncomment for cross-account deployment
  # assume_role {
  #   role_arn = "arn:aws:iam::${var.networking_account_id}:role/TerraformExecutionRole"
  # }
}

# Networking Account Provider
provider "aws" {
  alias  = "networking"
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }

  # assume_role {
  #   role_arn = "arn:aws:iam::${var.networking_account_id}:role/TerraformExecutionRole"
  # }
}

# Workload Account Provider
provider "aws" {
  alias  = "workload"
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }

  # assume_role {
  #   role_arn = "arn:aws:iam::${var.workload_account_id}:role/TerraformExecutionRole"
  # }
}

# Shared Services Account Provider
provider "aws" {
  alias  = "shared_services"
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }

  # assume_role {
  #   role_arn = "arn:aws:iam::${var.shared_services_account_id}:role/TerraformExecutionRole"
  # }
}

# US-East-1 Provider (Required for CloudFront WAF)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = var.common_tags
  }

  # assume_role {
  #   role_arn = "arn:aws:iam::${var.workload_account_id}:role/TerraformExecutionRole"
  # }
}

#====================================================================
# DISASTER RECOVERY REGION PROVIDERS (eu-west-2 - London)
#====================================================================

# DR Default provider - Networking Account
provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = merge(
      var.common_tags,
      {
        Region       = var.dr_region
        DRPurpose    = "Disaster Recovery"
        Failover     = "Pilot Light"
      }
    )
  }

  # assume_role {
  #   role_arn = "arn:aws:iam::${var.networking_account_id}:role/TerraformExecutionRole"
  # }
}

# DR Networking Account Provider
provider "aws" {
  alias  = "dr_networking"
  region = var.dr_region

  default_tags {
    tags = merge(
      var.common_tags,
      {
        Region       = var.dr_region
        DRPurpose    = "Disaster Recovery"
        Failover     = "Pilot Light"
      }
    )
  }

  # assume_role {
  #   role_arn = "arn:aws:iam::${var.networking_account_id}:role/TerraformExecutionRole"
  # }
}

# DR Workload Account Provider
provider "aws" {
  alias  = "dr_workload"
  region = var.dr_region

  default_tags {
    tags = merge(
      var.common_tags,
      {
        Region       = var.dr_region
        DRPurpose    = "Disaster Recovery"
        Failover     = "Pilot Light"
      }
    )
  }

  # assume_role {
  #   role_arn = "arn:aws:iam::${var.workload_account_id}:role/TerraformExecutionRole"
  # }
}

# DR Shared Services Account Provider
provider "aws" {
  alias  = "dr_shared_services"
  region = var.dr_region

  default_tags {
    tags = merge(
      var.common_tags,
      {
        Region       = var.dr_region
        DRPurpose    = "Disaster Recovery"
        Failover     = "Pilot Light"
      }
    )
  }

  # assume_role {
  #   role_arn = "arn:aws:iam::${var.shared_services_account_id}:role/TerraformExecutionRole"
  # }
}

# Kubernetes Provider (configured after EKS is created)
# Temporarily disabled for POC
# provider "kubernetes" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
# 
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     command     = "aws"
#     args = [
#       "eks",
#       "get-token",
#       "--cluster-name",
#       module.eks.cluster_name,
#       "--region",
#       var.aws_region
#     ]
#   }
# }
# 
# # Helm Provider
# provider "helm" {
#   kubernetes = {
#     host                   = module.eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
# 
#     exec = {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args = [
#         "eks",
#         "get-token",
#         "--cluster-name",
#         module.eks.cluster_name,
#         "--region",
#         var.aws_region
#       ]
#     }
#   }
# }