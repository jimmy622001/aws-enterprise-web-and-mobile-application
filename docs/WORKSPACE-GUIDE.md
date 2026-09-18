# Terraform Workspaces Guide

## Overview

This project uses **Terraform Workspaces** to manage multiple environments (POC, Dev, Staging, UAT, Prod) with a **single codebase**. This approach eliminates the need to manually comment/uncomment code sections when switching between environments.

---

## 🎯 Why Workspaces?

### **Problems with Manual Code Changes** ❌
- Manual commenting/uncommenting of code is **error-prone**
- Risk of deploying wrong configuration to production
- Difficult to track what's different between environments
- Merge conflicts when multiple people work on different environments

### **Benefits of Workspaces** ✅
- **Single source of truth**: One codebase for all environments
- **Conditional logic**: Enable/disable features via variables
- **Isolated state files**: Each environment has its own state
- **Easy switching**: Change environments with one command
- **No code modifications**: Switch via tfvars files only

---

## 📁 Workspace Structure

```
project-root/
├── main.tf                    # Main infrastructure code (same for all environments)
├── variables.tf               # Variable definitions with feature flags
├── providers.tf               # Provider configurations
├── outputs.tf                 # Output definitions
│
├── poc.tfvars                 # POC environment variables (VPN/EKS disabled)
├── dev.tfvars                 # Development environment variables
├── staging.tfvars             # Staging environment variables
├── uat.tfvars                 # UAT environment variables
├── prod.tfvars                # Production environment variables
│
├── workspace-manager.ps1      # Workspace management script
│
└── terraform.tfstate.d/       # Workspace state files (auto-created)
    ├── poc/
    │   └── terraform.tfstate
    ├── dev/
    │   └── terraform.tfstate
    ├── staging/
    │   └── terraform.tfstate
    ├── uat/
    │   └── terraform.tfstate
    └── prod/
        └── terraform.tfstate
```

---

## 🚀 Quick Start

### **1. List Available Workspaces**
```powershell
.\workspace-manager.ps1 -Action list
```

### **2. Create POC Workspace**
```powershell
.\workspace-manager.ps1 -Action create -Workspace poc
```

### **3. Switch to POC Workspace**
```powershell
.\workspace-manager.ps1 -Action switch -Workspace poc
```

### **4. Plan POC Deployment**
```powershell
.\workspace-manager.ps1 -Action plan -Workspace poc
```

### **5. Apply POC Configuration**
```powershell
.\workspace-manager.ps1 -Action apply -Workspace poc
```

---

## 🔧 Feature Flags

The project uses **feature flags** in `variables.tf` to conditionally enable/disable major components:

### **Available Feature Flags**

| Feature Flag | Default | POC Value | Description |
|--------------|---------|-----------|-------------|
| `enable_client_vpn` | `true` | **`false`** | Enable Client VPN (requires Okta SAML) |
| `enable_eks` | `true` | **`false`** | Enable EKS cluster deployment |
| `enable_msk` | `true` | **`false`** | Enable Kafka MSK cluster |
| `enable_airflow` | `true` | **`false`** | Enable Apache Airflow (MWAA) |

### **How to Use Feature Flags**

In your `*.tfvars` file:
```hcl
# POC configuration - minimal features
enable_client_vpn = false
enable_eks        = false
enable_msk        = false
enable_airflow    = false

# Dev/Prod configuration - all features
enable_client_vpn = true
enable_eks        = true
enable_msk        = true
enable_airflow    = true
```

---

## 📋 Environment Comparison

| Feature | POC | Dev | Staging | UAT | Prod |
|---------|-----|-----|---------|-----|------|
| **Client VPN** | ❌ Disabled | ✅ Enabled | ✅ Enabled | ✅ Enabled | ✅ Enabled |
| **EKS Cluster** | ❌ Disabled | ✅ Enabled | ✅ Enabled | ✅ Enabled | ✅ Enabled |
| **Kafka MSK** | ❌ Disabled | ✅ Enabled | ✅ Enabled | ✅ Enabled | ✅ Enabled |
| **Airflow** | ❌ Disabled | ✅ Enabled | ✅ Enabled | ✅ Enabled | ✅ Enabled |
| **Multi-AZ RDS** | ❌ Single-AZ | ✅ Multi-AZ | ✅ Multi-AZ | ✅ Multi-AZ | ✅ Multi-AZ |
| **Instance Size** | Minimal | Small | Medium | Large | Large |
| **Deletion Protection** | ❌ Off | ❌ Off | ✅ On | ✅ On | ✅ On |
| **Backup Retention** | 1 day | 7 days | 14 days | 30 days | 30 days |
| **Log Retention** | 1 day | 7 days | 30 days | 90 days | 365 days |
| **Security Hub** | ❌ Disabled | ⚠️ Basic | ✅ Standard | ✅ Full | ✅ Full |
| **GuardDuty** | ❌ Off | ✅ 6-hour | ✅ 1-hour | ✅ 15-min | ✅ 15-min |

