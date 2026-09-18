# AWS Solutions Architect Assessment - Single Region, 3-AZ Architecture

## Executive Summary

This document presents a production-grade AWS architecture designed for a core banking system operating in a single region (Ireland - eu-west-1) with 3 Availability Zones. The architecture implements defense-in-depth security, high availability, and operational excellence following AWS Well-Architected Framework principles.

**Key Metrics:**
- **Region**: eu-west-1 (Ireland)
- **Availability Zones**: 3 (eu-west-1a, eu-west-1b, eu-west-1c)
- **VPCs**: 7 (segregated by function)
- **Resources**: ~600+ AWS resources
- **RTO**: < 10 minutes
- **RPO**: < 1 second
- **Estimated Monthly Cost**: $3,000-5,000 (Production)

---

## Architecture Overview

### High-Level Design

```
┌─────────────────────────────────────────────────────────────────┐
│                    EDGE SECURITY LAYER                          │
│  CloudFront + WAF + Shield Advanced (DDoS Protection)           │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                  INGRESS LAYER (3 AZs)                          │
│  • ALB (Application Load Balancer)                              │
│  • NLB (Network Load Balancer)                                  │
│  • API Gateway                                                  │
│  • Cognito (User Authentication)                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│              NETWORK FIREWALL (Inspection VPC)                  │
│  • Stateful inspection of all traffic                           │
│  • IPS/IDS rules (Suricata)                                     │
│  • Domain filtering                                             │
│  • Protocol detection                                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                  WORKLOAD LAYER (3 AZs)                         │
│  • EKS Cluster (Kubernetes)                                     │
│  • Istio Service Mesh (mTLS)                                    │
│  • Lambda Functions                                             │
│  • Fargate Containers                                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                   DATA LAYER (3 AZs)                            │
│  • Aurora PostgreSQL (Multi-AZ)                                 │
│  • MSK Kafka (3 brokers)                                        │
│  • ElastiCache Redis                                            │
│  • S3 Data Lake                                                 │
│  • Redshift (Analytics)                                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## VPC Architecture & Segregation

### VPC Design Principles

The architecture uses **7 segregated VPCs** organized by function and security boundary:

1. **Hub VPC** - Central connectivity and routing
2. **Inspection VPC** - Network security and traffic inspection
3. **Private Ingress VPC** - Remote access (Client VPN)
4. **Ingress VPC** - Public-facing load balancers
5. **Workload VPC** - Application compute and databases
6. **Data VPC** - Analytics and data processing
7. **Shared Services VPC** - Container registry and shared tools

### VPC Layout (Single Region, 3 AZs)

```
REGION: eu-west-1 (Ireland)
├── AZ-1: eu-west-1a
├── AZ-2: eu-west-1b
└── AZ-3: eu-west-1c

