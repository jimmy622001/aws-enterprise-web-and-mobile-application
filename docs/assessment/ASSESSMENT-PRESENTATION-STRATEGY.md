# AWS Solutions Architect Assessment - Presentation Strategy

## Executive Recommendation: 2 Projects (25-30 minutes)

**Why 2 projects instead of 3:**
- Allows 12-15 minutes per project (depth over breadth)
- Demonstrates mastery of complex scenarios
- Time for assessor questions and discussion
- Shows thoughtful prioritization

---

## Recommended Project Selection

### Project 1: WBDM-TST (Billable) - Core Banking Platform ✅ PRIMARY
**Duration**: 15 minutes  
**Focus**: Architecture design, security, compliance, integration complexity

### Project 2: [Your second strongest project] - OPTIONAL
**Duration**: 10-12 minutes  
**Focus**: Different architectural pattern or challenge

**Skip Project 3** - Better to go deep on 2 than shallow on 3

---

## Project 1: WBDM-TST Presentation Flow (15 minutes)

### Slide 1: Business Challenge & Constraints (2 minutes)

**Current Content** ✅ Good foundation. Enhance with:

```
BUSINESS CHALLENGE & CONSTRAINTS

Client: Westbrom Building Society (Bank)
Challenge: Modernize legacy core banking system

Stage 1: Web & Mobile Banking Platform
├─ Integrate with on-premise infrastructure
├─ Connect to multiple third-party services
│  ├─ Fraud detection (FeatureSpace)
│  ├─ Core banking (10x system)
│  ├─ Document management (Alfresco)
│  └─ AML/KYC (Comply Advantage)
└─ Ensure regulatory compliance & resilience

KEY CONSTRAINTS:
✓ PCI-DSS compliance (card data)
✓ FCA regulation (financial services)
✓ GDPR (data privacy)
✓ High availability (banking SLA)
✓ Secure on-prem integration
✓ Auditable data flows
✓ Disaster recovery capability

STAGES:
Stage 1: Web & Mobile Banking (Current - THIS PROJECT)
Stage 2: Savings & Loan Platform (Future)
Stage 3: Mortgages Platform (Future)
```

**Talking Points:**
- "This is a phased modernization where Stage 1 establishes the foundation"
- "The architecture must support future stages without major rework"
- "Multiple third-party integrations require secure, auditable connectivity"

---

### Slide 2: Architecture Overview (2 minutes)

**Show the high-level flow:**

```
┌─────────────────────────────────────────────────────────────┐
│                    SINGLE REGION, 3-AZ DESIGN               │
│                      eu-west-1 (Ireland)                    │
└─────────────────────────────────────────────────────────────┘

EXTERNAL LAYER:
  Users (Web/Mobile) → CloudFront + WAF + Shield Advanced

INGRESS LAYER (3 AZs):
  ALB/NLB → API Gateway → Cognito (Authentication)

SECURITY LAYER:
  Network Firewall (Inspection VPC) - All traffic inspected

WORKLOAD LAYER (3 AZs):
  EKS Cluster (Kubernetes) + Istio mTLS

DATA LAYER (3 AZs):
  Aurora PostgreSQL | MSK Kafka | ElastiCache | S3

INTEGRATION LAYER:
  ├─ On-Premise (Site-to-Site VPN)
  ├─ Third-Party Services (Network Firewall)
  └─ Secure, Auditable Flows
```

**Talking Points:**
- "Single region with 3 AZs eliminates single points of failure"
- "7 segregated VPCs provide defense-in-depth security"
- "All integrations flow through Network Firewall for inspection and audit"

---

### Slide 3: VPC Segregation & Network Design (2.5 minutes)

**This is your differentiator - show the segregation:**

