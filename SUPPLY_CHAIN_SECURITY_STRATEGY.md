# Supply Chain Attack Prevention Strategy for AWS CI/CD Pipelines

## 🎯 Quick Answer: The #1 Defense Strategy

**Replace long-lived credentials with short-lived tokens (OIDC Federation):**
- ✅ **Tokens expire in 1 hour** (automatically, no manual rotation)
- ✅ **Generated dynamically** for each CI/CD workflow run
- ✅ **Nothing stored** - No PATs, no access keys, no credentials to steal
- ✅ **Would have completely prevented** the Trivy/TeamCity attack

**Implementation Time:** 1-2 hours | **Cost:** $0 | **Risk Reduction:** 90%+

---

## Executive Summary
Based on the Trivy/TeamCity supply chain attack (Wiz Security, 2024), this document outlines a comprehensive defense-in-depth strategy to prevent similar incidents in CI/CD pipelines deploying to AWS.

**Attack Summary:** Attackers compromised a TeamCity server, stole credentials (PAT tokens), and injected malicious code into Trivy scanner images, affecting thousands of organizations.

### 📊 Credential Lifespan Comparison

| Credential Type | Lifespan | Stored Location | If Stolen, Attacker Has | **Recommendation** |
|----------------|----------|-----------------|-------------------------|--------------------|
| AWS Access Keys | **Forever** (until manually rotated) | CI/CD config files | Unlimited access from anywhere | ❌ **MIGRATE AWAY** |
| Personal Access Tokens (PAT) | **1-2 years** | GitHub/GitLab/TeamCity | Access until token expires or manually revoked | ❌ **MIGRATE AWAY** |
| Service Account Keys | **90+ days** | Config files, K8s secrets | Long-term access | ❌ **MIGRATE AWAY** |
| **OIDC Tokens (Recommended)** | **1 hour** (auto-expires) | **Nowhere (generated on-demand)** | **Max 1 hour access, only for specific workflow** | ✅ **USE THIS** |

**Key Insight:** If attackers compromise your CI/CD system:
- With long-lived credentials: **They own your AWS account forever**
- With OIDC (1-hour tokens): **They have nothing useful to steal**

---

## 1. CREDENTIAL & IDENTITY MANAGEMENT

### 1.1 Multi-Factor Authentication (MFA) - YOUR CORRECT INSTINCT ✓
**Critical Priority for HUMAN Access**

**IMPORTANT CLARIFICATION:** MFA (phone codes, authenticator apps) only works for **human users**. CI/CD automation systems cannot respond to MFA prompts. For CI/CD, we use **OIDC federation** (Section 1.2) which provides cryptographic identity proof instead.

#### Implementation for Human Access:
- **Enforce MFA on ALL human identities:**
  - AWS IAM users (root and all human IAM users)
  - CI/CD platform admin accounts (GitHub/GitLab/TeamCity admins)
  - Container registry admin access (ECR, Docker Hub, Artifactory)
  - Cloud provider consoles
  - VPN/Bastion access

- **Hardware Security Keys (Preferred):**
  ```
  - YubiKey, Titan Security Keys for high-privilege accounts
  - FIDO2/WebAuthn protocols
  - Eliminates phishing risk
  ```

- **Conditional Access Policies:**
  - Require MFA for privileged operations
  - Geographic restrictions
  - Device compliance checks

#### AWS Specific:
```bash
# Enable MFA for AWS IAM users
aws iam enable-mfa-device --user-name <username> --serial-number <arn> --authentication-code1 <code1> --authentication-code2 <code2>

# Enforce MFA with IAM policies
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "DenyAllExceptListedIfNoMFA",
    "Effect": "Deny",
    "NotAction": [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken"
    ],
    "Resource": "*",
    "Condition": {
      "BoolIfExists": {
        "aws:MultiFactorAuthPresent": "false"
      }
    }
  }]
}
```

### 1.2 Eliminate Long-Lived Credentials - Use OIDC Federation for CI/CD
**The Root Cause of Trivy Attack + The Primary Defense**

