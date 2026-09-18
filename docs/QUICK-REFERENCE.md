# Terraform Workspace Quick Reference

## 🚀 Common Commands

### **Setup & Initialization**
```powershell
# First time setup
terraform init

# List workspaces
.\workspace-manager.ps1 -Action list
# OR
terraform workspace list
```

### **Create & Switch Workspaces**
```powershell
# Create POC workspace
.\workspace-manager.ps1 -Action create -Workspace poc

# Switch to POC workspace
.\workspace-manager.ps1 -Action switch -Workspace poc
# OR
terraform workspace select poc

# Show current workspace
.\workspace-manager.ps1 -Action current
# OR
terraform workspace show
```

### **Plan & Apply**
```powershell
# Plan POC changes
.\workspace-manager.ps1 -Action plan -Workspace poc
# OR
terraform workspace select poc
terraform plan -var-file="poc.tfvars" -out=tfplan-poc

# Apply POC changes
.\workspace-manager.ps1 -Action apply -Workspace poc
# OR
terraform workspace select poc
terraform apply tfplan-poc
```

### **Manual Operations (if needed)**
```powershell
# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Show outputs
terraform output

# Show state
terraform show

# Refresh state
terraform refresh -var-file="poc.tfvars"
```

---

## 📁 File Structure Quick Reference

```
├── poc.tfvars              # POC: VPN/EKS disabled, minimal sizing
├── dev.tfvars              # Dev: All features enabled, small sizing
├── staging.tfvars          # Staging: Production-like, medium sizing
├── uat.tfvars              # UAT: Full features, large sizing
├── prod.tfvars             # Prod: Full features, large sizing, protections

├── terraform.tfstate.d/    # Workspace state files (auto-created)
│   ├── poc/
│   ├── dev/
│   ├── staging/
│   ├── uat/
│   └── prod/
```

---

## 🎯 Feature Flags in tfvars Files

### **POC Configuration** (`poc.tfvars`)
```hcl
enable_client_vpn = false  # Disabled (no Okta SAML)
enable_eks        = false  # Disabled (complex dependencies)
enable_msk        = false  # Disabled (not needed for core networking)
enable_airflow    = false  # Disabled (not needed for core networking)
```

### **Dev/Staging/UAT/Prod Configuration**
```hcl
enable_client_vpn = true   # Enabled with Okta SAML
enable_eks        = true   # Enabled with node groups
enable_msk        = true   # Enabled with brokers
enable_airflow    = true   # Enabled with MWAA
```

---

## 🔄 Typical Workflow

### **1. Deploy POC** ⭐
```powershell
# Initialize (first time only)
terraform init

# Create POC workspace
.\workspace-manager.ps1 -Action create -Workspace poc

# Plan
.\workspace-manager.ps1 -Action plan -Workspace poc

# Review plan output carefully

# Apply
.\workspace-manager.ps1 -Action apply -Workspace poc

# Verify
terraform output
```

### **2. Test POC** 🧪
```powershell
# Still on POC workspace
terraform workspace show  # Should show "poc"

# Test connectivity, routing, etc.

# Make changes to poc.tfvars if needed
# Re-plan and re-apply
.\workspace-manager.ps1 -Action plan -Workspace poc
.\workspace-manager.ps1 -Action apply -Workspace poc
```

### **3. Promote to Dev** 🚀
```powershell
# Create dev workspace
.\workspace-manager.ps1 -Action create -Workspace dev

# Update dev.tfvars (enable additional features)
# enable_client_vpn = true
# enable_eks = true

# Plan dev deployment
.\workspace-manager.ps1 -Action plan -Workspace dev

# Apply dev configuration
.\workspace-manager.ps1 -Action apply -Workspace dev
```

### **4. Switch Between Environments** 🔄
```powershell
# Work on POC
.\workspace-manager.ps1 -Action switch -Workspace poc
terraform plan -var-file="poc.tfvars"

# Switch to dev
.\workspace-manager.ps1 -Action switch -Workspace dev
terraform plan -var-file="dev.tfvars"

# Switch to prod
.\workspace-manager.ps1 -Action switch -Workspace prod
terraform plan -var-file="prod.tfvars"
```

---

## ⚠️ Safety Checklist

Before running commands, always:

- [ ] Verify current workspace: `terraform workspace show`
- [ ] Verify you're using correct tfvars file
- [ ] Review the plan output carefully
- [ ] Check estimated costs (especially for prod)
- [ ] Ensure you have backups (for destroy operations)
- [ ] Get approval (for prod changes)

---

## 🔥 Emergency Commands

### **Rollback Last Change**
```powershell
# If you just applied a bad change
terraform workspace select <workspace>
terraform state list  # See what was created
terraform destroy -target=<resource>  # Destroy specific resource

# Or restore from backup
# Copy previous state file from backup
```

### **Force Unlock State**
```powershell
# If state is locked and process died
terraform force-unlock <lock-id>
```

### **Destroy Entire Workspace**
```powershell
# ⚠️ DANGER: This destroys ALL resources in the workspace!
.\workspace-manager.ps1 -Action destroy -Workspace poc

# Or manually
terraform workspace select poc
terraform destroy -var-file="poc.tfvars"
```

---

## 📊 Quick Comparison

| Aspect | POC | Dev | Prod |
|--------|-----|-----|------|
| **Client VPN** | ❌ | ✅ | ✅ |
| **EKS** | ❌ | ✅ | ✅ |
| **MSK** | ❌ | ✅ | ✅ |
| **Airflow** | ❌ | ✅ | ✅ |
| **RDS** | Single-AZ | Single-AZ | Multi-AZ |
| **Instance Size** | Minimal | Small | Large |
| **Cost/month** | ~$300-500 | ~$800-1,200 | ~$3,000-5,000 |
| **Resources** | ~600 | ~839 | ~850 |

---

## 📚 Documentation Links

- **Detailed Workspace Guide**: [WORKSPACE-GUIDE.md](./WORKSPACE-GUIDE.md)
- **POC Changes History**: [POC-CHANGES.md](./POC-CHANGES.md)
- **Main README**: [README.md](./README.md)
- **Security Architecture**: [Security Architecture.md](./Security Architecture.md)
- **Network Architecture**: [Network Architecture.md](./Network Architecture.md)

---

## 💡 Pro Tips

1. **Always use workspace-manager.ps1** - It handles workspace switching and tfvars files automatically
2. **Create workspaces before switching** - Can't switch to non-existent workspace
3. **Keep tfvars files in sync** - Use version control to track changes
4. **Tag resources with workspace name** - Makes it easy to identify resources
5. **Use workspace-specific plan files** - Name them `tfplan-poc`, `tfplan-dev`, etc.
6. **Never manually edit state files** - Use `terraform state` commands instead
7. **Back up state files regularly** - Especially before major changes
8. **Test in POC first** - Always validate changes in POC before deploying to prod

---

## 🆘 Getting Help

```powershell
# Workspace manager help
.\workspace-manager.ps1 -?

# Terraform help
terraform -help
terraform workspace -help
terraform plan -help
terraform apply -help

# Read documentation
cat docs\WORKSPACE-GUIDE.md
cat docs\README.md
```

---

**Keep this file handy for daily operations! 📌**
