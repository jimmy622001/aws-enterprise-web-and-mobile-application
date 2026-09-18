# Architecture Diagrams - Draw.io Files

✅ **FIXED AND WORKING!** All diagrams now use basic shapes that display properly in Draw.io.

## 📁 Files in This Directory

| File | Description | Size | Opens |
|------|-------------|------|-------|
| **1-multi-region-overview.drawio** | High-level overview of Primary + DR | Full page | ✅ YES |
| **2-primary-region-ireland.drawio** | Detailed Ireland (eu-west-1) architecture | Large | ✅ YES |
| **3-dr-region-london.drawio** | Detailed London (eu-west-2) DR architecture | Large | ✅ YES |

---

## 🚀 How to Open (3 Easy Methods)

### Method 1: Online (FASTEST - No Installation) ⭐

1. Go to: **https://app.diagrams.net/**
2. Click: **File → Open from → Device**
3. Select: Any `.drawio` file from this folder
4. ✅ **Done!** The diagram opens immediately

**OR** even faster:
1. Go to: **https://app.diagrams.net/**
2. **Drag and drop** the `.drawio` file onto the webpage
3. ✅ **Done!**

### Method 2: VS Code Extension (Best for Developers)

1. Install extension: **Draw.io Integration** by Henning Dieterichs
2. Open any `.drawio` file in VS Code
3. Edit inline in VS Code
4. ✅ Auto-saves!

### Method 3: Desktop App (Best for Heavy Editing)

1. Download from: https://github.com/jgraph/drawio-desktop/releases
2. Install the desktop application
3. Open `.drawio` files
4. ✅ Full professional editing

---

## 📊 What's in Each Diagram

### 1. Multi-Region Overview (`1-multi-region-overview.drawio`)

**Best for**: Executive presentations, high-level understanding

**Contents**:
- ✅ Global services (Route 53, CloudFront, WAF, CloudWatch, IAM)
- ✅ Primary Region (Ireland) - All 7 VPCs with services
- ✅ DR Region (London) - All 7 DR VPCs in standby
- ✅ Data replication flows (Aurora, S3)
- ✅ 7-step automatic failover process with timing
- ✅ Cost comparisons ($3-5K Primary vs $150-1.4K DR)
- ✅ RTO < 10 min, RPO < 1 sec metrics

**Size**: 1920x1200px (fits on one page)

**Key Features**:
- Side-by-side comparison of Primary and DR
- Clear active/standby status indicators (🟢/🔴)
- Complete failover timeline
- All metrics visible at a glance

---

### 2. Primary Region - Ireland (`2-primary-region-ireland.drawio`)

**Best for**: Technical deep-dives, deployment planning, operations

**Contents**:
- ✅ All 7 VPCs with complete subnet layouts:
  - Hub VPC (10.0.0.0/16) - Central routing, NAT Gateways
  - Inspection VPC (10.1.0.0/16) - Network Firewall, IDS/IPS
  - Workload VPC (10.2.0.0/16) - EKS cluster, node groups
  - Ingress VPC (10.3.0.0/16) - ALB, NLB, API Gateway
  - Data VPC (10.4.0.0/16) - Aurora, Redshift, S3 Data Lake
  - Shared Services VPC (10.5.0.0/16) - CI/CD, ECR, monitoring
  - Private Ingress VPC (10.6.0.0/16) - Client VPN, remote access

- ✅ Transit Gateway with all attachments and routing
- ✅ All data services:
  - Aurora Global Database (PRIMARY WRITER)
  - Redshift cluster (3 nodes)
  - ElastiCache Redis
  - MSK Kafka (3 brokers)
  - S3 Data Lake with CRR
  
- ✅ All compute services:
  - EKS cluster (3 node groups, auto-scaling)
  - Lambda functions (100+)
  - Fargate containers
  - MWAA Airflow

- ✅ Monitoring & Security:
  - CloudWatch (metrics, logs, dashboards)
  - GuardDuty (threat detection)
  - Security Hub (compliance)
  - Config (resource tracking)
  - CloudTrail (audit logs)
  - KMS (encryption)

- ✅ Additional services:
  - DynamoDB Global Tables
  - SNS + SQS
  - EventBridge
  - Step Functions
  - SES Email

**Size**: 1920x1400px (large, detailed)

**Key Features**:
- Every VPC shown with subnet details
- CIDR blocks clearly labeled
- Service types and instance sizes
- Multi-AZ indicators
- Complete resource count (~850 resources)
- Cost estimate ($3,000-5,000/month)

---

