# Disaster Recovery (DR) Architecture

## Overview

This document describes the multi-region Disaster Recovery (DR) architecture implemented for enterprise-grade business continuity and high availability.

---

## Architecture Summary

### **Primary Region**: `eu-west-1` (Ireland)
- Full production infrastructure
- Active-active for all services
- Complete data persistence and processing

### **DR Region**: `eu-west-2` (London)
- **Pilot Light** configuration (default)
- Minimal infrastructure always running
- Automatic scale-up on failover
- Cross-region data replication

---

## DR Strategy Options

### **1. Pilot Light** (Default) 💡
**RTO**: 2-4 hours | **RPO**: 1 hour | **Cost**: ~15% of primary

**What's Running:**
- ✅ Minimal VPC infrastructure (no compute)
- ✅ Aurora Global Database (single read replica)
- ✅ S3 cross-region replication
- ✅ ECR cross-region replication
- ✅ Route 53 health checks
- ❌ EKS nodes scaled to 0
- ❌ CloudFront disabled
- ❌ Application servers stopped

**Use Case**: Cost-effective DR for non-critical workloads

---

### **2. Warm Standby** 🔥
**RTO**: 15-60 minutes | **RPO**: 15 minutes | **Cost**: ~40% of primary

**What's Running:**
- ✅ Full VPC infrastructure
- ✅ Aurora Global Database (2 read replicas)
- ✅ EKS cluster with minimal nodes (2 per node group)
- ✅ CloudFront enabled but low traffic
- ✅ Application pods running (scaled down)
- ✅ Continuous data replication

**Use Case**: Faster recovery for business-critical applications

---

### **3. Active-Active** 🚀
**RTO**: < 1 minute | **RPO**: Near-zero | **Cost**: ~90-100% of primary

**What's Running:**
- ✅ Full production capacity in both regions
- ✅ Multi-region write capabilities
- ✅ Active traffic distribution (50/50 or weighted)
- ✅ Real-time data sync
- ✅ No failover required (automatic load balancing)

**Use Case**: Zero-downtime requirements, global applications

---

## Infrastructure Components

### 1. **Network Infrastructure**

#### Primary Region (eu-west-1)
```
┌─────────────────────────────────────────────────────────┐
│ Primary Region (eu-west-1 - Ireland)                    │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Hub VPC    │  │ Workload VPC │  │   Data VPC   │  │
│  │ 10.0.0.0/16  │  │ 10.10.0.0/16 │  │ 10.12.0.0/16 │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │            │
│         └────────┬────────┴────────┬────────┘            │
│                  │                 │                     │
│           ┌──────▼─────────────────▼──────┐             │
│           │   Transit Gateway (TGW)       │             │
│           │      ASN: 64512               │             │
│           └───────────────────────────────┘             │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

#### DR Region (eu-west-2)
```
┌─────────────────────────────────────────────────────────┐
│ DR Region (eu-west-2 - London)                          │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  DR Hub VPC  │  │DR Workload VPC│  │ DR Data VPC  │  │
│  │10.200.0.0/16 │  │ 10.210.0.0/16│  │ 10.212.0.0/16│  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                 │                 │            │
│         └────────┬────────┴────────┬────────┘            │
│                  │                 │                     │
│           ┌──────▼─────────────────▼──────┐             │
│           │   DR Transit Gateway          │             │
│           │      ASN: 65512               │             │
│           └───────────────────────────────┘             │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

### 2. **Data Replication**

#### Aurora Global Database
```
┌──────────────────────────────────────────────────────────┐
│                 Aurora Global Database                    │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  Primary (eu-west-1)          DR (eu-west-2)             │
│  ┌─────────────────┐          ┌─────────────────┐        │
│  │  Writer Node    │──Async──▶│  Reader Node    │        │
│  │  db.r6g.xlarge  │  Replic  │  db.t4g.medium  │        │
│  ├─────────────────┤          └─────────────────┘        │
│  │  Reader Node 1  │                                      │
│  ├─────────────────┤          Replication Lag:           │
│  │  Reader Node 2  │          < 1 second (typical)       │
│  └─────────────────┘                                      │
│                                                            │
│  RPO: < 1 second (data loss in DR scenario)              │
└──────────────────────────────────────────────────────────┘
```