```
VPC SEGREGATION BY FUNCTION:

Hub VPC (10.0.0.0/16)
├─ Central routing hub
├─ NAT Gateways (3 AZs)
└─ Route 53 Resolver

Inspection VPC (10.2.0.0/16)
├─ Network Firewall (all traffic)
├─ IPS/IDS rules
└─ Domain filtering

Private Ingress VPC (10.1.0.0/16)
├─ Client VPN (Okta SAML)
└─ Remote access for staff

Ingress VPC (10.11.0.0/16)
├─ ALB/NLB (public)
├─ ECS Fargate (NGINX proxy)
└─ API Gateway

Workload VPC (10.10.0.0/16)
├─ EKS Cluster (3 node groups)
├─ Aurora PostgreSQL (3 instances)
└─ MSK Kafka (3 brokers)

Data VPC (10.12.0.0/16)
├─ Glue (ETL)
├─ Airflow (orchestration)
└─ S3 Data Lake

Shared Services VPC (10.20.0.0/16)
├─ ECR (container registry)
├─ Transfer Family (SFTP)
└─ Shared databases

CONNECTIVITY:
All VPCs connected via Transit Gateway
All cross-VPC traffic inspected by Network Firewall
```

**Talking Points:**
- "Each VPC has a specific security boundary and purpose"
- "This segregation allows us to apply least-privilege access"
- "Network Firewall provides centralized inspection of all traffic"
- "Easy to scale - add new VPCs without affecting existing ones"

---

### Slide 4: Security Architecture (2.5 minutes)

**Defense-in-depth is your strength:**

```
DEFENSE-IN-DEPTH: 5 LAYERS

Layer 1: EDGE SECURITY
├─ CloudFront (TLS 1.3, geo-restriction)
├─ AWS WAF (SQL injection, XSS, rate limiting)
└─ Shield Advanced (DDoS protection)

Layer 2: NETWORK SECURITY
├─ Network Firewall (stateful inspection)
├─ Security Groups (micro-segmentation)
└─ Network ACLs (subnet-level filtering)

Layer 3: APPLICATION SECURITY
├─ Istio Service Mesh (mTLS between services)
├─ API Gateway (JWT validation, OAuth 2.0)
└─ Cognito (MFA, user authentication)

Layer 4: DATA SECURITY
├─ KMS Encryption (at rest)
├─ TLS 1.2+ (in transit)
├─ Secrets Manager (credential rotation)
└─ Private CA (internal certificates)

Layer 5: MONITORING & DETECTION
├─ GuardDuty (threat detection)
├─ Security Hub (compliance monitoring)
├─ CloudTrail (audit logging)
└─ Config (configuration tracking)

COMPLIANCE FRAMEWORKS:
✓ PCI-DSS (card data protection)
✓ CIS Benchmark (infrastructure hardening)
✓ NIST 800-53 (federal compliance)
✓ GDPR (data privacy)
✓ FCA (financial services)
```

**Talking Points:**
- "Each layer is independent - compromise of one doesn't break others"
- "PCI-DSS compliance is built-in, not bolted-on"
- "Automated compliance monitoring via Security Hub"
- "Complete audit trail for regulatory requirements"

---

### Slide 5: Integration Architecture (2 minutes)

**This addresses the "multiple third-party services" requirement:**

```
SECURE INTEGRATION FLOWS:

┌─────────────────────────────────────────────────────────┐
│                  NETWORK FIREWALL                       │
│         (Inspection VPC - All Traffic Inspected)        │
└────────────────┬────────────────────────────────────────┘
                 │
    ┌────────────┼────────────┬──────────────┐
    │            │            │              │
    ▼            ▼            ▼              ▼
On-Prem      Third-Party   Internal      External
(10x)        Services      Services      Partners
             (Fraud,       (EKS,         (SFTP)
              AML/KYC)      Aurora)

INTEGRATION PATTERNS:

1. ON-PREMISE INTEGRATION (10x Core Banking)
   ├─ Site-to-Site VPN (IPsec)
   ├─ Encrypted tunnel
   ├─ Network Firewall inspection
   └─ Audit logging (CloudTrail)

2. THIRD-PARTY SERVICES (Fraud, AML/KYC)
   ├─ Outbound through Network Firewall
   ├─ Domain filtering (allow-list)
   ├─ TLS 1.2+ encryption
   └─ API authentication (OAuth/JWT)

3. INTERNAL SERVICES (EKS, Aurora)
   ├─ Private subnets (no internet)
   ├─ Istio mTLS (service-to-service)
   ├─ Secrets Manager (credentials)
   └─ VPC Endpoints (AWS services)

4. EXTERNAL PARTNERS (SFTP)
   ├─ AWS Transfer Family
   ├─ SSH key authentication
   ├─ Anti-malware scanning
   └─ Audit logging
```