VPC SEGREGATION:
│
├── HUB VPC (10.0.0.0/16)
│   ├── AZ-1a: 10.0.1.0/24 (Public - NAT Gateway)
│   ├── AZ-1b: 10.0.2.0/24 (Public - NAT Gateway)
│   ├── AZ-1c: 10.0.3.0/24 (Public - NAT Gateway)
│   ├── AZ-1a: 10.0.11.0/24 (Private - Route 53 Resolver)
│   ├── AZ-1b: 10.0.12.0/24 (Private - Route 53 Resolver)
│   └── AZ-1c: 10.0.13.0/24 (Private - Route 53 Resolver)
│
├── INSPECTION VPC (10.2.0.0/16)
│   ├── AZ-1a: 10.2.1.0/24 (Network Firewall)
│   ├── AZ-1b: 10.2.2.0/24 (Network Firewall)
│   └── AZ-1c: 10.2.3.0/24 (Network Firewall)
│
├── PRIVATE INGRESS VPC (10.1.0.0/16)
│   ├── AZ-1a: 10.1.1.0/24 (Client VPN)
│   ├── AZ-1b: 10.1.2.0/24 (Client VPN)
│   └── AZ-1c: 10.1.3.0/24 (Client VPN)
│
├── INGRESS VPC (10.11.0.0/16)
│   ├── AZ-1a: 10.11.1.0/24 (ALB/NLB)
│   ├── AZ-1b: 10.11.2.0/24 (ALB/NLB)
│   └── AZ-1c: 10.11.3.0/24 (ALB/NLB)
│
├── WORKLOAD VPC (10.10.0.0/16)
│   ├── AZ-1a: 10.10.1.0/24 (EKS Node Group 1)
│   ├── AZ-1b: 10.10.2.0/24 (EKS Node Group 2)
│   ├── AZ-1c: 10.10.3.0/24 (EKS Node Group 3)
│   ├── AZ-1a: 10.10.11.0/24 (RDS Aurora)
│   ├── AZ-1b: 10.10.12.0/24 (RDS Aurora)
│   └── AZ-1c: 10.10.13.0/24 (RDS Aurora)
│
├── DATA VPC (10.12.0.0/16)
│   ├── AZ-1a: 10.12.1.0/24 (Glue, Airflow)
│   ├── AZ-1b: 10.12.2.0/24 (Glue, Airflow)
│   ├── AZ-1c: 10.12.3.0/24 (Glue, Airflow)
│   └── Shared: S3 Data Lake (Regional)
│
└── SHARED SERVICES VPC (10.20.0.0/16)
    ├── AZ-1a: 10.20.1.0/24 (ECR, Transfer Family)
    ├── AZ-1b: 10.20.2.0/24 (ECR, Transfer Family)
    └── AZ-1c: 10.20.3.0/24 (ECR, Transfer Family)
```

### VPC Connectivity

```
┌─────────────────────────────────────────────────────────────┐
│                    TRANSIT GATEWAY                          │
│              (Central Routing Hub - 3 AZs)                  │
└────────┬────────────┬────────────┬────────────┬─────────────┘
         │            │            │            │
    ┌────▼──┐    ┌───▼───┐   ┌───▼───┐   ┌───▼────┐
    │  Hub  │    │Inspect│   │Workld │   │ Data   │
    │ VPC   │    │ VPC   │   │ VPC   │   │ VPC    │
    └───────┘    └───────┘   └───────┘   └────────┘
         │            │            │            │
         └────────────┼────────────┴────────────┘
                      │
              ┌───────▼────────┐
              │ Network        │
              │ Firewall       │
              │ (Inspection)   │
              └────────────────┘
