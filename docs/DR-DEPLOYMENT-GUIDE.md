# DR Deployment Quick Start

## Overview

This guide provides step-by-step instructions for deploying the Disaster Recovery (DR) infrastructure across environments.

---

## DR Configuration by Environment

| Environment | DR Enabled | Strategy | RTO | RPO | Failover | Monthly Cost |
|-------------|-----------|----------|-----|-----|----------|--------------|
| **POC** | ❌ No | N/A | N/A | N/A | N/A | $0 |
| **Dev** | ❌ No | N/A | N/A | N/A | N/A | $0 |
| **Staging** | ✅ Yes | Pilot Light | 4 hours | 1 hour | Manual | ~$150 |
| **UAT** | ✅ Yes | Pilot Light | 2 hours | 1 hour | Manual | ~$200 |
| **Prod** | ✅ Yes | Warm Standby | 1 hour | Near-zero | Automatic | ~$1,400 |

---

## Prerequisites

### 1. AWS Accounts
- [ ] Primary region access (eu-west-1)
- [ ] DR region access (eu-west-2)
- [ ] Cross-account roles configured
- [ ] KMS keys for encryption

### 2. Networking
- [ ] Non-overlapping CIDR blocks defined
- [ ] VPC peering/TGW configured
- [ ] DNS zones created
- [ ] Route 53 health checks planned

### 3. Certificates
- [ ] ACM certificates in eu-west-2
- [ ] Same domains as primary region
- [ ] CloudFront certificate in us-east-1

### 4. Terraform
- [ ] Version >= 1.5.0
- [ ] AWS CLI configured
- [ ] PowerShell 7+ installed
- [ ] Lambda packaged (`.\package-dr-lambda.ps1`)

---

## Deployment Steps

### Step 1: Package Lambda Function

```powershell
# Package DR scale-up Lambda
.\package-dr-lambda.ps1
```

**Expected Output:**
```
Packaging DR Scale-Up Lambda function...
✓ Lambda function packaged successfully: lambda/dr-scale-up.zip (12.34 KB)
```

---

### Step 2: Enable DR in Environment Config

Edit the appropriate tfvars file (e.g., `prod.tfvars`):

```hcl
# Disaster Recovery
enable_dr              = true
dr_region              = "eu-west-2"
dr_strategy            = "warm-standby"  # or "pilot-light"
dr_rto_hours           = 1
dr_rpo_hours           = 0
dr_failover_mode       = "automatic"  # or "manual"

# DR VPC CIDRs (must not overlap!)
dr_hub_vpc_cidr             = "10.200.0.0/16"
dr_workload_vpc_cidr        = "10.210.0.0/16"
dr_data_vpc_cidr            = "10.212.0.0/16"
dr_shared_services_vpc_cidr = "10.220.0.0/16"

# DR Sizing
dr_aurora_instance_class    = "db.r6g.large"
dr_aurora_instance_count    = 2
dr_eks_node_desired_size    = 2  # 0 for pilot-light, 2+ for warm-standby
dr_postgres_instance_class  = "db.r6g.large"
```

---

### Step 3: Initialize Terraform with DR Providers

```powershell
# Reinitialize to detect new providers
terraform init -upgrade
```

**Expected Output:**
```
Initializing provider plugins...
- Finding hashicorp/aws versions matching ">= 5.0.0"...
- Installing hashicorp/aws v5.31.0...
✓ Provider plugins installed

Terraform has been successfully initialized!
```

---

### Step 4: Plan DR Deployment

```powershell
# Using workspace manager
.\workspace-manager.ps1 -Action plan -Workspace prod

# Or manually
terraform workspace select prod
terraform plan -var-file="prod.tfvars" -out=tfplan-dr
```

**Review Output:**
- Check for ~200-400 additional DR resources
- Verify CIDR blocks don't overlap
- Confirm Aurora Global Database creation
- Validate S3/ECR replication rules
- Check Route 53 health checks

---

### Step 5: Apply DR Infrastructure

⚠️ **IMPORTANT**: This will create billable resources in DR region!

```powershell
# Using workspace manager
.\workspace-manager.ps1 -Action apply -Workspace prod

# Or manually
terraform apply tfplan-dr
```

**Estimated Time:**
- Pilot Light: 30-45 minutes
- Warm Standby: 45-60 minutes

**Key Resources Created:**
```
✓ DR VPCs (Hub, Workload, Data, Shared Services)
✓ DR Transit Gateway
✓ Aurora Global Database (secondary cluster)
✓ S3 Cross-Region Replication
✓ ECR Replication Configuration
✓ Route 53 Health Checks
✓ CloudWatch Alarms
✓ SNS Topics
✓ Lambda Function (auto-failover)
✓ EventBridge Rules
✓ CloudFront DR Distribution
```

---

### Step 6: Validate DR Deployment

#### 6.1 Check Aurora Global Database

