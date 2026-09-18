# Infrastructure Components

## Overview

This document provides a comprehensive inventory of all infrastructure components across the three AWS accounts.

---

## Components

### Networking Account

| Component | Service | Purpose |
|-----------|---------|---------|
| **Route 53** | DNS | Public & Private hosted zones |
| **DNS Firewall** | Security | DNS query filtering |
| **Hub VPC** | Networking | Central connectivity hub |
| **Private Ingress VPC** | Connectivity | Client VPN with Okta SAML |
| **Inspection VPC** | Security | Network Firewall (3 AZs) |
| **Transit Gateway** | Networking | Central routing hub |
| **Site-to-Site VPN** | Connectivity | On-premises connection |

### Workload Account

| Component | Service | Purpose |
|-----------|---------|---------|
| **CloudFront** | CDN | Web & CMS distributions |
| **WAF** | Security | Web application firewall |
| **Shield Advanced** | Security | DDoS protection |
| **API Gateway** | API | Regional REST API |
| **Ingress VPC** | Networking | ALB, NLB, ECS Fargate |
| **Workload VPC** | Compute | EKS, Aurora, MSK |
| **EKS** | Containers | Kubernetes with Istio |
| **Aurora RDS** | Database | PostgreSQL cluster |
| **MSK** | Streaming | Apache Kafka |
| **Cognito** | Identity | User authentication |
| **Data VPC** | Analytics | Glue, Airflow, Lake Formation |

### Shared Services Account

| Component | Service | Purpose |
|-----------|---------|---------|
| **ECR** | Registry | Container image repository |
| **Transfer Family** | File Transfer | SFTP server |
| **Anti-Malware** | Security | File scanning on upload |
| **PostgreSQL** | Database | Shared services database |
| **SES** | Email | Transactional email |
| **SNS** | Messaging | Notifications and alerts |

---

## Prerequisites

### Required Tools