```

---

## Security Architecture

### Defense in Depth (5 Layers)

#### Layer 1: Edge Security
- **CloudFront**: Global CDN with TLS 1.3
- **AWS WAF**: Web Application Firewall with managed rules
- **AWS Shield Advanced**: DDoS protection (Layer 3/4)

#### Layer 2: Network Security
- **Network Firewall**: Stateful inspection in Inspection VPC
- **Security Groups**: Micro-segmentation at application level
- **Network ACLs**: Subnet-level filtering

#### Layer 3: Application Security
- **Istio Service Mesh**: mTLS between all microservices
- **API Gateway**: JWT validation, OAuth 2.0
- **Cognito**: User authentication with MFA

#### Layer 4: Data Security
- **KMS Encryption**: All data at rest encrypted
- **TLS 1.2+**: All data in transit encrypted
- **Secrets Manager**: Automatic credential rotation
- **Private CA**: Internal certificate authority

#### Layer 5: Monitoring & Detection
- **GuardDuty**: Threat detection with ML
- **Security Hub**: Compliance monitoring (PCI-DSS, CIS, NIST)
- **CloudTrail**: Complete audit logging
- **Config**: Configuration compliance tracking

### Compliance Frameworks

| Framework | Status | Coverage |
|-----------|--------|----------|
| **PCI-DSS** | ✅ Enabled | Card data protection |
| **CIS Benchmark** | ✅ Enabled | Infrastructure hardening |
| **AWS Foundational** | ✅ Enabled | AWS best practices |
| **NIST 800-53** | ✅ Enabled | Federal compliance |
| **GDPR** | ✅ Implemented | Data privacy |
| **FCA** | ✅ Implemented | Financial services |

---

## Compute Architecture

### EKS Cluster (Kubernetes)

**Configuration:**
- **Cluster Name**: example-prod-eks
- **Kubernetes Version**: 1.28+
- **Node Groups**: 3 (one per AZ)
- **Instance Type**: m6i.xlarge (Production)
- **Auto-scaling**: 3-10 nodes per AZ
- **Total Capacity**: 9-30 nodes across 3 AZs

**Node Group Distribution:**
```
AZ-1a: 3-10 nodes (m6i.xlarge)
AZ-1b: 3-10 nodes (m6i.xlarge)
AZ-1c: 3-10 nodes (m6i.xlarge)
```

**Service Mesh:**
- **Istio**: Automatic mTLS between services
- **Certificate Rotation**: Automatic (30 days)
- **Traffic Management**: Canary deployments, circuit breakers
- **Observability**: Distributed tracing, metrics collection

### Lambda Functions

- **100+ Functions**: Event-driven compute
- **Concurrency**: Auto-scaling (reserved concurrency for critical functions)
- **Timeout**: 15 minutes (default)
- **Memory**: 128MB - 10GB (optimized per function)
- **VPC Integration**: Private subnet access

### Fargate Containers

- **ECS Fargate**: Serverless container orchestration
- **NGINX Ingress**: Load balancing for EKS
- **Task Definition**: Auto-scaling based on CPU/memory

---

## Data Architecture

### Aurora PostgreSQL (Multi-AZ)

**Configuration:**
- **Engine**: PostgreSQL 15+
- **Instance Type**: db.r6g.xlarge (Production)
- **Multi-AZ**: 3 instances (1 writer + 2 read replicas)
- **Storage**: 1TB (auto-scaling)
- **Backup Retention**: 30 days
- **Encryption**: KMS (customer-managed keys)

**High Availability:**
```
Primary (AZ-1a) ──┐
                  ├─ Synchronous Replication
Read Replica (AZ-1b) ──┐
                       ├─ Asynchronous Replication
Read Replica (AZ-1c) ──┘
```

**Failover:**
- **Automatic Failover**: < 30 seconds
- **RTO**: < 1 minute
- **RPO**: < 1 second

### MSK Kafka (3 Brokers)

**Configuration:**
- **Brokers**: 3 (one per AZ)
- **Instance Type**: kafka.m5.large
- **Storage**: 1TB per broker
- **Replication Factor**: 3
- **Encryption**: TLS + KMS

**Topics:**
- Event streaming for real-time processing
- Data pipeline orchestration
- Application logging

### ElastiCache Redis

**Configuration:**
- **Engine**: Redis 7.0+
- **Node Type**: cache.r6g.xlarge
- **Multi-AZ**: Automatic failover
- **Encryption**: TLS + KMS
- **Eviction Policy**: allkeys-lru

**Use Cases:**
- Session management
- Real-time caching
- Rate limiting

### S3 Data Lake

**Configuration:**
- **Buckets**: Multiple (landing, curated, archive)
- **Encryption**: KMS (customer-managed keys)
- **Versioning**: Enabled
- **Lifecycle Policies**: Automatic archival to Glacier
- **Access Logging**: All access logged to separate bucket

**Data Organization:**
```
s3://data-lake-prod/
├── landing/          (Raw data ingestion)
├── curated/          (Processed data)
├── archive/          (Historical data)
└── metadata/         (Data catalog)
```

### Redshift (Analytics)

**Configuration:**
- **Cluster Type**: Dense Compute (dc2.large)
- **Nodes**: 3 (one per AZ)
- **Storage**: 160GB per node (480GB total)
- **Encryption**: KMS
- **Backup Retention**: 30 days

---

## Networking & Connectivity

### Internet Connectivity

**Egress Path:**
```
Application (Private Subnet)
    ↓
