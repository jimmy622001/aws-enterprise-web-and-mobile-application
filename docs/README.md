# AWS Cloud Infrastructure - Enterprise Web and Mobile Architecture

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-623CE4?style=flat&logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-eu--west--1-FF9900?style=flat&logo=amazon-aws)](https://aws.amazon.com/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

Enterprise-grade, multi-account AWS infrastructure for digital banking platform. Built with Terraform following AWS Well-Architected Framework principles.

![Architecture Diagram](architectural-layout.png)

---

## 📑 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
    - [Multi-Account Strategy](#multi-account-strategy)
    - [Network Architecture](#network-architecture)
    - [Security Architecture](#security-architecture)
    - [Data Platform](#data-platform)
- [Components](#components)
- [Environments](#environments)
- [Module Reference](#module-reference)
- [POC Configuration](#poc-configuration)
- [Operations](#operations)
- [Security & Compliance](#security--compliance)

---

## Overview

This repository contains the complete Infrastructure as Code (IaC) for West Brom Building Society's AWS cloud platform. The infrastructure supports:

- 🏦 **Digital Banking Platform** - Customer-facing mobile and web applications
- 🔐 **Secure Connectivity** - VPN access for colleagues and partners
- 📊 **Data Analytics Platform** - Real-time data processing and analytics
- 🔄 **Third-Party Integrations** - Core banking, fraud detection, and payment systems

### Key Features

| Feature | Description |
|---------|-------------|
| **Multi-Account** | Isolated accounts for Networking, Workload, and Shared Services |
| **Zero Trust** | Network segmentation with inspection at every layer |
| **High Availability** | Multi-AZ deployment across 3 Availability Zones |
| **Auto-Scaling** | Dynamic scaling for EKS, ECS, and databases |
| **Compliance Ready** | PCI-DSS, FCA, and GDPR compliance controls |
| **GitOps Ready** | Infrastructure managed entirely through Terraform |
| **POC Ready** | Rapid deployment with local state for testing |

---

## Quick Start

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Terraform](https://www.terraform.io/downloads) | >= 1.5.0 | Infrastructure provisioning |
| [AWS CLI](https://aws.amazon.com/cli/) | >= 2.0 | AWS authentication |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | >= 1.28 | Kubernetes management (when EKS enabled) |
| [Helm](https://helm.sh/docs/intro/install/) | >= 3.12 | Kubernetes package manager (when EKS enabled) |

### POC Deployment (Local State)

**Using Terraform Workspaces** (Recommended ⭐)

```powershell
# 1. Initialize Terraform
terraform init

# 2. Create POC workspace
.\workspace-manager.ps1 -Action create -Workspace poc

# 3. Plan POC deployment (Client VPN and EKS disabled)
.\workspace-manager.ps1 -Action plan -Workspace poc

# 4. Review the plan

# 5. Apply POC configuration
.\workspace-manager.ps1 -Action apply -Workspace poc
```

**Manual Workspace Method**

```bash
# 1. Initialize Terraform
terraform init

# 2. Create POC workspace
terraform workspace new poc

# 3. Plan deployment
terraform plan -var-file="poc.tfvars" -out=tfplan-poc

# 4. Apply
terraform apply tfplan-poc
```

📚 **See [WORKSPACE-GUIDE.md](WORKSPACE-GUIDE.md) for complete workspace documentation.**  
⚡ **See [QUICK-REFERENCE.md](../QUICK-REFERENCE.md) for daily command reference.**

**Alternative: Legacy POC Deployment (Commented Code)**

```bash
# 1. Clone the repository
git clone https://github.com/yourorg/aws-infrastructure.git
cd aws-infrastructure

# 2. Configure AWS credentials
export AWS_PROFILE=your-profile
# or
aws configure

# 3. Initialize Terraform
terraform init

# 4. Validate configuration
terraform validate

# 5. Plan deployment using dev environment
terraform plan -var-file="environments/dev.tfvars"

# 6. Apply infrastructure
terraform apply -var-file="environments/dev.tfvars"
```

**Deployment Time**: ~30-45 minutes  
**Resources Created**: 839 (POC configuration with Client VPN and EKS disabled)

> 💡 **Note**: For POC changes and how to re-enable production features, see [POC-CHANGES.md](POC-CHANGES.md)

### Production Deployment (Remote State)

```bash
# 1. Create S3 backend
aws s3 mb s3://your-terraform-state-bucket --region eu-west-1

# 2. Create DynamoDB lock table
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region eu-west-1

# 3. Uncomment backend configuration in providers.tf
# 4. Initialize with backend
terraform init

# 5. Deploy production
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
terraform apply prod.tfplan
```

---

## Architecture

### Multi-Account Strategy

The infrastructure follows AWS multi-account best practices with three primary accounts:

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS ORGANIZATION ROOT                        │
└─────────────────────────┬───────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼────────┐ ┌─────▼──────┐ ┌───────▼────────┐
│   NETWORKING   │ │  WORKLOAD  │ │ SHARED SERVICES│
│    ACCOUNT     │ │  ACCOUNT   │ │    ACCOUNT     │
│                │ │            │ │                │
│ • Hub VPC      │ │ • EKS      │ │ • ECR          │
│ • Transit GW   │ │ • Aurora   │ │ • SFTP         │
│ • Inspection   │ │ • MSK      │ │ • PostgreSQL   │
│ • Client VPN   │ │ • Lambda   │ │ • SES          │
│ • Route53      │ │ • API GW   │ │ • Anti-Malware │
└────────────────┘ └────────────┘ └────────────────┘
```

**See detailed documentation**: [Network Architecture](Network%20Architecture.md)

### Network Flow

```
Internet
   │
   ▼
┌─────────────────┐
│   CloudFront    │ ◄── Global Edge Locations
│      + WAF      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Ingress VPC    │ ◄── ALB, NLB, ECS Fargate
│  (10.11.0.0/16) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Inspection VPC  │ ◄── Network Firewall (All Traffic)
│  (10.2.0.0/16)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Transit Gateway │ ◄── Central Routing Hub
└────────┬────────┘
         │
    ┌────┴────┬────────────┬──────────┐
    ▼         ▼            ▼          ▼
┌────────┐ ┌──────┐  ┌─────────┐ ┌────────┐
│Hub VPC │ │Work  │  │Data VPC │ │Shared  │
│        │ │load  │  │         │ │Services│
│EKS     │ │VPC   │  │Airflow  │ │ECR     │
│Aurora  │ │      │  │Glue     │ │SFTP    │
└────────┘ └──────┘  └─────────┘ └────────┘
```

---

## Components

For a complete list of all infrastructure components, see [Components.md](Components.md)

### Networking Account
- **Route 53** - DNS management (public & private zones)
- **Transit Gateway** - Central routing hub
- **Hub VPC** - NAT Gateway, DNS resolver endpoints
- **Inspection VPC** - AWS Network Firewall (stateful inspection)
- **Private Ingress VPC** - Client VPN with Okta SAML (disabled in POC)
- **DNS Firewall** - Domain filtering and threat protection

### Workload Account
- **CloudFront + WAF** - Global CDN with DDoS protection
- **API Gateway** - REST API with throttling
- **EKS** - Kubernetes cluster with Istio service mesh (disabled in POC)
- **Aurora PostgreSQL** - Multi-AZ database cluster
- **MSK** - Managed Apache Kafka
- **Cognito** - User authentication with MFA
- **Ingress VPC** - Application Load Balancers
- **Workload VPC** - Application workloads
- **Data VPC** - Glue, Airflow (MWAA), Lake Formation

### Shared Services Account
- **ECR** - Container registry
- **Transfer Family** - SFTP server with anti-malware scanning
- **Aurora PostgreSQL** - Shared database
- **SES** - Email sending service
- **SNS** - Notifications and alerts

---

## Environments

| Environment | File | Purpose | Sizing | Resources |
|-------------|------|---------|--------|----------|
| **Development** | `environments/dev.tfvars` | Feature development | Minimal (SPOT) | ~850 |
| **Staging** | `environments/staging.tfvars` | QA testing | Medium | ~1000 |
| **UAT** | `environments/uat.tfvars` | User acceptance | Production-like | ~1100 |
| **Production** | `environments/prod.tfvars` | Live customers | Full scale | ~1200 |

### Environment Comparison

| Resource | Dev | Staging | UAT | Prod |
|----------|-----|---------|-----|------|
| **EKS Nodes** | t3.medium (SPOT) | m6i.large | m6i.xlarge | m6i.xlarge |
| **Aurora** | db.t4g.medium (1) | db.r6g.large (2) | db.r6g.large (2) | db.r6g.xlarge (3) |
| **MSK** | kafka.t3.small (2) | kafka.m5.large (3) | kafka.m5.large (3) | kafka.m5.xlarge (3) |
| **Multi-AZ** | No | Yes | Yes | Yes |
| **Deletion Protection** | No | Yes | Yes | Yes |
| **Backup Retention** | 7 days | 14 days | 30 days | 30 days |

### Deploying to Specific Environment

```bash
# Development
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Staging
terraform plan -var-file="environments/staging.tfvars"
terraform apply -var-file="environments/staging.tfvars"

# UAT
terraform plan -var-file="environments/uat.tfvars"
terraform apply -var-file="environments/uat.tfvars"

# Production (requires approval)
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
# Review plan carefully
terraform apply prod.tfplan
```

---

## Module Reference

See [directory structure.md](directory%20structure.md) for complete module organization.

```
modules/
├── networking-dns/          # Route 53, DNS Firewall
├── hub-vpc/                 # Hub VPC, NAT, Route53 Resolver
├── private-ingress-vpc/     # Client VPN (Okta SAML)
├── inspection-vpc/          # Network Firewall
├── transit-gateway/         # Transit Gateway, Site-to-Site VPN
├── workload-vpc/            # EKS, Aurora, MSK, Cognito
├── ingress-vpc/             # ALB, NLB, ECS Fargate
├── data-vpc/                # Glue, Airflow, Lake Formation
├── cloudfront-waf/          # CloudFront, WAF, Shield, API Gateway
├── eks/                     # EKS cluster, Istio, IRSA
├── shared-services/         # ECR, Transfer Family, SES
└── security/                # GuardDuty, Security Hub, CloudTrail
```

---

## POC Configuration

**📖 Full details**: [POC-CHANGES.md](POC-CHANGES.md)

### What's Disabled in POC

| Component | Reason | Impact |
|-----------|--------|--------|
| **Client VPN** | Requires Okta SAML metadata | No VPN access (use Session Manager) |
| **EKS Module** | Complex Kubernetes/Helm dependencies | No K8s cluster |
| **Remote Backend** | S3/DynamoDB not required for testing | Local state file |

### Re-enabling Production Features

```bash
# 1. Enable remote backend
# Uncomment backend block in providers.tf
terraform init -migrate-state

# 2. Enable Client VPN
# Add Okta SAML metadata to dev.tfvars
# Uncomment Client VPN resources in Modules/private-ingress-vpc/
terraform apply -var-file="environments/dev.tfvars"

# 3. Enable EKS
# Uncomment EKS module in main.tf
# Uncomment Kubernetes/Helm providers in providers.tf
terraform apply -var-file="environments/dev.tfvars"
```

---

## Operations

### Accessing EKS Cluster (when enabled)

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region eu-west-1 \
  --name example-prod-eks \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/PlatformEngineering

# Verify access
kubectl get nodes
```

### Connecting to RDS Aurora

```bash
# Via bastion host or Systems Manager Session Manager
psql -h <aurora-cluster-endpoint> \
     -U postgres \
     -d myapp
```

### Viewing Logs

```bash
# VPC Flow Logs
aws logs tail /aws/vpc/flowlogs/hub-vpc --follow

# Network Firewall Logs
aws logs tail /aws/networkfirewall/inspection-vpc --follow

# API Gateway Logs
aws logs tail /aws/apigateway/example-api --follow
```

### State Management

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show module.hub_vpc.aws_vpc.main

# Remove resource from state (careful!)
terraform state rm module.hub_vpc.aws_vpc.main

# Import existing resource
terraform import module.hub_vpc.aws_vpc.main vpc-xxxxx
```

---

## Security & Compliance

**📖 Full details**: [Security Architecture.md](Security%20Architecture.md)

### Compliance Frameworks

| Framework | Status | Automation |
|-----------|--------|------------|
| **PCI-DSS** | ✅ Enabled | Security Hub Standard |
| **CIS Benchmark** | ✅ Enabled | Security Hub Standard |
| **AWS Foundational** | ✅ Enabled | Security Hub Standard |
| **NIST 800-53** | ✅ Enabled | Security Hub Standard |
| **GDPR** | ✅ Implemented | Encryption, Access Controls |
| **FCA** | ✅ Implemented | Audit Logging, Data Protection |

### Defense in Depth Layers

1. **Edge Security**: CloudFront, WAF, Shield Advanced
2. **Network Security**: Network Firewall, Security Groups, NACLs
3. **Application Security**: Istio mTLS, API Gateway, Cognito MFA
4. **Data Security**: KMS encryption, TLS 1.2+, Secrets Manager
5. **Monitoring**: GuardDuty, Security Hub, CloudTrail, Config

---

## Troubleshooting

### Common Issues

#### Circular Dependency Errors
```bash
# Remove explicit depends_on blocks
# Terraform will resolve dependencies implicitly
```

#### Provider Alias Warnings
```bash
# These are informational only
# Can be fixed by adding configuration_aliases to module versions.tf
```

#### State Lock Errors
```bash
# Force unlock (use carefully)
terraform force-unlock <LOCK_ID>
```

#### Client VPN Validation Error
```bash
# For POC, ensure okta_saml_metadata is empty string in dev.tfvars
okta_saml_metadata = ""
```

---

## Cost Optimization

### Development Environment
- ✅ Use SPOT instances for EKS nodes
- ✅ Smaller RDS instances (t4g family)
- ✅ Single AZ deployments
- ✅ Reduced backup retention (7 days)
- ✅ No deletion protection

### Production Environment
- ✅ Savings Plans for EKS compute
- ✅ Aurora I/O-Optimized for high throughput
- ✅ VPC Endpoints to reduce data transfer costs
- ✅ S3 Intelligent-Tiering
- ✅ CloudWatch Logs retention policies

---

## Contributing

### Terraform Standards
- Use `terraform fmt` before committing
- Run `terraform validate` before pushing
- Update documentation when adding modules
- Follow naming conventions: `<resource>-<environment>-<purpose>`

### Pull Request Process
1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes and test locally
3. Run validation: `terraform validate`
4. Create PR with detailed description
5. Wait for approval from platform team
6. Merge after successful review

---

## Additional Documentation

- **[POC Changes](POC-CHANGES.md)** - POC-specific modifications and migration path
- **[Components](Components.md)** - Complete component inventory
- **[Network Architecture](Network%20Architecture.md)** - VPC layout and routing
- **[Security Architecture](Security%20Architecture.md)** - Security controls and compliance
- **[Data Platform](Data%20Platform.md)** - Data processing architecture
- **[Directory Structure](directory%20structure.md)** - Repository organization

---

## Support

For issues or questions:
1. Check this documentation
2. Review [POC-CHANGES.md](POC-CHANGES.md) for POC-specific guidance
3. Consult AWS documentation
4. Contact Platform Engineering team

---

**Last Updated**: 2024-01-XX  
**Terraform Version**: >= 1.5.0  
**AWS Provider Version**: >= 5.0  
**Maintained by**: Platform Engineering Team