#### S3 Cross-Region Replication
```
Primary S3 Buckets (eu-west-1)    DR S3 Buckets (eu-west-2)
┌────────────────────────┐        ┌────────────────────────┐
│ Data Lake              │───────▶│ DR Data Lake           │
│ Application Assets     │───────▶│ DR Application Assets  │
│ Logs & Backups         │───────▶│ DR Logs & Backups      │
└────────────────────────┘        └────────────────────────┘

Replication: Near real-time (< 15 minutes typical)
Versioning: Enabled on all buckets
Encryption: KMS with cross-region keys
```

#### ECR Replication
```
Primary ECR (eu-west-1)           DR ECR (eu-west-2)
┌────────────────────────┐        ┌────────────────────────┐
│ nginx-proxy:latest     │───────▶│ nginx-proxy:latest     │
│ api-service:v1.2.3     │───────▶│ api-service:v1.2.3     │
│ web-app:v2.0.1         │───────▶│ web-app:v2.0.1         │
│ worker-service:latest  │───────▶│ worker-service:latest  │
└────────────────────────┘        └────────────────────────┘

Replication: Automatic on push
Cross-account: Supported
```

---

### 3. **Failover Mechanism**

#### Automatic Failover (Route 53 Health Checks)
```
                    ┌─────────────────────────┐
                    │   Route 53 DNS          │
                    │  example.co.uk          │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼──────────────┐
                    │   Health Check           │
                    │   Primary Region         │
                    │   Interval: 30s          │
                    └───────────┬──────────────┘
                                │
                 ┌──────────────┴──────────────┐
                 │                             │
          HEALTHY│                             │UNHEALTHY
                 │                             │
       ┌─────────▼──────────┐        ┌────────▼────────────┐
       │  PRIMARY RECORD    │        │  FAILOVER RECORD    │
       │  CloudFront        │        │  DR CloudFront      │
       │  (eu-west-1)       │        │  (eu-west-2)        │
       └────────────────────┘        └─────────────────────┘
              ACTIVE                        STANDBY
```

#### Failover Flow
```
1. Health Check Failure (3 consecutive failures)
   ↓
2. CloudWatch Alarm Triggered
   ↓
3. SNS Notification Sent
   ↓
4. EventBridge Rule Activated
   ↓
5. Lambda Function Invoked
   ↓
6. DR Scale-Up Operations:
   ├─ Aurora: Scale from 1 to 3 instances
   ├─ EKS: Scale nodes from 0 to 6
   ├─ CloudFront: Enable DR distribution
   └─ Route 53: Activate secondary record
   ↓
7. Traffic Switches to DR Region
   ↓
8. Operations Team Notified
```

---

## RTO/RPO Targets by Environment

| Environment | Strategy      | RTO     | RPO       | Cost % |
|-------------|---------------|---------|-----------|--------|
| **POC**     | None          | N/A     | N/A       | 0%     |
| **Dev**     | None          | N/A     | N/A       | 0%     |
| **Staging** | Pilot Light   | 4 hours | 1 hour    | 15%    |
| **UAT**     | Pilot Light   | 2 hours | 30 min    | 20%    |
| **Prod**    | Warm Standby  | 1 hour  | 15 min    | 40%    |

---

## DR Configuration by Environment

### Variables in tfvars Files

#### For environments **WITHOUT** DR (POC, Dev):
```hcl
# Disaster Recovery
enable_dr = false  # DR disabled
```

#### For environments **WITH** Pilot Light (Staging, UAT):
```hcl
# Disaster Recovery
enable_dr              = true
dr_region              = "eu-west-2"
dr_strategy            = "pilot-light"
dr_rto_hours           = 4
dr_rpo_hours           = 1
dr_failover_mode       = "manual"  # Manual failover for non-prod

# DR VPC CIDRs
dr_hub_vpc_cidr             = "10.200.0.0/16"
dr_workload_vpc_cidr        = "10.210.0.0/16"
dr_data_vpc_cidr            = "10.212.0.0/16"
dr_shared_services_vpc_cidr = "10.220.0.0/16"

# DR Sizing (Minimal)
dr_aurora_instance_class    = "db.t4g.medium"
dr_aurora_instance_count    = 1
dr_eks_node_desired_size    = 0  # Scaled to 0 for pilot light
dr_postgres_instance_class  = "db.t4g.medium"
```