NAT Gateway (Hub VPC - Public Subnet)
    ↓
Internet Gateway
    ↓
Internet
```

**NAT Gateway Configuration:**
- **Count**: 3 (one per AZ for high availability)
- **Location**: Hub VPC public subnets
- **Elastic IP**: Static IP per NAT Gateway
- **Data Transfer**: ~$0.045 per GB

### VPC Endpoints (PrivateLink)

**Gateway Endpoints:**
- S3 (no data transfer charges)
- DynamoDB (no data transfer charges)

**Interface Endpoints:**
- EC2, ECS, SNS, SQS, Secrets Manager, KMS
- Reduces data transfer costs
- Improves security (no internet exposure)

### Route 53 DNS

**Hosted Zones:**
- **Public Zone**: example.com (external DNS)
- **Private Zone**: internal.example.com (internal DNS)

**Health Checks:**
- Endpoint health checks (HTTP/HTTPS)
- CloudWatch alarm-based checks
- Calculated health checks

**Routing Policies:**
- Weighted routing (A/B testing)
- Latency-based routing (multi-region ready)
- Failover routing (active-passive)

---

## Monitoring & Observability

### CloudWatch

**Metrics:**
- Application metrics (custom)
- Infrastructure metrics (CPU, memory, disk)
- Network metrics (throughput, latency)
- Database metrics (connections, queries)

**Logs:**
- Application logs (CloudWatch Logs)
- VPC Flow Logs (network traffic)
- Network Firewall logs (security events)
- CloudTrail logs (API calls)

**Dashboards:**
- Executive dashboard (high-level metrics)
- Operations dashboard (real-time alerts)
- Security dashboard (threat detection)
- Cost dashboard (spending trends)

### X-Ray Distributed Tracing

- End-to-end request tracing
- Service dependency mapping
- Performance bottleneck identification
- Error analysis

### GuardDuty Threat Detection

- Malicious IP detection
- Compromised instance detection
- Suspicious API calls
- Cryptocurrency mining detection

---

## Cost Optimization

### Production Monthly Cost Breakdown

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| **EKS Control Plane** | $73 | Fixed cost per cluster |
| **EKS Nodes** | $800-1,200 | 9-30 m6i.xlarge instances |
| **Aurora RDS** | $400-600 | 3 db.r6g.xlarge instances |
| **MSK Kafka** | $300-400 | 3 kafka.m5.large brokers |
| **NAT Gateways** | $150-200 | 3 NAT Gateways + data transfer |
| **Network Firewall** | $400-600 | Firewall + data processing |
| **ElastiCache** | $200-300 | cache.r6g.xlarge |
| **Redshift** | $300-400 | 3 dc2.large nodes |
| **CloudFront** | $100-200 | CDN data transfer |
| **Data Transfer** | $200-300 | Inter-region, internet egress |
| **Storage (S3, EBS)** | $200-300 | Data lake + backups |
| **Other Services** | $200-300 | Lambda, API Gateway, etc. |
| **TOTAL** | **$3,000-5,000** | Production environment |

### Cost Optimization Strategies

1. **Reserved Instances**: 30-40% savings on compute
2. **Savings Plans**: 20-30% savings on EKS/RDS
3. **SPOT Instances**: 70% savings for non-critical workloads
4. **S3 Intelligent-Tiering**: Automatic cost optimization
5. **VPC Endpoints**: Reduce NAT Gateway data transfer
6. **Scheduled Scaling**: Scale down non-production during off-hours

---

## High Availability & Disaster Recovery

### Availability Zones

**Multi-AZ Deployment:**
- All critical components deployed across 3 AZs
- Automatic failover between AZs
- No single point of failure

**Component Distribution:**
```
AZ-1a: EKS Node Group 1, Aurora Primary, MSK Broker 1
AZ-1b: EKS Node Group 2, Aurora Replica, MSK Broker 2
AZ-1c: EKS Node Group 3, Aurora Replica, MSK Broker 3
```

### RTO & RPO Targets

| Component | RTO | RPO | Method |
|-----------|-----|-----|--------|
| **EKS Cluster** | 5 min | 0 | Auto-scaling + health checks |
| **Aurora RDS** | 1 min | < 1 sec | Automatic failover |
| **MSK Kafka** | 2 min | 0 | Broker replication |
| **Application** | 5 min | 0 | Multi-AZ deployment |
| **Data** | 30 min | < 1 sec | Automated backups |

### Backup Strategy

**Automated Backups:**
- Aurora: Continuous backup (30-day retention)
- RDS: Daily snapshots (30-day retention)
- S3: Versioning enabled
- EBS: Daily snapshots (30-day retention)

**Backup Locations:**
- Primary: eu-west-1 (Ireland)
- Cross-region: eu-west-2 (London) for critical data

---

## Operational Excellence

### Infrastructure as Code (Terraform)

**Repository Structure:**
```
terraform/
├── main.tf                 # Core infrastructure
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── providers.tf            # Provider configuration
│
├── Modules/
│   ├── hub-vpc/            # Hub VPC module
│   ├── inspection-vpc/      # Inspection VPC module
│   ├── workload-vpc/        # Workload VPC module
│   ├── eks/                 # EKS cluster module
│   ├── rds/                 # Aurora RDS module
│   └── ...
│
├── environments/
│   ├── dev.tfvars           # Development config
│   ├── staging.tfvars       # Staging config
│   ├── uat.tfvars           # UAT config
│   └── prod.tfvars          # Production config
│
└── terraform.tfstate.d/     # State files (per workspace)
    ├── dev/
    ├── staging/
    ├── uat/
    └── prod/