```bash
# Primary cluster
aws rds describe-global-clusters \
  --region eu-west-1 \
  --query 'GlobalClusters[?GlobalClusterIdentifier==`example-prod-workload-global`]'

# DR cluster
aws rds describe-db-clusters \
  --region eu-west-2 \
  --db-cluster-identifier example-prod-dr-workload-cluster
```

**Expected:**
- Primary cluster status: `available`
- DR cluster status: `available`
- Replication lag: < 1 second

---

#### 6.2 Check S3 Replication

```bash
# Check replication configuration
aws s3api get-bucket-replication \
  --bucket example-prod-data-eu-west-1

# Check replication status
aws s3api head-object \
  --bucket example-prod-data-eu-west-1 \
  --key test-file.txt \
  --query 'ReplicationStatus'
```

**Expected:** `COMPLETED` or `REPLICA`

---

#### 6.3 Check Route 53 Health Checks

```bash
# List health checks
aws route53 list-health-checks \
  --query 'HealthChecks[?contains(CallerReference, `example-prod`)].{Id:Id, Status:HealthCheckConfig.Type}'

# Get health check status
aws route53 get-health-check-status \
  --health-check-id <health-check-id>
```

**Expected:** Status = `Healthy`

---

#### 6.4 Check DR Resources

```powershell
# List all DR resources
terraform state list | Select-String "dr_"

# Check specific DR components
terraform state show module.dr_hub_vpc[0].aws_vpc.main
terraform state show aws_rds_cluster.dr_workload[0]
terraform state show aws_route53_health_check.primary_region[0]
```

---

#### 6.5 Test DR Health Check Alarm

```bash
# Manually set alarm to ALARM state (test only!)
aws cloudwatch set-alarm-state \
  --alarm-name "example-prod-primary-region-unhealthy" \
  --state-value ALARM \
  --state-reason "Manual test" \
  --region eu-west-1

# Check if SNS notification was sent
# Check if Lambda was triggered (if automatic failover)

# Reset alarm
aws cloudwatch set-alarm-state \
  --alarm-name "example-prod-primary-region-unhealthy" \
  --state-value OK \
  --state-reason "Test complete" \
  --region eu-west-1
```

---

## Post-Deployment Tasks

### 1. Subscribe to SNS Topics

```bash
# DR Failover Notifications
aws sns subscribe \
  --topic-arn arn:aws:sns:eu-west-2:<account-id>:example-prod-dr-failover-notifications \
  --protocol email \
  --notification-endpoint ops-team@example.com

# Confirm subscription via email
```

### 2. Configure CloudWatch Dashboards

```bash
# Access DR monitoring dashboard
aws cloudwatch get-dashboard \
  --dashboard-name example-prod-dr-monitoring \
  --region eu-west-2
```

Add to your monitoring tools:
- Primary region health
- Aurora replication lag
- S3 replication status
- DR resource utilization

### 3. Document Runbooks

Create/update:
- [ ] DR Failover Procedure
- [ ] DR Failback Procedure
- [ ] DR Testing Schedule
- [ ] Emergency Contact List
- [ ] RTO/RPO Validation Results

### 4. Schedule DR Tests

Add to calendar:
- [ ] Monthly: Data integrity verification
- [ ] Quarterly: Full failover test (non-prod)
- [ ] Semi-annually: Full failover test (prod)
- [ ] Annually: DR audit and documentation review

---

## Monitoring DR Health

### CloudWatch Metrics to Monitor

```bash
# Aurora Replication Lag
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name AuroraGlobalDBReplicationLag \
  --dimensions Name=DBClusterIdentifier,Value=example-prod-dr-workload-cluster \
  --statistics Average \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --region eu-west-2

# S3 Replication
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name ReplicationLatency \
  --dimensions Name=SourceBucket,Value=example-prod-data-eu-west-1 \
  --statistics Average \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --region eu-west-1

# Health Check Status
aws cloudwatch get-metric-statistics \
  --namespace AWS/Route53 \
  --metric-name HealthCheckStatus \
  --dimensions Name=HealthCheckId,Value=<health-check-id> \
  --statistics Minimum \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60
```

---

## Cost Monitoring

### Daily Cost Check

```bash
# DR region costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -d '7 days ago' +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter file://dr-cost-filter.json
```

**dr-cost-filter.json:**
```json
{
  "Dimensions": {
    "Key": "REGION",
    "Values": ["eu-west-2"]
  }
}
```

### Expected Costs by Strategy

**Pilot Light (Staging/UAT):**
- VPC & Networking: $20-50/month
- Aurora Global DB: $100-150/month
- S3 Replication: $10-30/month
- Health Checks & Alarms: $5-10/month
- **Total: ~$135-240/month**

**Warm Standby (Production):**
- VPC & Networking: $100-200/month
- Aurora Global DB: $600-800/month
- EKS Cluster (minimal nodes): $150-300/month
- S3 Replication: $50-100/month
- CloudFront (disabled): $0/month
- Health Checks & Alarms: $10-20/month
- **Total: ~$910-1,420/month**

---

## Troubleshooting

