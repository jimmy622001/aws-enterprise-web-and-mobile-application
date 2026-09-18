# POC Configuration Changes

## ⚠️ IMPORTANT: Using Terraform Workspaces

**As of the latest update, this project uses Terraform Workspaces to manage different environments.**

Instead of manually commenting/uncommenting code sections, we now use:
- **Feature flags** in variables (`enable_client_vpn`, `enable_eks`, etc.)
- **Environment-specific `.tfvars` files** (`poc.tfvars`, `dev.tfvars`, etc.)
- **Isolated state files** per workspace

📚 **See [WORKSPACE-GUIDE.md](./WORKSPACE-GUIDE.md) for complete workspace usage documentation.**

The information below is kept for **historical reference** and explains what was originally disabled in POC.

---

# Historical POC Changes (Pre-Workspace)

**Note**: The sections below describe the manual code changes that were made before implementing workspaces.
These are now handled automatically via feature flags in `poc.tfvars`.

---

## Overview

This document tracks all modifications made to convert the full production infrastructure to a **Proof of Concept (POC)** configuration with **local state files**. These changes allow rapid development and testing before migrating to production-ready configuration.

---

## 🎯 POC Objectives

- ✅ Enable **local Terraform state** (no S3 backend required)
- ✅ Disable complex components requiring external dependencies
- ✅ Maintain core networking and infrastructure functionality
- ✅ Keep configuration migration-ready for production

---

## 📋 Changes Made

### 1. **Provider Configuration** (`providers.tf`)

#### **BEFORE (Production)**
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

#### **AFTER (POC)**
```hcl
terraform {
  # Backend commented out for POC - using local state
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "infrastructure/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}
```

**Impact**: Terraform uses local `terraform.tfstate` file in project root instead of S3.

---

### 2. **Client VPN Disabled** (`Modules/private-ingress-vpc/main.tf`)

#### **REASON**: 
Client VPN requires **Okta SAML metadata** which needs:
- Active Okta tenant configuration
- SAML application setup
- Certificate generation
- Network connectivity to Okta

#### **Resources Commented Out**:
- **Lines 132-234**: AWS Client VPN Endpoint
- **Lines 245-274**: Client VPN Security Group  
- **Lines 394-463**: KMS Keys and CloudWatch Log Groups for Client VPN
- **Lines 465-510**: IAM SAML Provider

#### **Variables Affected**:
```hcl
# These variables are defined but not used in POC
okta_saml_metadata                  = ""  # Empty in dev.tfvars
client_vpn_server_certificate_arn   = ""  # Not required
client_vpn_server_certificate_body  = ""  # Not required
client_vpn_server_private_key       = ""  # Not required
```

#### **Outputs Commented Out** (`Modules/private-ingress-vpc/outputs.tf`):
- **Lines 45-67**: Client VPN endpoint outputs
- **Lines 70-76**: Client VPN security group ID
- **Lines 108-119**: KMS key outputs for Client VPN
- **Lines 123-135**: CloudWatch log group outputs
- **Lines 161-166**: SAML provider ARN

**Impact**: 
- ❌ No VPN access to private networks during POC
- ✅ All other networking functionality remains intact
- ✅ Can be re-enabled by uncommenting these sections

---

### 3. **EKS Module Temporarily Disabled** (`main.tf`)

#### **REASON**:
EKS module has complex dependencies:
- Kubernetes provider requires EKS cluster endpoint
- Helm provider requires Kubernetes API access
- Multiple Helm releases with complex configurations
- TLS certificate generation
- IRSA (IAM Roles for Service Accounts) setup

#### **Resources Commented Out**:
- **Lines 310-336**: EKS module call in `main.tf`
- **Kubernetes provider configuration** in `providers.tf`
- **Helm provider configuration** in `providers.tf`

#### **Outputs Commented Out** (`outputs.tf`):
- All EKS-related outputs (cluster endpoint, OIDC provider, node groups, etc.)

**Impact**:
- ❌ No Kubernetes cluster during POC
- ✅ Core VPC networking, Transit Gateway, and data services remain functional
- ✅ Can be re-enabled once core infrastructure is validated

---