```

**Workspace Strategy:**
- Separate workspaces for each environment
- Isolated state files per environment
- Feature flags for conditional deployment
- Environment-specific tfvars files

### CI/CD Pipeline

**Deployment Process:**
1. **Plan**: `terraform plan -var-file=prod.tfvars`
2. **Review**: Manual approval required for production
3. **Apply**: `terraform apply prod.tfplan`
4. **Validate**: Automated tests post-deployment

**Approval Gates:**
- Development: Automatic
- Staging: Team lead approval
- UAT: QA approval
- Production: Architecture + Security approval

### Runbooks & Documentation

**Key Runbooks:**
- Cluster scaling procedures
- Database failover procedures
- Network troubleshooting
- Security incident response
- Backup and recovery procedures

---

## Well-Architected Framework Alignment

### Operational Excellence
- ✅ Infrastructure as Code (Terraform)
- ✅ Automated deployments (CI/CD)
- ✅ Comprehensive monitoring (CloudWatch, X-Ray)
- ✅ Runbooks and documentation
- ✅ Regular backup testing

### Security
- ✅ Defense in depth (5 layers)
- ✅ Encryption at rest and in transit
- ✅ Network segmentation (7 VPCs)
- ✅ Compliance monitoring (Security Hub)
- ✅ Audit logging (CloudTrail)

### Reliability
- ✅ Multi-AZ deployment (3 AZs)
- ✅ Automatic failover (< 1 minute)
- ✅ Health checks and auto-scaling
- ✅ Backup and recovery procedures
- ✅ RTO < 10 min, RPO < 1 sec

### Performance Efficiency
- ✅ Right-sized instances (m6i, r6g families)
- ✅ Auto-scaling based on demand
- ✅ Caching (ElastiCache Redis)
- ✅ CDN (CloudFront)
- ✅ Database optimization (Aurora)

### Cost Optimization
- ✅ Reserved Instances (30-40% savings)
- ✅ Savings Plans (20-30% savings)
- ✅ SPOT instances for non-critical workloads
- ✅ S3 Intelligent-Tiering
- ✅ VPC Endpoints (reduce data transfer)

---

## Assessment Talking Points

### 1. Architecture Design
- **Question**: "How does your architecture handle high availability?"
- **Answer**: Multi-AZ deployment across 3 AZs with automatic failover, RTO < 1 minute for databases, RTO < 5 minutes for applications

### 2. Security Posture
- **Question**: "What security controls are in place?"
- **Answer**: Defense-in-depth with 5 layers (edge, network, application, data, monitoring), compliance with PCI-DSS, CIS, NIST, encryption everywhere

### 3. Network Segregation
- **Question**: "How do you isolate workloads?"
- **Answer**: 7 segregated VPCs by function, Transit Gateway for controlled connectivity, Network Firewall for inspection, Security Groups for micro-segmentation

### 4. Cost Management
- **Question**: "How do you optimize costs?"
- **Answer**: Reserved Instances, Savings Plans, SPOT instances, S3 Intelligent-Tiering, VPC Endpoints, estimated $3-5K/month for production

### 5. Operational Readiness
- **Question**: "How do you manage infrastructure?"
- **Answer**: Infrastructure as Code (Terraform), Workspaces for environment isolation, CI/CD pipeline with approval gates, comprehensive monitoring and alerting

### 6. Compliance & Governance
- **Question**: "How do you ensure compliance?"
- **Answer**: Security Hub for automated compliance checks, CloudTrail for audit logging, Config for configuration tracking, regular security assessments

### 7. Disaster Recovery
- **Question**: "What's your DR strategy?"
- **Answer**: Single region with 3 AZs (RTO < 10 min, RPO < 1 sec), automated backups with 30-day retention, cross-region backup replication

---

## Key Differentiators

### Why This Architecture?

1. **Banking-Grade Security**: Defense-in-depth, compliance-ready, audit trails
2. **High Availability**: Multi-AZ, automatic failover, < 1 minute RTO
3. **Scalability**: Auto-scaling EKS, Aurora, MSK across 3 AZs
4. **Cost Efficiency**: $3-5K/month for production, optimization strategies
5. **Operational Excellence**: IaC, CI/CD, comprehensive monitoring
6. **Compliance Ready**: PCI-DSS, CIS, NIST, GDPR, FCA

---

## Next Steps for Assessment

### Preparation
1. Review this document thoroughly
2. Understand each VPC's purpose and connectivity
3. Be ready to explain security layers
4. Know the cost breakdown
5. Understand failover procedures

### During Assessment
1. Start with high-level architecture overview
2. Drill down into specific areas as asked
3. Use diagrams to explain VPC segregation
4. Discuss trade-offs (security vs. cost, complexity vs. reliability)
5. Relate to AWS Well-Architected Framework

### Key Metrics to Remember
- **3 AZs**: High availability
- **7 VPCs**: Security segregation
- **600+ Resources**: Comprehensive infrastructure
- **$3-5K/month**: Production cost
- **< 1 min RTO**: Database failover
- **< 5 min RTO**: Application failover
- **PCI-DSS, CIS, NIST**: Compliance frameworks

---

## Related Documentation

- [Network Architecture](Network%20Architecture.md) - Detailed network design
- [Security Architecture](Security%20Architecture.md) - Security controls
- [Components](Components.md) - Complete component inventory
- [Data Platform](Data%20Platform.md) - Data processing architecture
- [DISASTER-RECOVERY.md](DISASTER-RECOVERY.md) - DR procedures

---

**Document Version**: 1.0  
**Last Updated**: April 2026  
**Prepared for**: AWS Solutions Architect Assessment  
**Architecture**: Single Region (eu-west-1), 3 AZs, 7 VPCs, Banking-Grade Security