**THIS IS THE #1 MOST IMPORTANT SECURITY CONTROL**

**Why CI/CD Can't Use Traditional MFA:**
CI/CD pipelines are automated systems that run without human interaction. They cannot:
- ❌ Respond to "Enter your phone code" prompts
- ❌ Click "Approve" on push notifications
- ❌ Scan fingerprints or faces

**The Solution: Passwordless Authentication (OIDC Federation)**
Instead of passwords + MFA codes, CI/CD systems prove their identity cryptographically:
- ✅ **Cryptographic proof** - GitHub/GitLab signs a JWT token that can't be forged
- ✅ **Identity-constrained** - Only specific repos/workflows can assume AWS roles
- ✅ **Time-bound** - Credentials auto-expire in 1 hour
- ✅ **Nothing to steal** - No PATs, no access keys, no credentials stored anywhere
- ✅ **Fully auditable** - CloudTrail shows exactly which workflow made each API call

#### How the Trivy Attack Would Have Been Stopped:

**What Attackers Stole from TeamCity:**
```bash
# Long-lived credentials stored in TeamCity:
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=abc123...
GITHUB_PAT=ghp_...

# These credentials:
# ✗ Work from anywhere in the world
# ✗ Never expire (until manually rotated)
# ✗ Give full access to AWS resources
# ✗ Can't be traced back to specific workflow
```

**With OIDC Federation (Nothing to Steal):**
```yaml
# What's stored in GitHub Actions (just config, no secrets):
role-to-assume: arn:aws:iam::123456789:role/DeployRole
aws-region: us-east-1

# Attackers gain nothing because:
# ✓ No credentials stored anywhere
# ✓ Can't forge GitHub's cryptographic signature
# ✓ AWS only trusts tokens from specific GitHub workflows
# ✓ Even if they intercept a token, it expires in 1 hour
# ✓ AWS logs show exactly which repo/workflow made the call
```

#### Problems with Personal Access Tokens (PATs) & Access Keys:
- ✗ No expiration (or very long-lived)
- ✗ Stored in plain text in CI/CD systems (TeamCity, Jenkins, etc.)
- ✗ No audit trail of actual usage
- ✗ Cannot be rotated without breaking pipelines
- ✗ If stolen, attacker has unlimited access from anywhere
- ✗ **This is exactly what the Trivy attackers exploited**

#### Solution: OIDC Federation (Passwordless Authentication for Automation)

**A. AWS IAM Roles for Service Accounts (IRSA) - Kubernetes**
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cicd-service-account
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT_ID:role/CICD-Role
---
# Pod automatically gets temporary credentials (auto-rotated)
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: cicd-service-account
```

**B. OIDC Federation (GitHub Actions, GitLab CI, etc.)**
```yaml
# GitHub Actions example - NO STORED CREDENTIALS
name: Deploy to AWS
on: push

permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
          aws-region: us-east-1
          # NO access keys! Uses OIDC token exchange
```

**C. AWS IAM Role Configuration for OIDC:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR-ORG/YOUR-REPO:*"
        }
      }
    }
  ]
}
```