#### For environments **WITH** Warm Standby (Prod):
```hcl
# Disaster Recovery
enable_dr              = true
dr_region              = "eu-west-2"
dr_strategy            = "warm-standby"
dr_rto_hours           = 1
dr_rpo_hours           = 0  # Near-zero RPO
dr_failover_mode       = "automatic"  # Automatic failover for prod

# DR VPC CIDRs
dr_hub_vpc_cidr             = "10.200.0.0/16"
dr_workload_vpc_cidr        = "10.210.0.0/16"
dr_data_vpc_cidr            = "10.212.0.0/16"
dr_shared_services_vpc_cidr = "10.220.0.0/16"

# DR Sizing (Production-grade but smaller)
dr_aurora_instance_class    = "db.r6g.large"   # Smaller than primary
dr_aurora_instance_count    = 2                # Fewer than primary (3)
dr_eks_node_desired_size    = 2                # Minimal nodes running
dr_postgres_instance_class  = "db.r6g.large"
```

---

## Cost Analysis

### Monthly Cost Estimates (Production Environment)

#### Primary Region (eu-west-1): ~$3,500/month
- VPCs & Networking: $500
- Aurora RDS (3x r6g.xlarge): $1,200
- EKS Cluster (6x m6i.xlarge): $800
- NAT Gateways: $300
- Data Transfer: $400
- Other Services: $300

#### DR Region - Pilot Light (eu-west-2): ~$525/month (15%)
- VPCs & Networking: $100
- Aurora Global DB (1x t4g.medium): $200
- EKS Control Plane (no nodes): $75
- S3 Replication Storage: $100
- Route 53 Health Checks: $25
- Other Services: $25

#### DR Region - Warm Standby (eu-west-2): ~$1,400/month (40%)
- VPCs & Networking: $200
- Aurora Global DB (2x r6g.large): $800
- EKS Cluster (2x m6i.xlarge): $200
- NAT Gateways: $150
- Other Services: $50

---

## Deployment Instructions

### 1. Enable DR for an Environment

Update the environment's tfvars file (e.g., `prod.tfvars`):

```hcl
# Add DR configuration
enable_dr              = true
dr_region              = "eu-west-2"
dr_strategy            = "pilot-light"  # or "warm-standby"
dr_rto_hours           = 4
dr_rpo_hours           = 1
dr_failover_mode       = "manual"      # or "automatic" for prod

# Add DR VPC CIDRs (must not overlap with primary)
dr_hub_vpc_cidr             = "10.200.0.0/16"
dr_workload_vpc_cidr        = "10.210.0.0/16"
dr_data_vpc_cidr            = "10.212.0.0/16"
dr_shared_services_vpc_cidr = "10.220.0.0/16"

# Add DR sizing
dr_aurora_instance_class    = "db.t4g.medium"
dr_aurora_instance_count    = 1
dr_eks_node_desired_size    = 0  # 0 for pilot light, 2+ for warm standby
dr_postgres_instance_class  = "db.t4g.medium"
```

### 2. Package Lambda Function

```powershell
.\package-dr-lambda.ps1
```

### 3. Deploy DR Infrastructure

```powershell
# Initialize with DR providers
terraform init

# Plan DR deployment
.\workspace-manager.ps1 -Action plan -Workspace prod

# Apply DR infrastructure
.\workspace-manager.ps1 -Action apply -Workspace prod
```

### 4. Validate DR Setup

```powershell
# Check DR resources
terraform state list | Select-String "dr_"

# Verify Aurora Global Database
aws rds describe-global-clusters --region eu-west-1

# Check S3 replication
aws s3api get-bucket-replication --bucket <primary-bucket>

# Verify Route 53 health checks
aws route53 list-health-checks
```

---

## Failover Procedures

### Automatic Failover (Production Only)

When `dr_failover_mode = "automatic"`, failover happens automatically:

1. **Health check fails** (3 consecutive failures = 90 seconds)
2. **CloudWatch alarm triggers**
3. **Lambda function executes** scale-up operations
4. **Route 53 switches** traffic to DR CloudFront
5. **Operations team notified** via SNS/email

**Total Time**: 5-10 minutes for DNS propagation

---

### Manual Failover (All Environments)

#### Step 1: Assess Primary Region
```bash
# Check primary region health
aws cloudwatch describe-alarms --region eu-west-1

# Check RDS status
aws rds describe-db-clusters --region eu-west-1

# Check EKS status
aws eks describe-cluster --name <cluster-name> --region eu-west-1
```

