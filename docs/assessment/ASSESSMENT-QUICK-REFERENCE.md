# AWS Solutions Architect Assessment - Quick Reference Guide

## One-Page Architecture Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SINGLE REGION, 3-AZ ARCHITECTURE                 │
│                         eu-west-1 (Ireland)                         │
└─────────────────────────────────────────────────────────────────────┘

EDGE LAYER:
  CloudFront + WAF + Shield Advanced
  ↓
INGRESS LAYER (3 AZs):
  ALB | NLB | API Gateway | Cognito
  ↓
NETWORK FIREWALL (Inspection VPC):
  Stateful inspection, IPS/IDS, Domain filtering
  ↓
WORKLOAD LAYER (3 AZs):
  EKS (Kubernetes) | Lambda | Fargate | Istio mTLS
  ↓
DATA LAYER (3 AZs):
  Aurora PostgreSQL | MSK Kafka | ElastiCache | S3 | Redshift
```

---

## VPC Segregation at a Glance

| VPC | CIDR | Purpose | AZs | Key Services |
|-----|------|---------|-----|--------------|
| **Hub** | 10.0.0.0/16 | Central routing, NAT | 3 | Route 53, NAT GW |
| **Inspection** | 10.2.0.0/16 | Traffic inspection | 3 | Network Firewall |
| **Private Ingress** | 10.1.0.0/16 | Remote access | 3 | Client VPN |
| **Ingress** | 10.11.0.0/16 | Public entry | 3 | ALB, NLB, API GW |
| **Workload** | 10.10.0.0/16 | Applications | 3 | EKS, Aurora, MSK |
| **Data** | 10.12.0.0/16 | Analytics | 3 | Glue, Airflow, S3 |
| **Shared Services** | 10.20.0.0/16 | Shared tools | 3 | ECR, Transfer Family |

---

## Security Layers (Defense in Depth)

```
Layer 1: EDGE
  ├─ CloudFront (TLS 1.3)
  ├─ AWS WAF (Managed Rules)
  └─ Shield Advanced (DDoS)

Layer 2: NETWORK
  ├─ Network Firewall (Stateful)
  ├─ Security Groups (Micro-seg)
  └─ Network ACLs (Subnet-level)

Layer 3: APPLICATION
  ├─ Istio mTLS (Service Mesh)
  ├─ API Gateway (JWT)
  └─ Cognito (MFA)

Layer 4: DATA
  ├─ KMS Encryption (at rest)
  ├─ TLS 1.2+ (in transit)
  ├─ Secrets Manager (rotation)
  └─ Private CA (certificates)

Layer 5: MONITORING
  ├─ GuardDuty (Threats)
  ├─ Security Hub (Compliance)
  ├─ CloudTrail (Audit)
  └─ Config (Compliance)