### Issue: Aurora Replication Not Starting

**Check:**
```bash
# Verify global cluster
aws rds describe-global-clusters \
  --global-cluster-identifier example-prod-workload-global

# Check DR cluster status
aws rds describe-db-clusters \
  --db-cluster-identifier example-prod-dr-workload-cluster \
  --region eu-west-2
```

**Fix:**
- Ensure primary cluster is part of global cluster
- Verify DR cluster is attached to global cluster
- Check IAM permissions for cross-region replication
- Verify KMS key policies allow cross-region use

---

### Issue: S3 Replication Not Working

**Check:**
```bash
# Verify replication configuration
aws s3api get-bucket-replication \
  --bucket <source-bucket>

# Check replication metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/S3 \
  --metric-name OperationsFailedReplication \
  --dimensions Name=SourceBucket,Value=<source-bucket> \
  --statistics Sum \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600
```

**Fix:**
- Ensure versioning is enabled on both buckets
- Verify IAM role has proper permissions
- Check destination bucket policies
- Ensure KMS keys are multi-region or properly shared

---

### Issue: Lambda Function Not Triggering

**Check:**
```bash
# View Lambda logs
aws logs tail /aws/lambda/example-prod-dr-scale-up \
  --follow \
  --region eu-west-2

# Check EventBridge rule
aws events describe-rule \
  --name example-prod-dr-failover-trigger \
  --region eu-west-2

# Verify targets
aws events list-targets-by-rule \
  --rule example-prod-dr-failover-trigger \
  --region eu-west-2
```

**Fix:**
- Verify EventBridge rule is enabled
- Check Lambda permissions (allow EventBridge invocation)
- Ensure CloudWatch alarm name matches EventBridge pattern
- Review Lambda execution role permissions

---

## Rollback Procedure

If DR deployment fails or needs rollback:

### 1. Document Current State
```powershell
# Export current state
terraform show -json > pre-rollback-state.json

# List all resources
terraform state list > pre-rollback-resources.txt
```

### 2. Destroy DR Resources

⚠️ **WARNING**: This will delete all DR infrastructure!

```powershell
# Target DR resources only
terraform destroy \
  -target=module.dr_hub_vpc \
  -target=module.dr_workload_vpc \
  -target=module.dr_data_vpc \
  -target=module.dr_shared_services_vpc \
  -target=aws_rds_global_cluster.workload \
  -target=aws_route53_health_check.primary_region \
  -var-file="prod.tfvars"

# Or destroy all with DR disabled
terraform apply -var="enable_dr=false" -var-file="prod.tfvars"
```

### 3. Revert Configuration

```hcl
# In prod.tfvars
enable_dr = false
```

### 4. Clean State

```powershell
terraform state rm module.dr_hub_vpc[0]
terraform state rm module.dr_workload_vpc[0]
# ... etc
```

---

## Next Steps

After successful DR deployment:

1. **✅ Schedule Quarterly DR Test**
   - Book maintenance window
   - Notify stakeholders
   - Prepare test plan

2. **✅ Update Documentation**
   - DR runbook customization
   - Contact list updates
   - Architecture diagrams

3. **✅ Train Team**
   - Failover procedures
   - Monitoring dashboards
   - Incident response

4. **✅ Compliance Review**
   - Document RTO/RPO
   - Audit trail setup
   - Disaster recovery policy

---

## Support

**Documentation:**
- Full DR Guide: `docs/DISASTER-RECOVERY.md`
- Architecture: `docs/Network Architecture.md`
- Workspace Guide: `docs/WORKSPACE-GUIDE.md`

**Contacts:**
- DR Coordinator: Platform Engineering Lead
- On-Call: SRE Team (PagerDuty)
- Email: dr-team@example.com

---

## Checklist

### Pre-Deployment
- [ ] Lambda function packaged
- [ ] tfvars file updated with DR config
- [ ] CIDR blocks verified (no overlap)
- [ ] ACM certificates created in DR region
- [ ] Cross-account roles configured
- [ ] Team notified of deployment

### During Deployment
- [ ] `terraform init -upgrade` successful
- [ ] `terraform plan` reviewed
- [ ] `terraform apply` successful
- [ ] No errors in output

### Post-Deployment
- [ ] Aurora Global Database active
- [ ] S3 replication configured
- [ ] ECR replication configured
- [ ] Route 53 health checks active
- [ ] CloudWatch alarms configured
- [ ] SNS subscriptions confirmed
- [ ] Monitoring dashboards configured
- [ ] DR test scheduled
- [ ] Documentation updated
- [ ] Team trained

### Validation
- [ ] Aurora replication lag < 5 seconds
- [ ] S3 replication working
- [ ] Health checks passing
- [ ] Alarms not triggering
- [ ] Cost tracking enabled
- [ ] Runbooks documented

---

**DR Infrastructure is now deployed and ready! 🚀**

Remember to:
- Monitor replication lag daily
- Test failover quarterly
- Review costs monthly
- Update documentation as needed