| Tool | Version | Purpose |
|------|---------|---------|
| [Terraform](https://www.terraform.io/downloads) | >= 1.5.0 | Infrastructure provisioning |
| [AWS CLI](https://aws.amazon.com/cli/) | >= 2.0 | AWS authentication |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | >= 1.28 | Kubernetes management |
| [Helm](https://helm.sh/docs/intro/install/) | >= 3.12 | Kubernetes package manager |

### AWS Prerequisites

1. **AWS Accounts** - Three AWS accounts (Networking, Workload, Shared Services)
2. **IAM Roles** - Cross-account Terraform execution roles
3. **S3 Backend** - Terraform state bucket with DynamoDB locking
4. **ACM Certificates** - SSL certificates for domains
5. **Route 53 Hosted Zones** - Public DNS zones

### Required Permissions

The Terraform execution role requires these AWS managed policies:
- `AdministratorAccess` (for initial deployment)
- Or custom policy with least-privilege permissions

---

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/example-org/aws-infrastructure.git
cd aws-infrastructure

aws eks update-kubeconfig \
  --region eu-west-1 \
  --name example-prod-eks \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/PlatformEngineering

Environments
Environment	File	                        Purpose	           Sizing
Development	environments/dev.tfvars	    Feature development   Minimal (SPOT instances)
Staging	environments/staging.tfvars	    QA testing	          Medium
UAT	environments/uat.tfvars	            User acceptance       Production-like
Production	environments/prod.tfvars	Live customers	      Full scale

# Development
terraform apply -var-file="environments/dev.tfvars"

# Staging
terraform apply -var-file="environments/staging.tfvars"

# UAT
terraform apply -var-file="environments/uat.tfvars"

# Production (requires approval)
terraform plan -var-file="environments/prod.tfvars" -out=prod.tfplan
terraform apply prod.tfplan

Environment Comparison
Resource	   Dev	            Staging	         UAT	                Prod
EKS Nodes	t3.medium (SPOT)	m6i.large	   m6i.xlarge	          m6i.xlarge
Aurora	    db.t4g.medium (1)	db.r6g.large (2) db.r6g.large (2)	db.r6g.xlarge (3)
MSK	kafka.t3.small (2)      kafka.m5.large (3)	   kafka.m5.large (3)	kafka.m5.xlarge (3)
Multi-AZ	  No	            Yes	             Yes	  Yes
Deletion Protection	No      	Yes            	Yes	      Yes

---

## External Integrations

### Core Platform Integrations

| Integration | Type | Connection Method | Purpose |
|-------------|------|-------------------|----------|
| **10x** | Core Banking System | Transit Gateway / Egress Gateway | Banking operations |
| **Salesforce** | CRM Platform | Istio Egress Gateway | Customer relationship management |

**Connection Details**:
- Traffic routed through Transit Gateway
- Inspected by Network Firewall
- Authenticated at application layer
- Encrypted with mTLS (when EKS enabled)

---

### Third-Party Services

| Integration | Type | Connection Method | Purpose |
|-------------|------|-------------------|----------|
| **FeatureSpace** | Fraud Detection | Network Firewall | Real-time fraud analysis |
| **Alfresco** | Document Management | Network Firewall | Document storage and retrieval |
| **Comply Advantage** | AML/KYC | Network Firewall | Anti-money laundering checks |
| **Sunpay** | Payment Gateway | Network Firewall | Payment processing |
| **10Tek** | Managed Services | Network Firewall | External service provider |

**Security**:
- All outbound traffic inspected by Network Firewall
- Domain filtering and IPS/IDS rules applied
- TLS 1.2+ encryption enforced
- API authentication required

---

### Connectivity Partners

| Integration | Type | Connection Method | Purpose |
|-------------|------|-------------------|----------|
| **Example Colleagues** | Internal Users | Client VPN (Okta SAML) | Employee remote access |
| **GoAnywhere** | File Transfer | Site-to-Site VPN | Secure file exchange |
| **AWS Transfer Family** | External SFTP | SFTP Endpoint | External partner file transfers |

**Access Controls**:
- **Client VPN**: Multi-factor authentication via Okta (disabled in POC)
- **Site-to-Site VPN**: IPsec tunnel with pre-shared keys
- **SFTP**: SSH key authentication with anti-malware scanning

---

### Monitoring & Identity

| Integration | Type | Connection Method | Purpose |
|-------------|------|-------------------|----------|
| **Dynatrace** | APM/Monitoring | Private Ingress VPC | Application performance monitoring |
| **Okta** | Identity Provider | SAML Federation | Single sign-on and MFA |

**Integration Points**:
- **Dynatrace**: OneAgent deployed on EC2/EKS, data sent via PrivateLink
- **Okta**: SAML 2.0 federation for Client VPN and AWS SSO

---

## Integration Architecture

```
                    INTERNET
                        |
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼
   CloudFront      API Partners    Third Parties
        │               │               │
        ▼               ▼               ▼
  ┌─────────────────────────────────────────┐
  │         NETWORK FIREWALL                │
  │    (Inspection VPC - All Traffic)       │
  └─────────────────┬───────────────────────┘
                    │
                    ▼
            TRANSIT GATEWAY
                    │
    ┌───────────────┼───────────────┐
    │               │               │
    ▼               ▼               ▼
┌────────┐    ┌─────────┐    ┌──────────┐
│Workload│    │Shared   │    │Hub VPC   │
│VPC     │    │Services │    │          │
│        │    │VPC      │    │Site-to-  │
│• EKS   │    │• SFTP   │    │Site VPN  │
│• Aurora│    │• ECR    │    │          │
└────────┘    └─────────┘    └──────────┘
```

---

## Data Flow Examples

### Customer Mobile App → Backend API

```
Mobile App
    ↓ HTTPS
CloudFront (CDN)
    ↓ Origin Request
API Gateway
    ↓ JWT Validation
Cognito (Authentication)
    ↓ Authorized Request
Ingress VPC (ALB)
    ↓ Health Check OK
EKS (Application Pods)
    ↓ Database Query
Aurora PostgreSQL
    ↓ Response
Return to Mobile App
```

### External Partner → SFTP File Upload

```
External Partner
    ↓ SFTP (Port 22)
AWS Transfer Family
    ↓ Anti-Malware Scan
Lambda (File Validation)
    ↓ Clean File
S3 Bucket (Landing Zone)
    ↓ EventBridge Trigger
Data Processing Pipeline
    ↓ Processed
S3 Bucket (Curated)
```

### Internal User → Private Resources

```
Employee Laptop
    ↓ Client VPN (Okta MFA)
Private Ingress VPC
    ↓ Routing
Transit Gateway
    ↓ Network Firewall
Inspection VPC
    ↓ Allowed Traffic
Workload VPC (Private Resources)
```

---

## Component Dependencies

### Critical Path Dependencies

1. **VPC Creation Order**:
   - Hub VPC → Inspection VPC → Transit Gateway → All other VPCs

2. **DNS Dependencies**:
   - Route53 Hosted Zones → Route53 Resolver (Hub VPC) → Private Zones

3. **Network Security**:
   - VPCs → Security Groups → Network Firewall → Transit Gateway Routing

4. **Application Stack**:
   - VPCs → Aurora RDS → EKS → Applications → API Gateway → CloudFront

5. **Data Platform**:
   - Data VPC → S3 → Glue → Airflow (MWAA) → Lake Formation

---

## POC Configuration Notes

### Disabled in POC

| Component | Status | Reason |
|-----------|--------|--------|
| **Client VPN** | ❌ Disabled | Requires Okta SAML configuration |
| **EKS Cluster** | ❌ Disabled | Complex Helm/K8s dependencies |
| **Istio Service Mesh** | ❌ Disabled | Requires EKS |

### Active in POC

| Component | Status | Notes |
|-----------|--------|-------|
| **All VPCs** | ✅ Active | Full networking stack |
| **Transit Gateway** | ✅ Active | Inter-VPC routing |
| **Network Firewall** | ✅ Active | Traffic inspection |
| **Aurora RDS** | ✅ Active | Database clusters |
| **CloudFront + WAF** | ✅ Active | Edge security |
| **API Gateway** | ✅ Active | API management |
| **Data Services** | ✅ Active | Glue, Airflow, MSK |

---

## Monitoring & Observability

### Metrics Collection

| Service | Metrics Source | Destination | Retention |
|---------|----------------|-------------|----------|
| **VPC Flow Logs** | VPC | CloudWatch Logs | 90 days |
| **Network Firewall** | Firewall | CloudWatch/S3 | 90 days |
| **ALB Access Logs** | Load Balancer | S3 | 365 days |
| **CloudFront Logs** | CDN | S3 | 90 days |
| **API Gateway Logs** | API Gateway | CloudWatch | 30 days |
| **RDS Enhanced Monitoring** | Database | CloudWatch | 30 days |
| **EKS Control Plane Logs** | EKS | CloudWatch | 30 days |

### Alerting

- **GuardDuty Findings** → SNS → Security Team
- **Security Hub Findings** → SNS → Platform Team
- **CloudWatch Alarms** → SNS → On-Call Engineer
- **RDS Events** → EventBridge → Lambda → Slack

---

## Cost Considerations

### High-Cost Components (Production)

1. **NAT Gateways**: ~$100-150/month per AZ
2. **Transit Gateway**: ~$50/month + data transfer
3. **Network Firewall**: ~$400-600/month
4. **Aurora RDS**: ~$200-1000/month depending on instance size
5. **EKS Control Plane**: $73/month per cluster
6. **CloudFront**: Usage-based, ~$100-500/month

### Cost Optimization (Dev/POC)

- ✅ SPOT instances for EKS nodes (70% savings)
- ✅ Smaller RDS instances (t4g family)
- ✅ Single AZ deployments where possible
- ✅ VPC Endpoints to reduce NAT Gateway data transfer
- ✅ S3 Intelligent-Tiering for data lake

---

## Related Documentation

- [Network Architecture](Network%20Architecture.md) - Detailed network design
- [Security Architecture](Security%20Architecture.md) - Security controls
- [Data Platform](Data%20Platform.md) - Data processing architecture
- [POC Changes](POC-CHANGES.md) - POC-specific modifications
- [README](README.md) - Main documentation

---

**Last Updated**: 2024-01-XX  
**Maintained by**: Platform Engineering Team