### 3. DR Region - London (`3-dr-region-london.drawio`)

**Best for**: DR planning, failover testing, cost optimization

**Contents**:
- ✅ All 7 DR VPCs with different CIDR ranges:
  - DR Hub VPC (10.10.0.0/16) - Minimal routing
  - DR Inspection VPC (10.11.0.0/16) - Firewall STANDBY
  - DR Workload VPC (10.12.0.0/16) - EKS NOT running (saves cost)
  - DR Ingress VPC (10.13.0.0/16) - ALB created, no traffic
  - DR Data VPC (10.14.0.0/16) - Read replicas active
  - DR Shared Services VPC (10.15.0.0/16) - Replicated images/secrets
  - DR Private Ingress VPC (10.16.0.0/16) - VPN NOT deployed

- ✅ Data replication status:
  - Aurora Global Database (READ REPLICA, < 1 sec lag)
  - S3 buckets (CRR active, ~15 min lag)
  - DynamoDB Global Tables (auto-replicating)
  - Cross-region backups (daily snapshots)
  - ECR images (auto-replicated)
  - Secrets Manager (replicated)

- ✅ Automatic failover automation:
  - Route 53 health checks (90 sec detection)
  - CloudWatch alarms (10 sec trigger)
  - Lambda orchestrator (auto-scale all services)
  - Step Functions workflow (sequential deployment)
  - SNS notifications (team alerts)

- ✅ Scaling actions on failover:
  - Promote Aurora to WRITER (60 sec)
  - Deploy EKS cluster (180 sec)
  - Deploy Network Firewall (60 sec)
  - Scale RDS instances (60 sec)
  - Register ALB targets (30 sec)
  - Update Route 53 DNS (60 sec)
  - **Total: < 10 minutes**

**Size**: 1920x1300px (large, detailed)

**Key Features**:
- Clear standby status indicators (❌/⚠️/✅)
- Lambda automation clearly shown
- Complete failover timeline
- Cost breakdown by environment:
  - POC/Dev: $0/month (DR disabled)
  - Staging: $150-240/month (Pilot Light)
  - Production: $920-1,440/month (Warm Standby)
- RTO < 10 min, RPO < 1 sec metrics

---

## 🎨 Diagram Features

### Color Coding (Consistent Across All Diagrams)

| Color | Meaning |
|-------|---------|
| 🟢 Green | Active, Running, Primary |
| 🔴 Red | Standby, Not running, DR |
| 🟡 Yellow | Warning, Manual action needed |
| 🔵 Blue | Networking (VPCs, subnets) |
| 🟣 Purple | Compute (EKS, Lambda) |
| 🟠 Orange | Data services (RDS, S3) |

### Icons & Symbols

| Symbol | Meaning |
|--------|---------|
| ✅ | Active, Working, Enabled |
| ❌ | Disabled, Not running (cost savings) |
| ⚠️ | Standby, Ready to activate |
| 🤖 | Automated action via Lambda |
| 🔐 | Security feature |
| 📊 | Metrics, Monitoring |
| ⚡ | Fast action, Automatic |

---

## 📤 Exporting Diagrams

### For Presentations (PDF)
1. Open diagram in Draw.io
2. **File → Export as → PDF**
3. Settings:
   - ✅ Fit to 1 page (or select custom)
   - ✅ Include all layers
   - ✅ High quality
4. Save

### For Documentation (PNG)
1. Open diagram in Draw.io
2. **File → Export as → PNG**
3. Settings:
   - Width: 3840px (or 300 DPI)
   - ✅ Transparent background (optional)
   - ✅ Include selection only (optional)
4. Save

### For Web (SVG)
1. Open diagram in Draw.io
2. **File → Export as → SVG**
3. Settings:
   - ✅ Embed fonts
   - ✅ Include selection only (optional)
4. Save

---

## ✏️ Editing Diagrams

### Making Changes

1. Open in Draw.io (any method above)
2. Edit as needed
3. **File → Save** (overwrites original)

### Tips for Editing

- **Zoom**: Mouse wheel or View → Zoom
- **Search**: Ctrl+F to find elements
- **Layers**: View → Layers (show/hide sections)
- **Align**: Arrange → Align (align multiple objects)
- **Copy**: Ctrl+C, Ctrl+V (duplicate elements)
- **Format**: Right-click → Edit Style

### Common Tasks

**Add a new VPC**:
1. Copy existing VPC container
2. Paste and reposition
3. Update text (VPC name, CIDR)
4. Update colors if needed

**Add a new service**:
1. Copy similar service box
2. Paste in appropriate VPC
3. Update text
4. Connect with arrows if needed