**Talking Points:**
- "All integrations are auditable - critical for banking"
- "Network Firewall provides centralized control and inspection"
- "Each integration type has appropriate security controls"
- "Supports future stages (Savings & Loan, Mortgages) without redesign"

---

### Slide 6: High Availability & Disaster Recovery (2 minutes)

**Show resilience:**

```
HIGH AVAILABILITY (Single Region, 3 AZs):

COMPONENT DISTRIBUTION:
AZ-1a: EKS Node Group 1, Aurora Primary, MSK Broker 1
AZ-1b: EKS Node Group 2, Aurora Replica, MSK Broker 2
AZ-1c: EKS Node Group 3, Aurora Replica, MSK Broker 3

FAILOVER CAPABILITIES:
├─ Database: < 30 seconds (automatic)
├─ Application: < 5 minutes (auto-scaling)
├─ Cluster: < 5 minutes (health checks)
└─ Data: < 1 second (synchronous replication)

RTO/RPO TARGETS:
┌──────────────────┬─────────┬─────────┐
│ Component        │ RTO     │ RPO     │
├──────────────────┼─────────┼─────────┤
│ Database         │ < 1 min │ < 1 sec │
│ Application      │ < 5 min │ 0       │
│ Cluster          │ < 5 min │ 0       │
│ Data             │ 30 min  │ < 1 sec │
└──────────────────┴─────────┴─────────┘

BACKUP STRATEGY:
├─ Aurora: Continuous backup (30-day retention)
├─ RDS: Daily snapshots (30-day retention)
├─ S3: Versioning enabled
├─ EBS: Daily snapshots (30-day retention)
└─ Cross-region: Critical data replicated to eu-west-2

DISASTER RECOVERY:
Stage 1: Single region with 3 AZs (RTO < 10 min)
Stage 2: Warm standby in eu-west-2 (future)
Stage 3: Multi-region active-active (future)
```

**Talking Points:**
- "No single point of failure - any AZ can go down"
- "Automatic failover for databases and applications"
- "Meets banking SLA requirements"
- "Architecture supports future multi-region expansion"

---

### Slide 7: Cost & Operational Excellence (1.5 minutes)

**Show you understand the business side:**

```
COST OPTIMIZATION:

PRODUCTION MONTHLY COST: $3,000-5,000

Breakdown:
├─ EKS Control Plane: $73
├─ EKS Nodes (9-30): $800-1,200
├─ Aurora RDS (3 instances): $400-600
├─ MSK Kafka (3 brokers): $300-400
├─ NAT Gateways (3): $150-200
├─ Network Firewall: $400-600
├─ Other Services: $500-700
└─ TOTAL: $3,000-5,000

OPTIMIZATION STRATEGIES:
├─ Reserved Instances: 30-40% savings
├─ Savings Plans: 20-30% savings
├─ SPOT instances: 70% savings (non-critical)
├─ S3 Intelligent-Tiering: Automatic optimization
└─ VPC Endpoints: Reduce data transfer costs

OPERATIONAL EXCELLENCE:
├─ Infrastructure as Code (Terraform)
├─ Workspaces for environment isolation
├─ CI/CD pipeline with approval gates
├─ Comprehensive monitoring (CloudWatch, X-Ray)
├─ Automated compliance checks (Security Hub)
└─ Runbooks for common operations
```

**Talking Points:**
- "Cost is predictable and optimized"
- "Infrastructure as Code ensures consistency"
- "Automated compliance reduces manual effort"
- "Supports future scaling without major redesign"

---

### Slide 8: Well-Architected Framework Alignment (1 minute)

**Show you know AWS best practices:**