#### Step 2: Scale Up DR Infrastructure
```bash
# Scale Aurora to production capacity
aws rds modify-db-cluster \
  --db-cluster-identifier example-prod-dr-workload-cluster \
  --apply-immediately \
  --region eu-west-2

# Add additional Aurora instances
for i in {2..3}; do
  aws rds create-db-instance \
    --db-instance-identifier example-prod-dr-workload-$i \
    --db-cluster-identifier example-prod-dr-workload-cluster \
    --db-instance-class db.r6g.xlarge \
    --engine aurora-postgresql \
    --region eu-west-2
done

# Scale EKS node groups
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name <asg-name> \
  --desired-capacity 6 \
  --region eu-west-2
```

#### Step 3: Enable DR CloudFront
```bash
# Get DR CloudFront distribution ID
DR_DIST_ID=$(aws cloudfront list-distributions --query \
  "DistributionList.Items[?Comment contains 'dr-cloudfront'].Id" \
  --output text)

# Get current config
aws cloudfront get-distribution-config \
  --id $DR_DIST_ID > dr-config.json

# Enable distribution (modify Enabled: true in config)
aws cloudfront update-distribution \
  --id $DR_DIST_ID \
  --if-match <etag> \
  --distribution-config file://dr-config-updated.json
```

#### Step 4: Update Route 53
```bash
# Update DNS to point to DR
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch file://dr-dns-update.json
```

#### Step 5: Verify Application
```bash
# Test DR endpoint
curl -I https://example.co.uk

# Check application logs
kubectl logs -n production <pod-name> --region eu-west-2

# Monitor metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --region eu-west-2 \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average
```

---

## Failback Procedures

### Prerequisites
1. Primary region fully operational
2. All data synchronized to primary
3. Maintenance window scheduled
4. Stakeholders notified

### Step 1: Verify Primary Region
```bash
# Check all services operational
aws cloudwatch describe-alarms --alarm-names <primary-alarms> --region eu-west-1

# Verify data replication status
aws rds describe-db-clusters \
  --db-cluster-identifier <primary-cluster> \
  --region eu-west-1
```

### Step 2: Sync Latest Data to Primary
```bash
# Promote DR Aurora to standalone (if needed)
aws rds remove-from-global-cluster \
  --db-cluster-identifier <dr-cluster> \
  --region eu-west-2

# Create snapshot of DR Aurora
aws rds create-db-cluster-snapshot \
  --db-cluster-snapshot-identifier dr-failback-snapshot \
  --db-cluster-identifier <dr-cluster> \
  --region eu-west-2

# Restore to primary region
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier <primary-cluster> \
  --snapshot-identifier dr-failback-snapshot \
  --region eu-west-1
```

### Step 3: Switch Traffic Back
```bash
# Update Route 53 to primary
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch file://primary-dns-update.json

# Monitor traffic shift
watch 'aws cloudwatch get-metric-statistics --namespace AWS/Route53 --metric-name HealthCheckStatus --region eu-west-1'
```

### Step 4: Scale Down DR
```bash
# Scale EKS to pilot light
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name <dr-asg> \
  --desired-capacity 0 \
  --region eu-west-2

# Scale Aurora to single instance
aws rds delete-db-instance \
  --db-instance-identifier example-prod-dr-workload-2 \
  --skip-final-snapshot \
  --region eu-west-2

# Disable DR CloudFront
aws cloudfront update-distribution \
  --id $DR_DIST_ID \
  --if-match <etag> \
  --distribution-config file://dr-config-disabled.json
```

### Step 5: Re-establish Replication
```bash
# Re-create Global Database
aws rds create-global-cluster \
  --global-cluster-identifier <global-cluster-id> \
  --source-db-cluster-identifier <primary-cluster> \
  --region eu-west-1

# Attach DR cluster as secondary
aws rds create-db-cluster \
  --db-cluster-identifier <dr-cluster> \
  --global-cluster-identifier <global-cluster-id> \
  --region eu-west-2
```

---

## Monitoring & Alerts

### CloudWatch Dashboards

#### DR Health Dashboard
- Primary region health check status
- Aurora replication lag
- S3 replication metrics
- ECR replication status
- Route 53 query counts

#### Failover Dashboard
- Failover event timeline
- DR scale-up progress
- Application health in DR
- Error rates and latency
- Cost tracking

### Key Metrics to Monitor

| Metric | Threshold | Action |
|--------|-----------|--------|
| **Aurora Replication Lag** | > 5 seconds | Alert DBA team |
| **S3 Replication Lag** | > 15 minutes | Check replication rules |
| **Health Check Failures** | 3 consecutive | Trigger investigation |
| **DR RDS CPU** | > 80% (pilot light) | Something's wrong |
| **DR EKS Nodes** | > 0 (pilot light) | Check auto-scaling |
| **Route 53 Queries** | Sudden spike to DR | Possible failover |