**Update metrics**:
1. Find metrics box (usually at bottom)
2. Double-click to edit text
3. Update values

---

## 🔍 Troubleshooting

### Diagram won't open

**Problem**: File won't load in Draw.io  
**Solution**: 
- Make sure you're using https://app.diagrams.net/ (not old draw.io URL)
- Try dragging file onto webpage instead of File → Open
- Check file isn't corrupted (should be ~50-200KB)

### Icons not displaying

**Problem**: Some shapes look wrong  
**Solution**: 
- These diagrams use basic shapes (rectangles, ellipses) so this shouldn't happen
- If it does, try reloading the page
- Try opening in desktop app instead of online

### Can't edit

**Problem**: Diagram is read-only  
**Solution**:
- Make sure you opened the file (not just viewing)
- In online version, file opens as editable by default
- In desktop app, check file permissions

### Export fails

**Problem**: Can't export to PDF/PNG  
**Solution**:
- Try different format (PDF vs PNG)
- Reduce diagram size if very large
- Try desktop app instead of online version

---

## 📚 Additional Resources

### Learn Draw.io
- Official docs: https://www.diagrams.net/doc/
- Video tutorials: https://www.youtube.com/c/drawioapp
- Example diagrams: https://www.diagrams.net/example-diagrams

### AWS Architecture
- AWS Architecture Icons: https://aws.amazon.com/architecture/icons/
- AWS Well-Architected: https://aws.amazon.com/architecture/well-architected/
- AWS Reference Architectures: https://aws.amazon.com/architecture/

---

## 🎯 Use Cases by Role

### For Executives
**Use**: `1-multi-region-overview.drawio`  
**Export**: PDF  
**Purpose**: Understand complete architecture, costs, and DR strategy  
**Time**: 5 minutes to review

### For Architects
**Use**: All three diagrams  
**Export**: Keep editable .drawio  
**Purpose**: Design reviews, architecture decisions  
**Time**: 30 minutes comprehensive review

### For Developers
**Use**: `2-primary-region-ireland.drawio`  
**Export**: PNG for wiki  
**Purpose**: Find services, understand connectivity  
**Time**: 10-15 minutes to locate services

### For Operations/SRE
**Use**: `2-primary-region-ireland.drawio` + `3-dr-region-london.drawio`  
**Export**: PDF for runbooks  
**Purpose**: Operations, troubleshooting, DR testing  
**Time**: 20 minutes to create runbook

### For Compliance/Security
**Use**: `2-primary-region-ireland.drawio`  
**Export**: PDF  
**Purpose**: Security reviews, compliance audits  
**Time**: 30 minutes for audit

---

## ✅ Verification Checklist

Before using diagrams in important presentations:

- [ ] Diagram opens without errors
- [ ] All text is readable at 100% zoom
- [ ] Colors are consistent
- [ ] Arrows point to correct targets
- [ ] Metrics are up-to-date
- [ ] CIDR blocks match actual infrastructure
- [ ] Service types/sizes match tfvars
- [ ] Cost estimates are current

---

## 🔄 Keeping Diagrams Updated

### When to Update

Update diagrams when you:
- Add/remove VPCs or services
- Change CIDR blocks
- Modify DR strategy
- Update instance types/sizes
- Change costs significantly
- Add new environments

### How to Update

1. Open relevant diagram
2. Make changes
3. Update metrics/summary boxes
4. Save with same filename
5. Export new PDF/PNG versions
6. Update documentation references

### Version Control

These `.drawio` files are in Git, so:
- Commit changes with clear messages
- Review diffs (Draw.io files are XML)
- Tag releases if needed

---

## 📞 Support

**Questions about diagrams?**
- Check this README first
- See `DOCUMENTATION-INDEX.md` for all docs
- See `docs/DISASTER-RECOVERY.md` for DR architecture details

**Need changes?**
- Edit yourself using methods above
- Open issue/ticket with specific requests
- Include what needs changing and why

---

## 🎉 Summary

You now have **three professional, working Draw.io diagrams** that:
- ✅ Open properly in any Draw.io viewer
- ✅ Use basic shapes (maximum compatibility)
- ✅ Show complete multi-region architecture
- ✅ Include all services, metrics, and costs
- ✅ Are fully editable
- ✅ Can be exported to any format

**Start here**: Open `1-multi-region-overview.drawio` to see the complete picture!

---

**Last updated**: 2024-01-15  
**Diagrams version**: 1.0  
**Compatibility**: All Draw.io versions (online, desktop, VS Code)