```
WELL-ARCHITECTED FRAMEWORK ALIGNMENT:

✓ OPERATIONAL EXCELLENCE
  ├─ IaC (Terraform)
  ├─ CI/CD pipeline
  ├─ Comprehensive monitoring
  └─ Runbooks & documentation

✓ SECURITY
  ├─ Defense-in-depth (5 layers)
  ├─ Encryption everywhere
  ├─ Network segregation (7 VPCs)
  ├─ Compliance monitoring
  └─ Audit logging

✓ RELIABILITY
  ├─ Multi-AZ deployment (3 AZs)
  ├─ Automatic failover
  ├─ Health checks & auto-scaling
  ├─ Backup & recovery
  └─ RTO < 10 min, RPO < 1 sec

✓ PERFORMANCE EFFICIENCY
  ├─ Right-sized instances
  ├─ Auto-scaling
  ├─ Caching (ElastiCache)
  ├─ CDN (CloudFront)
  └─ Database optimization

✓ COST OPTIMIZATION
  ├─ Reserved Instances
  ├─ Savings Plans
  ├─ SPOT instances
  ├─ S3 Intelligent-Tiering
  └─ VPC Endpoints
```

**Talking Points:**
- "This architecture aligns with all 5 pillars of Well-Architected Framework"
- "Not just technically sound, but operationally and financially optimized"

---

## Presentation Timing Breakdown (15 minutes)

| Slide | Topic | Time | Notes |
|-------|-------|------|-------|
| 1 | Business Challenge | 2 min | Set context |
| 2 | Architecture Overview | 2 min | High-level view |
| 3 | VPC Segregation | 2.5 min | Your differentiator |
| 4 | Security (5 Layers) | 2.5 min | Compliance focus |
| 5 | Integration Architecture | 2 min | Third-party/on-prem |
| 6 | HA & DR | 2 min | Resilience |
| 7 | Cost & Operations | 1.5 min | Business value |
| 8 | Well-Architected | 1 min | Best practices |
| **TOTAL** | | **15 min** | |

---

## Key Talking Points to Memorize

### Opening (30 seconds)
"This is a phased modernization of a legacy banking system. Stage 1 focuses on web and mobile banking with secure integration to on-premise systems and multiple third-party services. The architecture must be robust, secure, compliant, and resilient."

### VPC Segregation (Your Strength)
"We use 7 segregated VPCs organized by function and security boundary. This allows us to apply least-privilege access, isolate failures, and scale independently. All cross-VPC traffic flows through a centralized Network Firewall for inspection and audit."

### Security (Compliance Focus)
"Defense-in-depth with 5 layers: edge security (CloudFront/WAF), network security (firewall), application security (mTLS), data security (encryption), and monitoring (GuardDuty/Security Hub). This architecture is PCI-DSS, CIS, NIST, GDPR, and FCA compliant."

### Integration (Addresses Requirements)
"All integrations - whether on-premise, third-party, or internal - flow through the Network Firewall for centralized inspection and audit. This ensures secure, auditable data flows as required by the bank."

### HA/DR (Resilience)
"Multi-AZ deployment across 3 AZs with automatic failover. Database RTO < 1 minute, application RTO < 5 minutes. No single point of failure. Meets banking SLA requirements."

### Closing (30 seconds)
"This architecture is designed to support future stages (Savings & Loan, Mortgages) without major rework. It's secure, compliant, resilient, and cost-optimized."

---

## Anticipated Questions & Answers

### Q: Why 7 VPCs instead of fewer?
**A**: "Each VPC represents a security boundary. This segregation allows us to apply least-privilege access, isolate failures, and scale independently. For example, if the Ingress VPC is compromised, the Workload VPC remains protected."

### Q: Why Network Firewall instead of just Security Groups?
**A**: "Security Groups are stateful but application-aware. Network Firewall provides stateful inspection at the network layer, including IPS/IDS rules and domain filtering. Together they provide defense-in-depth."

### Q: How do you handle on-premise integration securely?
**A**: "Site-to-Site VPN with IPsec encryption. All traffic flows through the Network Firewall for inspection. CloudTrail logs all API calls. This provides the audit trail required for banking compliance."