```

---

## Compute Architecture

### EKS Cluster
- **Nodes**: 3 node groups (1 per AZ)
- **Instance Type**: m6i.xlarge
- **Scaling**: 3-10 nodes per AZ
- **Service Mesh**: Istio (mTLS)
- **Ingress**: NGINX on Fargate

### Lambda
- **Functions**: 100+
- **Concurrency**: Auto-scaling
- **VPC**: Private subnet access

### Fargate
- **NGINX Ingress**: Load balancing
- **Task Scaling**: CPU/Memory-based

---

## Data Architecture

### Aurora PostgreSQL
- **Instances**: 3 (1 writer + 2 replicas)
- **Type**: db.r6g.xlarge
- **Failover**: < 30 seconds
- **Backup**: 30-day retention
- **Encryption**: KMS

### MSK Kafka
- **Brokers**: 3 (1 per AZ)
- **Type**: kafka.m5.large
- **Replication**: Factor 3
- **Encryption**: TLS + KMS

### ElastiCache Redis
- **Type**: cache.r6g.xlarge
- **Multi-AZ**: Automatic failover
- **Encryption**: TLS + KMS

### S3 Data Lake
- **Buckets**: Landing, Curated, Archive
- **Encryption**: KMS
- **Versioning**: Enabled
- **Lifecycle**: Auto-archival

### Redshift
- **Nodes**: 3 (dc2.large)
- **Storage**: 480GB total
- **Backup**: 30-day retention

---

## High Availability Metrics

| Component | RTO | RPO | Method |
|-----------|-----|-----|--------|
| **Database** | < 1 min | < 1 sec | Auto-failover |
| **Application** | < 5 min | 0 | Multi-AZ |
| **Cluster** | < 5 min | 0 | Auto-scaling |
| **Data** | 30 min | < 1 sec | Backups |

---

## Cost Breakdown (Monthly)

| Component | Cost | Notes |
|-----------|------|-------|
| EKS Control | $73 | Fixed |
| EKS Nodes | $800-1,200 | 9-30 m6i.xlarge |
| Aurora RDS | $400-600 | 3 instances |
| MSK Kafka | $300-400 | 3 brokers |
| NAT Gateways | $150-200 | 3 + data transfer |
| Network Firewall | $400-600 | Firewall + processing |
| ElastiCache | $200-300 | cache.r6g.xlarge |
| Redshift | $300-400 | 3 nodes |
| CloudFront | $100-200 | CDN |
| Other | $200-300 | Lambda, API GW, etc. |
| **TOTAL** | **$3-5K** | Production |

---

## Compliance Frameworks

✅ **PCI-DSS** - Card data protection  
✅ **CIS Benchmark** - Infrastructure hardening  
✅ **AWS Foundational** - AWS best practices  
✅ **NIST 800-53** - Federal compliance  
✅ **GDPR** - Data privacy  
✅ **FCA** - Financial services  

---

## Key Talking Points

### 1. High Availability
"Multi-AZ deployment across 3 AZs with automatic failover. Database RTO < 1 minute, application RTO < 5 minutes. No single point of failure."

### 2. Security
"Defense-in-depth with 5 layers: edge (CloudFront/WAF), network (firewall), application (mTLS), data (encryption), monitoring (GuardDuty). Compliance-ready for PCI-DSS, CIS, NIST."

### 3. Network Segregation
"7 segregated VPCs by function. Transit Gateway for controlled connectivity. Network Firewall for inspection. Security Groups for micro-segmentation."

### 4. Scalability
"Auto-scaling EKS (3-10 nodes per AZ), Aurora (read replicas), MSK (3 brokers). Handles 3x traffic spikes automatically."

### 5. Cost Efficiency
"$3-5K/month production. Reserved Instances (30-40% savings), Savings Plans (20-30%), SPOT instances for non-critical workloads."

### 6. Operational Excellence
"Infrastructure as Code (Terraform), Workspaces for environments, CI/CD with approval gates, comprehensive monitoring (CloudWatch, X-Ray)."

### 7. Compliance
"Security Hub for automated compliance checks, CloudTrail for audit logging, Config for configuration tracking, regular security assessments."

---

## Well-Architected Framework Alignment

| Pillar | Status | Key Features |
|--------|--------|--------------|
| **Operational Excellence** | ✅ | IaC, CI/CD, Monitoring, Runbooks |
| **Security** | ✅ | Defense-in-depth, Encryption, Compliance |
| **Reliability** | ✅ | Multi-AZ, Auto-failover, Backups |
| **Performance Efficiency** | ✅ | Right-sizing, Auto-scaling, Caching |
| **Cost Optimization** | ✅ | Reserved Instances, SPOT, Tiering |

---

## Common Assessment Questions & Answers

### Q: How do you ensure high availability?
**A**: Multi-AZ deployment across 3 AZs with automatic failover. Aurora has < 30 second failover, applications < 5 minutes. No single point of failure.

### Q: What's your security strategy?
**A**: Defense-in-depth with 5 layers. Edge security (CloudFront/WAF), network firewall, application mTLS, data encryption, and continuous monitoring (GuardDuty/Security Hub).

### Q: How do you segregate workloads?
**A**: 7 segregated VPCs by function (Hub, Inspection, Ingress, Workload, Data, etc.). Transit Gateway for controlled connectivity. Network Firewall for inspection.

### Q: What's your cost model?
**A**: $3-5K/month production. Optimized with Reserved Instances (30-40% savings), Savings Plans (20-30%), SPOT instances for non-critical workloads.

### Q: How do you manage infrastructure?
**A**: Infrastructure as Code (Terraform) with Workspaces for environment isolation. CI/CD pipeline with approval gates. Comprehensive monitoring and alerting.

### Q: What compliance frameworks do you support?
**A**: PCI-DSS, CIS Benchmark, AWS Foundational, NIST 800-53, GDPR, FCA. Automated compliance checks via Security Hub.

### Q: What's your disaster recovery strategy?
**A**: Single region with 3 AZs (RTO < 10 min, RPO < 1 sec). Automated backups with 30-day retention. Cross-region backup replication for critical data.

### Q: How do you handle traffic spikes?
**A**: Auto-scaling EKS (3-10 nodes per AZ), Aurora read replicas, MSK brokers. Handles 3x traffic spikes automatically.

---

## Presentation Flow

### 5-Minute Overview
1. Start with high-level architecture (edge → ingress → firewall → workload → data)
2. Mention 3 AZs for HA
3. Highlight 7 VPCs for security
4. Note $3-5K/month cost
5. Emphasize compliance-ready

### 15-Minute Deep Dive
1. Architecture overview (5 min)
2. VPC segregation and connectivity (3 min)
3. Security layers (3 min)
4. Compute and data architecture (2 min)
5. Cost and HA metrics (2 min)

### 30-Minute Full Presentation
1. Architecture overview (5 min)
2. VPC segregation (5 min)
3. Security architecture (5 min)
4. Compute and data (5 min)
5. HA and DR (3 min)
6. Cost optimization (2 min)
7. Q&A (5 min)

---

## Diagrams to Reference

- **1-multi-region-overview.drawio**: High-level architecture (use for 5-min overview)
- **2-primary-ireland-v2.drawio**: Detailed single-region architecture (use for deep dive)
- **3-dr-london-v2.drawio**: DR architecture (reference only, not primary focus)

---

## Pre-Assessment Checklist

- [ ] Read AWS-SOLUTIONS-ARCHITECT-ASSESSMENT.md completely
- [ ] Understand each VPC's purpose
- [ ] Know the 5 security layers
- [ ] Memorize key metrics (RTO, RPO, cost)
- [ ] Practice explaining VPC segregation
- [ ] Review Well-Architected Framework alignment
- [ ] Prepare examples for each pillar
- [ ] Practice 5-min, 15-min, 30-min presentations
- [ ] Know answers to common questions
- [ ] Have diagrams ready to reference

---

## Key Numbers to Remember

- **3 AZs**: High availability
- **7 VPCs**: Security segregation
- **600+ Resources**: Comprehensive infrastructure
- **$3-5K/month**: Production cost
- **< 1 min RTO**: Database failover
- **< 5 min RTO**: Application failover
- **< 1 sec RPO**: Data loss tolerance
- **5 Layers**: Defense-in-depth security
- **6 Compliance Frameworks**: PCI-DSS, CIS, NIST, GDPR, FCA, AWS Foundational
- **100+ Lambda Functions**: Event-driven compute

---

**Good luck with your AWS Solutions Architect Assessment! 🚀**

This architecture demonstrates enterprise-grade design, security, and operational excellence.