### 4. **VPC Flow Logs Simplified** (`Modules/private-ingress-vpc/main.tf`)

#### **BEFORE**:
```hcl
kms_key_id = aws_kms_key.client_vpn_logs.arn
```

#### **AFTER**:
```hcl
# KMS encryption removed for POC simplicity
# kms_key_id can be added back when Client VPN is re-enabled
```

**Impact**: VPC Flow Logs use default AWS managed encryption instead of customer-managed KMS keys.

---

## 🔄 Re-enabling Production Features

### **Step 1: Enable Remote Backend**

Uncomment backend configuration in `providers.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

Then migrate state:
```bash
terraform init -migrate-state
```

---

### **Step 2: Re-enable Client VPN**

#### **2.1 Configure Okta SAML**

1. Create SAML application in Okta
2. Export SAML metadata XML
3. Update `dev.tfvars`:

```hcl
okta_saml_metadata = <<-EOT
<?xml version="1.0" encoding="UTF-8"?>
<EntityDescriptor xmlns="urn:oasis:names:tc:SAML:2.0:metadata"...>
  <!-- Full Okta SAML metadata -->
</EntityDescriptor>
EOT
```

#### **2.2 Generate Certificates**

```bash
# Generate server certificate and key
openssl req -x509 -newkey rsa:2048 -keyout server.key -out server.crt -days 365 -nodes
```

Update `dev.tfvars`:
```hcl
client_vpn_server_certificate_arn  = "arn:aws:acm:region:account:certificate/xxx"
```

#### **2.3 Uncomment Resources**

In `Modules/private-ingress-vpc/main.tf`:
```bash
# Uncomment lines 132-234 (Client VPN Endpoint)
# Uncomment lines 245-274 (Security Group)
# Uncomment lines 394-463 (KMS and CloudWatch)
# Uncomment lines 465-510 (SAML Provider)
```

In `Modules/private-ingress-vpc/outputs.tf`:
```bash
# Uncomment lines 45-67 (VPN outputs)
# Uncomment lines 70-76 (Security Group)
# Uncomment lines 108-119 (KMS outputs)
# Uncomment lines 123-135 (CloudWatch outputs)
# Uncomment lines 161-166 (SAML provider)
```

#### **2.4 Deploy**
```bash
terraform plan -var-file="dev.tfvars"
terraform apply
```

---

### **Step 3: Re-enable EKS**

#### **3.1 Uncomment EKS Module**

In `main.tf`:
```bash
# Uncomment lines 310-336 (EKS module call)
```

#### **3.2 Uncomment Provider Configurations**

In `providers.tf`:
```bash
# Uncomment Kubernetes provider configuration
# Uncomment Helm provider configuration
```

#### **3.3 Uncomment Outputs**

In `outputs.tf`:
```bash
# Uncomment all EKS-related outputs
```

#### **3.4 Deploy**
```bash
terraform plan -var-file="dev.tfvars"
terraform apply
```

---

## 📊 Resource Count Comparison

| Configuration | Resources | State Storage | Client VPN | EKS |
|--------------|-----------|---------------|------------|-----|
| **POC** | 839 | Local file | ❌ Disabled | ❌ Disabled |
| **Full Production** | ~1200 | S3 + DynamoDB | ✅ Enabled | ✅ Enabled |

---

## 🔐 Security Considerations

### **POC Environment**
- ✅ VPC isolation maintained
- ✅ Security Groups active
- ✅ Network Firewall operational
- ✅ Transit Gateway routing functional
- ⚠️ Local state file (not encrypted at rest in S3)
- ⚠️ No VPN access (use AWS Systems Manager Session Manager instead)

### **Production Environment**
- ✅ All POC security controls
- ✅ Remote state with encryption
- ✅ State locking with DynamoDB
- ✅ Client VPN with MFA
- ✅ EKS with pod security policies

---

## 📝 Environment Variables

### **POC (dev.tfvars)**
```hcl
# Required for POC
environment         = "dev"
aws_region         = "eu-west-1"
availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