### Q: What about multi-region disaster recovery?
**A**: "Stage 1 uses single-region with 3 AZs. Future stages will add warm standby in eu-west-2 (London) and eventually multi-region active-active. The architecture is designed to support this evolution."

### Q: How do you ensure PCI-DSS compliance?
**A**: "Multiple controls: encryption at rest (KMS) and in transit (TLS 1.2+), network segmentation (7 VPCs), access control (IAM), audit logging (CloudTrail), and automated compliance monitoring (Security Hub)."

### Q: What's the cost?
**A**: "$3-5K/month for production. Optimized with Reserved Instances (30-40% savings), Savings Plans (20-30%), and SPOT instances for non-critical workloads."

### Q: How do you handle the phased rollout (Stage 1, 2, 3)?
**A**: "The architecture is designed to support all three stages. Stage 1 establishes the foundation. Stages 2 and 3 add new VPCs and services without requiring major rework. The Transit Gateway and Network Firewall scale seamlessly."

---

## Slide Design Tips

### Use Visuals
- Show the VPC diagram (your differentiator)
- Show the 5-layer security model
- Show the integration flows
- Use color coding (green = active, red = standby, blue = networking)

### Keep Text Minimal
- Use bullet points, not paragraphs
- One idea per slide
- Let the visuals do the talking

### Tell a Story
1. **Problem**: Legacy system, need modernization
2. **Constraints**: Compliance, security, integration
3. **Solution**: Multi-AZ, 7 VPCs, defense-in-depth
4. **Benefits**: Secure, compliant, resilient, cost-optimized
5. **Future**: Supports Stages 2 & 3

---

## Practice Recommendations

### Before Presentation
1. Practice the 15-minute flow 3-4 times
2. Time yourself on each slide
3. Prepare for common questions
4. Have the diagrams ready to reference
5. Know your numbers (RTO, RPO, cost, compliance frameworks)

### During Presentation
1. Start with the business challenge (context)
2. Show the architecture overview (big picture)
3. Drill down into VPC segregation (your strength)
4. Explain security layers (compliance focus)
5. Address integration requirements (third-party/on-prem)
6. Highlight HA/DR (resilience)
7. Mention cost and operations (business value)
8. Align with Well-Architected Framework (best practices)

### Handling Questions
1. Listen fully before answering
2. Relate back to the business challenge
3. Use the diagrams to explain
4. Be honest if you don't know something
5. Offer to follow up

---

## Why This Approach Works

### Strengths of Your Project
✅ **Complex integration requirements** - Shows you can handle real-world scenarios  
✅ **Multiple compliance frameworks** - Demonstrates regulatory knowledge  
✅ **Phased rollout** - Shows forward-thinking architecture  
✅ **On-premise integration** - Hybrid cloud expertise  
✅ **Third-party services** - Integration complexity  

### What Assessors Look For
✅ **Problem-solving** - How you address constraints  
✅ **Trade-offs** - Why you made specific choices  
✅ **Best practices** - Alignment with AWS Well-Architected  
✅ **Business acumen** - Understanding cost and compliance  
✅ **Communication** - Clear explanation of complex concepts  

### Your Competitive Advantage
✅ **VPC segregation** - Most candidates don't go this deep  
✅ **Defense-in-depth** - Shows security maturity  
✅ **Integration architecture** - Real-world complexity  
✅ **Compliance focus** - Banking/financial services expertise  
✅ **Phased approach** - Scalable, future-proof design  

---

## Final Recommendation

**Stick with Project 1 (WBDM-TST) as your primary project.**

This project has everything an assessor wants to see:
- Complex business requirements
- Multiple integration points
- Compliance and security focus
- High availability and disaster recovery
- Cost optimization
- Operational excellence

**If you have time for a second project**, choose one that demonstrates a different architectural pattern (e.g., data pipeline, microservices, serverless) to show breadth of knowledge.

**Avoid the temptation to present all 3 projects.** Better to go deep on 1-2 and have time for discussion than to rush through 3 and leave questions unanswered.

---

**Good luck with your presentation! You have a strong project with excellent architectural decisions. 🚀**