---

## 🛠️ Workspace Manager Commands

### **View Commands**
```powershell
# List all workspaces
.\workspace-manager.ps1 -Action list

# Show current workspace
.\workspace-manager.ps1 -Action current
```

### **Workspace Management**
```powershell
# Create a new workspace
.\workspace-manager.ps1 -Action create -Workspace <name>

# Switch to a workspace
.\workspace-manager.ps1 -Action switch -Workspace <name>

# Delete a workspace (cannot delete current/default)
.\workspace-manager.ps1 -Action delete -Workspace <name>
```

### **Terraform Operations**
```powershell
# Plan changes for a workspace
.\workspace-manager.ps1 -Action plan -Workspace <name>

# Apply changes for a workspace
.\workspace-manager.ps1 -Action apply -Workspace <name>

# Apply with auto-approve (USE WITH CAUTION!)
.\workspace-manager.ps1 -Action apply -Workspace poc -AutoApprove

# Destroy workspace resources
.\workspace-manager.ps1 -Action destroy -Workspace <name>
```

---

## 🔄 Common Workflows

### **Workflow 1: Deploy POC from Scratch**
```powershell
# 1. Initialize Terraform (first time only)
terraform init

# 2. Create POC workspace
.\workspace-manager.ps1 -Action create -Workspace poc

# 3. Plan POC deployment
.\workspace-manager.ps1 -Action plan -Workspace poc

# 4. Review the plan output carefully

# 5. Apply POC configuration
.\workspace-manager.ps1 -Action apply -Workspace poc

# 6. Verify deployment
terraform output
```

### **Workflow 2: Migrate POC to Dev**
```powershell
# 1. Create dev workspace
.\workspace-manager.ps1 -Action create -Workspace dev

# 2. Edit dev.tfvars to enable additional features
# enable_client_vpn = true
# enable_eks = true

# 3. Plan dev deployment
.\workspace-manager.ps1 -Action plan -Workspace dev

# 4. Apply dev configuration
.\workspace-manager.ps1 -Action apply -Workspace dev
```

### **Workflow 3: Switch Between Environments**
```powershell
# Working on POC
.\workspace-manager.ps1 -Action switch -Workspace poc
terraform plan -var-file="poc.tfvars"

# Switch to Dev
.\workspace-manager.ps1 -Action switch -Workspace dev
terraform plan -var-file="dev.tfvars"

# Switch to Prod
.\workspace-manager.ps1 -Action switch -Workspace prod
terraform plan -var-file="prod.tfvars"
```

### **Workflow 4: Test Feature in POC, Deploy to Dev**
```powershell
# 1. Test new feature in POC
.\workspace-manager.ps1 -Action switch -Workspace poc
# Edit poc.tfvars to enable feature
.\workspace-manager.ps1 -Action plan -Workspace poc
.\workspace-manager.ps1 -Action apply -Workspace poc

# 2. Verify feature works

# 3. Deploy to dev
.\workspace-manager.ps1 -Action switch -Workspace dev
.\workspace-manager.ps1 -Action plan -Workspace dev
.\workspace-manager.ps1 -Action apply -Workspace dev

# 4. Promote to staging/uat/prod after testing
```

---

## ⚠️ Important Notes

### **State File Isolation**
- Each workspace has its **own state file** in `terraform.tfstate.d/<workspace>/`
- Changes in one workspace **do not affect** other workspaces
- You can **safely test** in POC without affecting Prod

### **Variable Files**
- Always use the correct `.tfvars` file for each workspace
- **POC**: `poc.tfvars` (Client VPN/EKS disabled)
- **Dev**: `dev.tfvars` (All features enabled with minimal sizing)
- **Staging**: `staging.tfvars` (Production-like configuration)
- **UAT**: `uat.tfvars` (User acceptance testing)
- **Prod**: `prod.tfvars` (Full production configuration)

### **Default Workspace**
- Terraform creates a `default` workspace automatically
- **DO NOT USE** the default workspace for deployments
- Always create and use named workspaces (poc, dev, etc.)

