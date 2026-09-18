# 🌿 Branch Strategy & Environment Mapping

## 📋 Current Branch Structure

| Branch | Environment | Purpose | Region | Deploy To |
|--------|-------------|---------|--------|-----------|
| **main** | **Production** | Stable, production-ready code | Ireland (eu-west-1) | Production EKS Cluster |
| **staging** | **Staging** | Pre-production testing, mirrors prod | Ireland (eu-west-1) | Staging EKS Cluster |
| **poc** | **POC** | Proof of Concept, experimental features | Ireland (eu-west-1) | POC EKS Cluster |
| **dev** | **Development** | Active development, feature integration | Ireland (eu-west-1) | Dev EKS Cluster |
| **dr-london** | **DR (Disaster Recovery)** | Passive DR environment | London (eu-west-2) | DR EKS Cluster |

---

## 🔄 Deployment Flow

```
Developer → dev → poc → staging → main (Production)
                                    ↓
                              dr-london (sync)
```

### **Step-by-Step Flow:**

1. **Development Phase** (`dev` branch)
   - Developers create feature branches from `dev`
   - Features merged back to `dev` after code review
   - Continuous integration testing
   
2. **Proof of Concept** (`poc` branch)
   - Test new architectures or major changes
   - Business validation
   - Performance testing
   - Merge to `staging` once validated

3. **Staging Phase** (`staging` branch)
   - Final pre-production testing
   - UAT (User Acceptance Testing)
   - Load testing
   - Security scanning
   - Exact mirror of production environment

4. **Production Deployment** (`main` branch)
   - Merge from `staging` only
   - Production-ready, stable code
   - Tagged releases (v1.0.0, v1.1.0, etc.)
   - Blue-green or canary deployments

5. **DR Sync** (`dr-london` branch)
   - Automatically synced from `main`
   - Kept in passive/warm standby
   - Activated during failover scenarios

---

## 📝 Branch Protection Rules

### **main (Production)**
- ✅ Require pull request reviews (minimum 2 approvers)
- ✅ Require status checks to pass
- ✅ Require branches to be up to date
- ✅ Restrict who can push (DevOps/Release Managers only)
- ✅ Require signed commits
- ✅ No force pushes
- ✅ No deletions

### **staging**
- ✅ Require pull request reviews (minimum 1 approver)
- ✅ Require status checks to pass
- ✅ Restrict who can push (Developers + DevOps)

### **poc**
- ⚠️ Lighter restrictions (for experimentation)
- ✅ Require pull request reviews (optional)
- ✅ Allow force pushes (for rebasing)

### **dev**
- ⚠️ Minimal restrictions (active development)
- ✅ Require pull request for feature branches
- ✅ Allow force pushes (for rebasing)

### **dr-london**
- ✅ Same protection as `main`
- ✅ Auto-sync from main (via CI/CD)

---

## 🚀 Working with Branches

### **Switch Between Environments**

```bash
# Development
git checkout dev

# POC Testing
git checkout poc

# Staging
git checkout staging

# Production
git checkout main

# DR Environment
git checkout dr-london
```

### **Create Feature Branch**

```bash
# Always branch from dev
git checkout dev
git pull origin dev
git checkout -b feature/your-feature-name

# Work on your feature
git add .
git commit -m "Add new feature"

# Push to remote
git push origin feature/your-feature-name
```

### **Promote Changes Through Environments**

```bash
# Step 1: Merge feature to dev
git checkout dev
git merge feature/your-feature-name
git push origin dev

# Step 2: Promote dev to poc (for validation)
git checkout poc
git merge dev
git push origin poc

# Step 3: Promote poc to staging (after POC approval)
git checkout staging
git merge poc
git push origin staging

# Step 4: Promote staging to production (after final testing)
git checkout main
git merge staging
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin main --tags

# Step 5: Sync DR (automated or manual)
git checkout dr-london
git merge main
git push origin dr-london
```

---

## 🏷️ Tagging Strategy

### **Version Format:** `vMAJOR.MINOR.PATCH`

```bash
# Production releases
git tag -a v1.0.0 -m "Initial production release"
git tag -a v1.1.0 -m "New feature: Auto-scaling"
git tag -a v1.1.1 -m "Hotfix: Security patch"

# Push tags
git push origin --tags
```

### **Tag Types:**
- **v1.0.0** - Major release (breaking changes)
- **v1.1.0** - Minor release (new features, backward compatible)
- **v1.1.1** - Patch release (bug fixes, security patches)

---

## 🔥 Hotfix Process

For critical production issues:

```bash
# Create hotfix branch from main
git checkout main
git checkout -b hotfix/critical-issue

# Fix the issue
git add .
git commit -m "Hotfix: Fix critical security issue"

# Merge to main
git checkout main
git merge hotfix/critical-issue
git tag -a v1.1.1 -m "Hotfix: Security patch"
git push origin main --tags

# Backport to other branches
git checkout staging
git merge hotfix/critical-issue
git push origin staging

git checkout dev
git merge hotfix/critical-issue
git push origin dev

# Delete hotfix branch
git branch -d hotfix/critical-issue
git push origin --delete hotfix/critical-issue
```

---

## 📊 Environment-Specific Configurations

Each branch should have environment-specific Terraform variable files:

```
terraform/
├── environments/
│   ├── dev/
│   │   └── terraform.tfvars
│   ├── poc/
│   │   └── terraform.tfvars
│   ├── staging/
│   │   └── terraform.tfvars
│   ├── prod/
│   │   └── terraform.tfvars
│   └── dr-london/
│       └── terraform.tfvars
```

---

## 🛡️ Best Practices

### **DO:**
✅ Always create feature branches from `dev`  
✅ Write descriptive commit messages  
✅ Test locally before pushing  
✅ Request code reviews for all PRs  
✅ Keep branches up-to-date with their parent  
✅ Tag all production releases  
✅ Document breaking changes  

### **DON'T:**
❌ Push directly to `main` or `staging`  
❌ Force push to protected branches  
❌ Merge unreviewed code to `main`  
❌ Skip testing in `staging` before `main`  
❌ Delete branches without backups  
❌ Commit secrets or sensitive data  

---

## 🔐 Security Considerations

1. **Secrets Management**
   - Never commit AWS credentials
   - Use AWS Secrets Manager or Parameter Store
   - Rotate credentials regularly

2. **Access Control**
   - Use GitHub Teams for access management
   - Limit `main` branch access to Release Managers
   - Require MFA for all contributors

3. **Audit Trail**
   - All changes tracked via Git history
   - Signed commits for accountability
   - PR reviews documented

---

## 📞 Support

**Questions about branch strategy?**
- Check this document first
- Consult with DevOps team
- Create an issue in GitHub

**Emergency Production Issues?**
- Follow hotfix process above
- Notify on-call DevOps engineer
- Document in incident log

---

## 📅 Last Updated

**Date:** 2025-01-XX  
**Version:** 1.0  
**Maintained by:** DevOps Team

---

**🎯 Remember:** The branch structure ensures safe, predictable deployments. Always follow the promotion flow! 🚀