# VPC CIDRs
hub_vpc_cidr               = "10.0.0.0/16"
private_ingress_vpc_cidr   = "10.1.0.0/16"
inspection_vpc_cidr        = "10.2.0.0/16"
workload_vpc_cidr          = "10.10.0.0/16"
ingress_vpc_cidr           = "10.11.0.0/16"
data_vpc_cidr              = "10.12.0.0/16"
shared_services_vpc_cidr   = "10.20.0.0/16"

# Client VPN (not used in POC but must be defined)
okta_saml_metadata                = ""  # Empty for POC
client_vpn_split_tunnel           = true
client_vpn_session_timeout_hours  = 10

# Other required variables...
```

---

## 🚀 Migration Path: POC → Production

### **Phase 1: Validate Core Infrastructure (POC)**
```bash
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```
**Duration**: 30-45 minutes  
**Validates**: Networking, Transit Gateway, VPC Endpoints, Security Groups

---

### **Phase 2: Enable Remote State**
```bash
# 1. Create S3 bucket and DynamoDB table
aws s3 mb s3://your-terraform-state-bucket
aws dynamodb create-table --table-name terraform-state-lock ...

# 2. Uncomment backend in providers.tf
# 3. Migrate state
terraform init -migrate-state
```
**Duration**: 10 minutes  
**Impact**: State moves to S3, enables team collaboration

---

### **Phase 3: Enable Client VPN**
```bash
# 1. Configure Okta SAML
# 2. Update dev.tfvars with SAML metadata
# 3. Uncomment Client VPN resources
# 4. Deploy
terraform apply -var-file="dev.tfvars"
```
**Duration**: 15-20 minutes  
**Validates**: VPN connectivity, Okta integration

---

### **Phase 4: Enable EKS**
```bash
# 1. Uncomment EKS module and providers
# 2. Deploy
terraform apply -var-file="dev.tfvars"
```
**Duration**: 20-30 minutes  
**Validates**: Kubernetes cluster, Helm deployments, IRSA

---

### **Phase 5: Production Deployment**
```bash
# 1. Update prod.tfvars with production values
# 2. Review plan carefully
terraform plan -var-file="prod.tfvars" -out=prod.tfplan

# 3. Apply with approval
terraform apply prod.tfplan
```
**Duration**: 45-60 minutes  
**Result**: Full production infrastructure

---

## 📖 Related Documentation

- [Components Overview](Components.md) - All infrastructure components
- [Network Architecture](Network%20Architecture.md) - VPC layout and routing
- [Security Architecture](Security%20Architecture.md) - Defense in depth strategy
- [Directory Structure](directory%20structure.md) - Repository organization

---

## ✅ Validation Checklist

### **POC Deployment**
- [ ] `terraform init` succeeds
- [ ] `terraform validate` succeeds
- [ ] `terraform plan -var-file="dev.tfvars"` succeeds
- [ ] Local state file created (`terraform.tfstate`)
- [ ] 839 resources planned for creation
- [ ] No blocking errors
- [ ] Only informational warnings present

### **Production Migration**
- [ ] S3 backend bucket created
- [ ] DynamoDB lock table created
- [ ] Backend configuration uncommented
- [ ] State successfully migrated to S3
- [ ] Okta SAML configured
- [ ] Client VPN re-enabled and tested
- [ ] EKS cluster deployed and accessible
- [ ] All 1200+ resources deployed
- [ ] Health checks passing

---

## 🆘 Troubleshooting

### **Issue: Circular Dependency Errors**
**Solution**: Ensure all `depends_on` blocks are removed from main.tf. Terraform should resolve dependencies implicitly.

### **Issue: Provider Alias Warnings**
**Solution**: These are informational only. To fix, add `configuration_aliases` to module `versions.tf` files.

### **Issue: State Lock Error**
**Solution**: If using remote backend, ensure DynamoDB table exists and has correct permissions.

### **Issue: Client VPN Validation Error**
**Solution**: Ensure `okta_saml_metadata` is empty string `""` in dev.tfvars for POC, or provide valid SAML XML for full deployment.

---

## 📞 Support

For questions or issues:
1. Check this documentation first
2. Review Terraform plan output carefully
3. Consult AWS documentation for specific services
4. Contact platform engineering team

---

**Last Updated**: 2024-01-XX  
**Terraform Version**: >= 1.5.0  
**AWS Provider Version**: >= 5.0  