### SNS Alerts

```hcl
# Configured SNS topics
- dr-failover-notifications      # Failover events
- dr-health-alerts                # Health check failures
- dr-replication-lag-alerts       # Data sync issues
- dr-scale-up-notifications       # Auto-scaling events
```

---

## Testing & Validation

### Quarterly DR Tests (Required)

#### Test 1: Failover Test (Non-Prod)
**Frequency**: Quarterly
**Duration**: 4 hours
**Objective**: Validate automatic failover

```bash
# 1. Simulate primary region failure
aws route53 change-resource-record-sets --simulate-failure

# 2. Verify automatic failover
# 3. Validate application functionality
# 4. Measure RTO/RPO
# 5. Perform failback
# 6. Document results
```

#### Test 2: Data Integrity Test
**Frequency**: Monthly
**Duration**: 2 hours
**Objective**: Validate data replication

```bash
# 1. Create test data in primary
# 2. Wait for replication
# 3. Query DR region
# 4. Compare checksums
# 5. Document lag times
```

#### Test 3: Scale-Up Test
**Frequency**: Monthly
**Duration**: 1 hour
**Objective**: Validate DR can scale to production capacity

```bash
# 1. Manually trigger scale-up Lambda
# 2. Monitor scaling progress
# 3. Validate all resources reach target capacity
# 4. Scale back down
# 5. Measure total time
```

---

## Troubleshooting

### Issue: Aurora Replication Lag High

**Symptoms**: Replication lag > 10 seconds

**Causes**:
- High write volume in primary
- Network issues between regions
- DR instance too small

**Resolution**:
```bash
# Check current lag
aws rds describe-db-clusters \
  --db-cluster-identifier <cluster-id> \
  --query 'DBClusters[0].ReplicaLag'

# Scale up DR instance temporarily
aws rds modify-db-instance \
  --db-instance-identifier <dr-instance> \
  --db-instance-class db.r6g.large \
  --apply-immediately
```

---

### Issue: Failover Lambda Fails

**Symptoms**: Lambda error in CloudWatch Logs

**Resolution**:
1. Check Lambda execution role permissions
2. Verify environment variables are set
3. Check CloudWatch Logs for specific error
4. Manually execute failover steps
5. Update Lambda code if needed

```bash
# View Lambda logs
aws logs tail /aws/lambda/example-prod-dr-scale-up --follow

# Manual invocation for testing
aws lambda invoke \
  --function-name example-prod-dr-scale-up \
  --payload '{"test": true}' \
  output.json
```

---

### Issue: Route 53 Not Failing Over

**Symptoms**: Health check failing but traffic not switching

**Causes**:
- Failover records not configured correctly
- Health check threshold not met
- DNS caching

**Resolution**:
```bash
# Check health check status
aws route53 get-health-check-status --health-check-id <id>

# Verify failover routing policy
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>

# Force DNS cache clear (client-side)
ipconfig /flushdns  # Windows
sudo dscacheutil -flushcache  # macOS
```

---

## Compliance & Audit

### Required Documentation
- [ ] DR runbook (this document)
- [ ] RTO/RPO targets signed off by business
- [ ] Quarterly DR test reports
- [ ] Incident response procedures
- [ ] Failover authorization matrix
- [ ] Data sovereignty compliance docs

### Audit Checklist
- [ ] DR infrastructure deployed and functional
- [ ] Automated backups configured and tested
- [ ] Cross-region replication verified
- [ ] Health checks operational
- [ ] Monitoring and alerting configured
- [ ] DR tests conducted quarterly
- [ ] Staff trained on DR procedures
- [ ] Documentation up to date

---

## References

### AWS Documentation
- [Aurora Global Database](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-global-database.html)
- [S3 Cross-Region Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
- [Route 53 Health Checks](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-failover.html)
- [Disaster Recovery Whitepaper](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-workloads-on-aws.html)

### Internal Resources
- DR Runbook: This document
- Workspace Guide: `docs/WORKSPACE-GUIDE.md`
- Architecture Diagram: `docs/Network Architecture.md`
- Security Architecture: `docs/Security Architecture.md`

---

## Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024-12-XX | Platform Engineering | Initial DR implementation |

---

## Support & Contacts

**DR Coordinator**: Platform Engineering Lead
**On-Call Team**: SRE Team (PagerDuty)
**Escalation**: CTO
**Email**: dr-team@example.co.uk