**How OIDC Works (The "Multiple Factors" for CI/CD):**
1. **Factor 1: Cryptographic Identity** - GitHub signs JWT with private key (can't be forged)
2. **Factor 2: Specific Repository** - AWS only trusts tokens from `MyOrg/MyRepo:main`
3. **Factor 3: Trusted Issuer** - AWS verifies GitHub's signature (not some random server)
4. **Factor 4: Time-Bound** - Token expires in 1 hour automatically
5. **Factor 5 (Optional): Network** - Can restrict to GitHub's IP ranges

**Benefits:**
- ✓ **Zero stored credentials** - Nothing to steal from CI/CD config
- ✓ **Credentials expire in 1 hour** - Even if intercepted, useless after 60 minutes
- ✓ **Automatic rotation** - New token for each workflow run
- ✓ **Scoped to specific repositories/branches** - Can't be used by other repos
- ✓ **Audit trail** - CloudTrail shows exact GitHub workflow that made each AWS API call
- ✓ **Would have prevented Trivy attack** - Attackers would have found nothing to steal

**⏱️ Token Lifecycle (The "1-Hour" Strategy):**
```
Time: 00:00  GitHub Actions workflow starts
      00:01  Workflow requests: "I need to deploy to AWS"
      00:02  GitHub signs JWT: "This is MyOrg/MyRepo on branch main"
      00:03  AWS verifies signature: "Yes, I trust this GitHub workflow"
      00:04  AWS issues temporary credentials (Access Key + Secret + Session Token)
             ⚠️ These expire at 01:04 (exactly 1 hour later)
      00:05  Workflow uses credentials to deploy to S3, ECS, etc.
      00:45  Deployment completes successfully
      00:46  Workflow ends, credentials discarded

      [If attacker stole credentials at 00:30]
      00:31  Attacker tries to use stolen credentials ✓ Works (for now)
      01:05  Credentials auto-expire ✓ Attacker's access cut off
      01:06  Attacker has worthless expired tokens

      [Next workflow run at 02:00]
      02:00  Completely NEW credentials generated (different Access Key)
      02:01  Old stolen credentials are permanently useless
```

**Why This Works:**
1. **Attacker steals TeamCity config** → Finds... nothing (no credentials stored)
2. **Attacker compromises CI/CD mid-workflow** → Gets credentials valid for < 1 hour
3. **Attacker tries to reuse credentials next day** → Expired, worthless
4. **Attacker tries to use credentials from different location** → AWS logs "This doesn't match the workflow identity" + GuardDuty alert

### 1.3 Credential Rotation Policy (Legacy - Migrate to OIDC Instead)
**⚠️ WARNING:** Even with rotation, long-lived credentials are vulnerable. Migrate to OIDC (Section 1.2) instead.

**Comparison: Manual Rotation vs OIDC Auto-Expiry:**
```
Manual Rotation (Old Way):
- Day 1: Create AWS Access Key → Valid until Day 90
- Day 90: Manually rotate → Update all CI/CD configs → Hope nothing breaks
- If compromised on Day 45: Attacker has 45 days of access
- Human error: "I'll rotate next week..." → Never happens

OIDC Auto-Expiry (New Way):
- Hour 1: Token created → Valid until Hour 2
- Hour 2: Token expires automatically → No human action needed
- If compromised at Hour 1:30: Attacker has 30 minutes max
- Zero human effort: Fully automatic
```

If you MUST use long-lived credentials temporarily during migration:

```bash
# Automate rotation every 30-90 days
# Store in AWS Secrets Manager with automatic rotation

aws secretsmanager rotate-secret \
  --secret-id prod/cicd/credentials \
  --rotation-lambda-arn arn:aws:lambda:region:account:function:RotateSecret

# But seriously, migrate to OIDC instead. It takes 1-2 hours.
```

### 1.4 Least Privilege Access
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DeploySpecificResourcesOnly",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::my-deployment-bucket/*",
      "Condition": {
        "StringEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}
```

**Apply:**
- Separate roles per environment (dev/staging/prod)
- Separate roles per service/application
- Time-based restrictions (working hours only)
- IP allowlisting where possible

---

## 2. ENVIRONMENT ISOLATION - YOUR CORRECT INSTINCT ✓

### 2.1 Multi-Environment Strategy (Dev → Staging → Production)

**Why This Prevents Supply Chain Attacks:**
- Malicious code detected in dev/staging before production impact
- Different credentials per environment (breach doesn't cascade)
- Time to detect anomalies before production deployment

#### Implementation Architecture:
```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│ DEV Account │ -->  │ STAGING Acc │ -->  │ PROD Account│
│ AWS Acc 111 │      │ AWS Acc 222 │      │ AWS Acc 333 │
└─────────────┘      └─────────────┘      └─────────────┘
     │                     │                     │
     ├─ Fast deploys       ├─ Automated tests    ├─ Manual approval
     ├─ Loose security     ├─ Security scans     ├─ Strict security
     ├─ Dev IAM roles      ├─ Staging IAM roles  ├─ Prod IAM roles
     └─ Test data          └─ Sanitized data     └─ Real data
```

#### CI/CD Pipeline with Gated Promotions:
```yaml
# Example: GitHub Actions Multi-Environment
name: Multi-Environment Deploy

on:
  push:
    branches: [develop]
  pull_request:
    branches: [main]

jobs:
  deploy-dev:
    runs-on: ubuntu-latest
    environment: development
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::111111111111:role/DevRole
      - run: terraform apply -auto-approve
  
  security-scan:
    needs: deploy-dev
    runs-on: ubuntu-latest
    steps:
      - name: Run Trivy vulnerability scan
        run: trivy image --severity HIGH,CRITICAL myimage:latest
      - name: Run Snyk scan
        run: snyk test --severity-threshold=high
  
  deploy-staging:
    needs: security-scan
    environment: staging
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::222222222222:role/StagingRole
      - run: terraform apply -auto-approve
  
  integration-tests:
    needs: deploy-staging
    runs-on: ubuntu-latest
    steps:
      - run: pytest tests/integration/
  
  deploy-production:
    needs: integration-tests
    environment: production  # Requires manual approval
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::333333333333:role/ProdRole
      - run: terraform apply
```

### 2.2 AWS Account Isolation
**Use AWS Organizations with separate accounts:**

```
Root Organization
├── Security Account (CloudTrail, GuardDuty, Security Hub)
├── Shared Services (CI/CD tools, artifact storage)
├── Development Account
├── Staging Account
└── Production Account
```

**Benefits:**
- Credential compromise in dev doesn't affect prod
- Separate billing and cost tracking
- Different compliance controls per environment
- Use AWS Service Control Policies (SCPs) to enforce boundaries

**Example SCP to prevent credential exfiltration:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": [
        "iam:CreateAccessKey",
        "iam:CreateLoginProfile"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalOrgID": "o-xxxxxxxxxx"
        }
      }
    }
  ]
}
```

---

## 3. SUPPLY CHAIN SECURITY

### 3.1 Container Image Security

#### A. Use Trusted Base Images Only
```dockerfile
# ❌ DON'T USE
FROM ubuntu:latest

# ✓ USE VERIFIED IMAGES
FROM public.ecr.aws/docker/library/ubuntu:22.04
# Or AWS-provided images
FROM public.ecr.aws/amazonlinux/amazonlinux:2023
```

#### B. Image Signing & Verification (Cosign, Notary v2)
```bash
# Sign images
cosign sign --key cosign.key myregistry/myimage:tag

# Verify before deployment
cosign verify --key cosign.pub myregistry/myimage:tag

# Enforce in Kubernetes with admission controller
# Only allow signed images to run
```

#### C. Multi-Layer Scanning Strategy
**Don't rely on ONE scanner (Trivy was compromised!)**

```yaml
# Use multiple scanners in parallel
scan-security:
  parallel:
    scan-trivy:
      - trivy image myimage:latest
    
    scan-grype:
      - grype myimage:latest
    
    scan-snyk:
      - snyk container test myimage:latest
    
    scan-aws-ecr:
      - aws ecr describe-image-scan-findings
```

#### D. Software Bill of Materials (SBOM)
```bash
# Generate SBOM for every build
syft packages myimage:latest -o json > sbom.json

# Store SBOM in artifact repository
# Monitor for newly disclosed vulnerabilities
grype sbom:sbom.json
```

### 3.2 Dependency Security

#### A. Lock File Verification
```bash
# Verify integrity of dependencies
npm ci --audit  # Uses package-lock.json
pip install --require-hashes -r requirements.txt
go mod verify
```

#### B. Private Artifact Repository
```
┌──────────────────────────────────────┐
│  Internet (npm, PyPI, Docker Hub)    │
└────────────────┬─────────────────────┘
                 │
                 ▼
         ┌───────────────┐
         │  Proxy/Cache  │
         │  (Artifactory,│
         │   Nexus, ECR) │
         └───────┬───────┘
                 │ Scan & Approve
                 ▼
         ┌───────────────┐
         │  CI/CD Pull   │
         │  From Here    │
         └───────────────┘
```

**Benefits:**
- Central scanning point
- Cache dependencies (no direct internet access from builds)
- Malicious packages can't be pulled directly

**Example: AWS CodeArtifact**
```bash
# Configure private repository
aws codeartifact create-repository \
  --domain my-domain \
  --repository my-repo

# Configure npm to use it
npm config set registry=https://my-domain-123456789012.d.codeartifact.us-east-1.amazonaws.com/npm/my-repo/
```

### 3.3 Build Environment Security

#### A. Immutable Build Agents
```yaml
# Use ephemeral runners that are destroyed after each build
# GitHub Actions uses fresh VMs automatically
# For self-hosted: Use Kubernetes pods

apiVersion: v1
kind: Pod
metadata:
  name: build-agent
spec:
  restartPolicy: Never  # Single-use
  containers:
  - name: builder
    image: build-agent:v1.0
    securityContext:
      runAsNonRoot: true
      readOnlyRootFilesystem: true
```

#### B. Network Isolation
```
Build Agents
├── No inbound internet access
├── Outbound only through proxy
├── No SSH access
└── Logs sent to centralized SIEM
```

---

## 4. DETECTION & MONITORING

### 4.1 AWS CloudTrail - Monitor ALL API Calls
```bash
# Enable in ALL accounts and regions
aws cloudtrail create-trail \
  --name all-events-trail \
  --s3-bucket-name cloudtrail-logs \
  --is-multi-region-trail \
  --enable-log-file-validation

# Monitor for suspicious activity
# - New IAM users/keys created
# - Assume role from unknown IPs
# - Changes to security groups
# - Unexpected S3 bucket access
```

### 4.2 AWS GuardDuty
```bash
# Enable threat detection
aws guardduty create-detector --enable

# Alerts for:
# - Compromised credentials
# - Unusual API calls
# - Cryptocurrency mining
# - Data exfiltration
```

### 4.3 Runtime Security (Falco, AWS Security Hub)
```yaml
# Falco rule to detect credential access
- rule: Credentials Access
  desc: Detect access to credential files
  condition: >
    open_read and
    (fd.name contains "aws/credentials" or
     fd.name contains ".docker/config.json" or
     fd.name contains ".kube/config")
  output: "Credentials accessed (file=%fd.name user=%user.name container=%container.name)"
  priority: CRITICAL
```

### 4.4 Behavioral Anomaly Detection
```
Baseline Normal Behavior:
- Deployments happen 9am-5pm EST
- From known IP ranges
- By 5 specific IAM roles
- To specific S3 buckets

Alert on:
- Deployment at 3am
- From unknown country
- By newly created role
- To unexpected bucket
```

---

## 5. INCIDENT RESPONSE READINESS

### 5.1 Automated Rollback Capability
```bash
# Tag all deployments
aws deploy create-deployment \
  --application-name myapp \
  --deployment-group-name prod \
  --revision "revisionType=S3,s3Location={bucket=myapp,key=v1.2.3.zip}" \
  --description "Release v1.2.3"

# One-command rollback
aws deploy create-deployment \
  --application-name myapp \
  --deployment-group-name prod \
  --auto-rollback-configuration enabled=true,events=DEPLOYMENT_FAILURE
```

### 5.2 Kill Switch - Emergency Credential Revocation
```bash
#!/bin/bash
# emergency-revoke.sh
# Immediately revoke all CI/CD access

# Attach deny-all policy to CI/CD roles
aws iam put-role-policy \
  --role-name CICD-Role \
  --policy-name EmergencyDeny \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*"
    }]
  }'

# Deactivate all access keys
for key in $(aws iam list-access-keys --user-name cicd-user --query 'AccessKeyMetadata[*].AccessKeyId' --output text); do
  aws iam update-access-key --user-name cicd-user --access-key-id $key --status Inactive
done
```

### 5.3 Forensics Preparation
```
Enable in advance:
- S3 access logging (who accessed artifacts)
- VPC Flow Logs (network traffic)
- CloudTrail log file validation (tamper-proof)
- Snapshot automation (quick restore)
```

---

## 6. IMPLEMENTATION CHECKLIST

### Phase 1: Immediate (Week 1)
- [ ] Enable MFA on all **human** AWS accounts (root + IAM users)
- [ ] Enable MFA on all CI/CD platform **admin** accounts (GitHub/GitLab org owners)
- [ ] Enable CloudTrail in all accounts/regions
- [ ] Enable GuardDuty
- [ ] Audit existing PATs and AWS access keys (prepare migration list)
- [ ] Implement least privilege IAM policies

### Phase 2: Short-term (Month 1)
- [ ] **[CRITICAL]** Migrate primary CI/CD pipeline to OIDC/IRSA (eliminate stored credentials)
- [ ] **[CRITICAL]** Delete all long-lived credentials after OIDC migration
- [ ] Implement multi-environment deployment pipeline (dev/staging/prod)
- [ ] Set up separate AWS accounts per environment
- [ ] Configure AWS Organizations and SCPs
- [ ] Implement container image scanning (multiple tools - don't trust just Trivy!)
- [ ] Set up private artifact repository

### Phase 3: Medium-term (Quarter 1)
- [ ] Implement image signing and verification
- [ ] Deploy runtime security monitoring (Falco)
- [ ] Establish SBOM generation process
- [ ] Create anomaly detection rules
- [ ] Conduct tabletop exercise for compromise scenario
- [ ] Document incident response runbooks

### Phase 4: Ongoing
- [ ] Quarterly access reviews
- [ ] Monthly security scanning updates
- [ ] Continuous monitoring and alerting refinement
- [ ] Annual disaster recovery drills
- [ ] Stay updated on emerging threats

---

## 7. SPECIFIC DEFENSES AGAINST THE TRIVY ATTACK

### What Happened:
1. TeamCity server compromised
2. Attacker stole PAT tokens
3. Injected malicious code into Trivy scanner container images
4. Thousands of organizations pulled compromised images
5. Malware executed during CI/CD scans

### How This Strategy Would Have Prevented It:

| Attack Vector | Defense Mechanism | Why It Works |
|--------------|-------------------|---------------|
| TeamCity compromise | MFA on human admin accounts, network isolation, patching | Attackers can't access admin panel |
| PAT token theft | **OIDC federation (no PATs to steal)** | **Nothing stored = nothing to steal** |
| Container image tampering | Image signing, verification before use | Unsigned images rejected |
| Malicious code execution | Multiple scanners, SBOM comparison, behavioral monitoring | Another scanner catches the malware |
| Production impact | Dev/staging caught it first, separate account credentials | Malware detected before prod |
| Persistence | Immutable infrastructure, automated rollback | Quick recovery |

---

## 8. TERRAFORM/IaC SPECIFIC SECURITY

### A. State File Protection
```hcl
# terraform.tf
terraform {
  backend "s3" {
    bucket         = "terraform-state-prod"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:ACCOUNT:key/KEY-ID"
    dynamodb_table = "terraform-locks"
    
    # Prevent accidental deletion
    versioning     = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "state_bucket" {
  bucket = aws_s3_bucket.terraform_state.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### B. Secrets Management
```hcl
# ❌ NEVER DO THIS
resource "aws_instance" "app" {
  user_data = <<-EOF
    export DB_PASSWORD="hardcoded_password"
  EOF
}

# ✓ DO THIS
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/db/password"
}

resource "aws_instance" "app" {
  iam_instance_profile = aws_iam_instance_profile.app.name
  
  user_data = <<-EOF
    export DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id prod/db/password --query SecretString --output text)
  EOF
}
```

### C. Policy as Code
```hcl
# Use Sentinel or OPA to enforce security policies

# Example: Prevent public S3 buckets
import "tfplan/v2" as tfplan

deny_public_s3 = rule {
  all tfplan.resource_changes as _, rc {
    rc.type is "aws_s3_bucket_acl" implies
    rc.change.after.acl is not "public-read"
  }
}

main = rule {
  deny_public_s3
}
```

---

## 9. COST CONSIDERATIONS

**"But this costs money!"** - So does a breach.

| Security Measure | Approximate Cost | Breach Cost Prevented |
|-----------------|------------------|----------------------|
| GuardDuty | $50-500/month | $4.45M (avg breach cost) |
| Separate AWS accounts | $0 (no charge) | Containment of blast radius |
| CloudTrail | $2-20/month | Forensics, compliance |
| MFA hardware keys | $40/user one-time | Credential theft prevention |
| OIDC (no PATs) | $0 | Massive reduction in attack surface |

**ROI is immediate and enormous.**

---

## 10. CONCLUSION

Your instincts were **100% correct**:

1. **✓ Dev environment before production** - Catches malicious code before impact
2. **✓ MFA connected to identities** - Prevents human credential theft

**CRITICAL CLARIFICATION: "MFA" for CI/CD vs Humans:**

**For Humans:**
- ✅ Traditional MFA (phone codes, authenticator apps)
- ✅ Applied to AWS Console, GitHub/GitLab admin access, VPN
- ✅ Protects against stolen passwords

**For CI/CD Automation (Can't Use Traditional MFA):**
- ✅ OIDC Federation (passwordless, cryptographic identity proof)
- ✅ No stored credentials (PATs, access keys)
- ✅ Credentials auto-expire in 1 hour
- ✅ **This is what would have prevented the Trivy attack**

**Additional critical layers:**
- **[#1 Priority]** Eliminate long-lived credentials (use OIDC/IRSA)
- Multiple scanning tools (don't trust just Trivy!)
- Image signing and verification
- Separate AWS accounts per environment
- Comprehensive monitoring and detection

**The Trivy attack succeeded because:**
- ❌ Organizations stored long-lived PATs/access keys in TeamCity
- ❌ Trusted a single scanner (Trivy itself was compromised)
- ❌ No verification of container image integrity
- ❌ Direct deployment to production
- ❌ No MFA on TeamCity admin access

**This strategy creates defense-in-depth where multiple layers must fail:**

```
Attack Must Bypass All These Layers:

1. MFA on CI/CD admin access → Prevents initial compromise
2. OIDC (no stored credentials) → Nothing to steal even if compromised
3. Multiple scanners → Another tool detects malicious Trivy
4. Image signing → Unsigned malicious images rejected
5. Dev/staging environments → Caught before production
6. Network segmentation → Compromised dev can't reach prod
7. GuardDuty/CloudTrail → Detects unusual API activity
8. Approval gates → Human review catches suspicious changes
```

**Bottom Line:**
- **OIDC Federation = The single most effective defense** (eliminates the attack vector)
- **MFA = Protects the humans who manage CI/CD systems**
- **Multi-environment = Provides time to detect before production impact**
- **Together = Attack becomes practically impossible**

---

## References & Further Reading

- AWS Security Best Practices: https://docs.aws.amazon.com/security/
- CISA Supply Chain Security: https://www.cisa.gov/supply-chain
- NIST SSDF (Secure Software Development Framework): https://csrc.nist.gov/projects/ssdf
- SLSA Framework: https://slsa.dev/
- Wiz Trivy Attack Analysis: https://www.wiz.io/blog/trivy-compromised-teampcp-supply-chain-attack

---

**Document Version:** 1.0  
**Last Updated:** 2025  
**Applicable To:** All AWS CI/CD pipelines (GitHub Actions, GitLab CI, Jenkins, TeamCity, CircleCI, Azure DevOps, etc.)