### **Workspace Best Practices**
- ✅ **Always verify** current workspace before running commands
- ✅ **Use workspace-manager.ps1** for consistency
- ✅ **Review plans** before applying (especially in prod)
- ✅ **Tag resources** with workspace/environment name
- ❌ **Never** manually edit state files
- ❌ **Never** mix tfvars files (don't use dev.tfvars in prod workspace)

---

## 🔐 Security Considerations

### **POC Environment**
- ❌ **No Client VPN** - No secure remote access (acceptable for POC)
- ❌ **No EKS** - No container orchestration (acceptable for POC)
- ⚠️ **Relaxed Security Hub** - Disabled for cost savings
- ⚠️ **Single-AZ** - No high availability (acceptable for POC)

### **Production Environment**
- ✅ **Client VPN Required** - Secure remote access with Okta SAML
- ✅ **EKS Enabled** - Full container orchestration
- ✅ **Security Hub Enabled** - All compliance frameworks
- ✅ **Multi-AZ** - High availability for all critical components
- ✅ **Deletion Protection** - Prevent accidental resource deletion

---

## 📊 Resource Count by Environment

| Environment | Approximate Resources | Est. Monthly Cost |
|-------------|----------------------|-------------------|
| **POC** | ~600 resources | $300-500 |
| **Dev** | ~839 resources | $800-1,200 |
| **Staging** | ~850 resources | $1,500-2,000 |
| **UAT** | ~850 resources | $1,500-2,000 |
| **Prod** | ~850 resources | $3,000-5,000 |

*Costs are estimates and vary based on actual usage, data transfer, and NAT Gateway usage.*

---

## 🐛 Troubleshooting

### **Issue: "Workspace already exists"**
```powershell
# Solution: Switch to it instead
.\workspace-manager.ps1 -Action switch -Workspace poc
```

### **Issue: "tfvars file not found"**
```powershell
# Solution: Ensure you have the correct .tfvars file
ls *.tfvars

# Create missing tfvars from template
cp dev.tfvars poc.tfvars
# Edit poc.tfvars to set enable_client_vpn = false
```

### **Issue: "Cannot delete current workspace"**
```powershell
# Solution: Switch to a different workspace first
.\workspace-manager.ps1 -Action switch -Workspace default
.\workspace-manager.ps1 -Action delete -Workspace poc
```

### **Issue: "Wrong workspace applied"**
```powershell
# Solution: Always verify current workspace
.\workspace-manager.ps1 -Action current

# Switch to correct workspace
.\workspace-manager.ps1 -Action switch -Workspace <correct-workspace>
```

---

## 🚀 Migration Path: POC → Prod

### **Phase 1: POC (Week 1-2)**
- Deploy core networking (VPCs, TGW, Security Groups)
- Test connectivity between VPCs
- Validate Transit Gateway routing
- **Disabled**: Client VPN, EKS, MSK, Airflow

### **Phase 2: Dev (Week 3-4)**
- Enable all features in Dev
- Add Client VPN with Okta SAML
- Deploy EKS cluster
- Test full application stack
- **Enabled**: All features with minimal sizing

### **Phase 3: Staging (Week 5-6)**
- Production-like configuration
- Full security controls enabled
- Performance testing
- **Enabled**: All features with medium sizing

### **Phase 4: UAT (Week 7-8)**
- User acceptance testing
- Security audits
- Compliance validation
- **Enabled**: All features with production sizing

### **Phase 5: Prod (Week 9+)**
- Full production deployment
- High availability (Multi-AZ)
- All security controls
- Deletion protection enabled
- **Enabled**: All features with production sizing

---

## 📚 Additional Resources

- **POC Changes Documentation**: `docs/POC-CHANGES.md`
- **README**: `docs/README.md`
- **Security Architecture**: `docs/Security Architecture.md`
- **Network Architecture**: `docs/Network Architecture.md`
- **Components Guide**: `docs/Components.md`

---

## ✅ Checklist: Before Deploying to Production

- [ ] POC successfully tested
- [ ] Dev environment validated
- [ ] Staging environment tested
- [ ] UAT sign-off received
- [ ] Security audit completed
- [ ] Disaster recovery plan documented
- [ ] Runbooks created
- [ ] Team trained on operations
- [ ] Monitoring/alerting configured
- [ ] Backup/restore tested
- [ ] Okta SAML integration configured
- [ ] SSL/TLS certificates obtained
- [ ] DNS records configured
- [ ] Cost optimization reviewed
- [ ] Compliance requirements validated

---

**Happy Deploying! 🚀**
