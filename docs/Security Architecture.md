# Security Architecture

## Overview

This document describes the comprehensive security architecture implementing **Defense in Depth** strategy across all layers of the AWS infrastructure.

---

## Defense in Depth

### Layer 1: Edge Security

```
┌─────────────────────────────────────────────────────────────┐
│                      EDGE SECURITY                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐                                       │
│  │ AWS Shield       │ ◄── DDoS Protection (Layer 3/4)       │
│  │ Advanced         │                                       │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ AWS WAF          │ ◄── Web Application Firewall          │
│  │                  │     • AWS Managed Rules               │
│  │                  │     • SQL Injection Prevention        │
│  │                  │     • XSS Protection                  │
│  │                  │     • Rate Limiting                   │
│  │                  │     • Geo-blocking                    │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ CloudFront       │ ◄── Global CDN + TLS 1.3              │
│  │ Distribution     │                                       │
│  └──────────────────┘                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Components**:
- **AWS Shield Advanced**: Automatic DDoS protection at Layer 3/4
- **AWS WAF**: Managed rules for common web exploits
- **CloudFront**: TLS 1.3 termination, geo-restriction, signed URLs

**Key Features**:
- ✅ Automatic DDoS mitigation
- ✅ Real-time threat intelligence
- ✅ Custom WAF rules
- ✅ Rate-based blocking
- ✅ Geographic restrictions

---

### Layer 2: Network Security

```
┌─────────────────────────────────────────────────────────────┐
│                    NETWORK SECURITY                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐                                       │
│  │ Network Firewall │ ◄── Stateful Inspection (All Traffic) │
│  │ (Inspection VPC) │     • Domain Filtering                │
│  │                  │     • IPS/IDS Rules                   │
│  │                  │     • Protocol Detection              │
│  │                  │     • Suricata Rules                  │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ Security Groups  │ ◄── Micro-segmentation                │
│  │ (Stateful)       │     • Least Privilege                 │
│  │                  │     • Application-level Control       │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ Network ACLs     │ ◄── Subnet-level Filtering            │
│  │ (Stateless)      │                                       │
│  └──────────────────┘                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Components**:
- **Network Firewall**: Centralized stateful inspection in Inspection VPC
- **Security Groups**: Application-level micro-segmentation
- **Network ACLs**: Subnet-level boundary protection

**Key Features**:
- ✅ All cross-VPC traffic inspected
- ✅ Domain-based allow/deny lists
- ✅ Intrusion Prevention System (IPS)
- ✅ Protocol detection and enforcement
- ✅ Zero-trust network architecture

---

### Layer 3: Application Security

```
┌─────────────────────────────────────────────────────────────┐
│                  APPLICATION SECURITY                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐                                       │
│  │ Istio Service    │ ◄── mTLS Between All Services         │
│  │ Mesh             │     • Certificate Rotation            │
│  │                  │     • Service-to-Service Auth         │
│  │                  │     • Traffic Encryption              │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ API Gateway      │ ◄── API Authentication                │
│  │                  │     • JWT Validation                  │
│  │                  │     • OAuth 2.0                       │
│  │                  │     • Throttling                      │
│  │                  │     • Request Validation              │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ Cognito User     │ ◄── User Authentication               │
│  │ Pool             │     • MFA (TOTP/SMS)                  │
│  │                  │     • Password Policies               │
│  │                  │     • Account Recovery                │
│  └──────────────────┘                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Components**:
- **Istio Service Mesh**: Automatic mTLS between microservices (when EKS enabled)
- **API Gateway**: Centralized API security and throttling
- **Cognito**: User authentication with MFA support

**Key Features**:
- ✅ Zero-trust service communication
- ✅ Automatic certificate management
- ✅ API request validation
- ✅ Multi-factor authentication
- ✅ JWT token validation

---

### Layer 4: Data Security

```
┌─────────────────────────────────────────────────────────────┐
│                     DATA SECURITY                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐                                       │
│  │ KMS Encryption   │ ◄── Data at Rest                      │
│  │                  │     • EBS Volumes                     │
│  │                  │     • RDS Databases                   │
│  │                  │     • S3 Buckets                      │
│  │                  │     • Secrets Manager                 │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ TLS 1.2+         │ ◄── Data in Transit                   │
│  │                  │     • API Gateway                     │
│  │                  │     • ALB/NLB                         │
│  │                  │     • RDS Connections                 │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ AWS Secrets      │ ◄── Credential Management             │
│  │ Manager          │     • Automatic Rotation              │
│  │                  │     • Audit Logging                   │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ AWS Private CA   │ ◄── Internal Certificate Authority    │
│  │                  │                                       │
│  └──────────────────┘                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Components**:
- **KMS**: Customer-managed keys for encryption at rest
- **TLS 1.2+**: Enforced encryption in transit
- **Secrets Manager**: Secure credential storage with rotation
- **Private CA**: Internal certificate authority

**Key Features**:
- ✅ Encryption at rest for all data stores
- ✅ TLS 1.2+ enforced everywhere
- ✅ Automatic secret rotation
- ✅ Audit trail for secret access
- ✅ HSM-backed key storage

---

### Layer 5: Monitoring & Detection

```
┌─────────────────────────────────────────────────────────────┐
│               MONITORING & DETECTION                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────┐                                       │
│  │ Amazon GuardDuty │ ◄── Threat Detection                  │
│  │                  │     • Malicious IPs                   │
│  │                  │     • Compromised Instances           │
│  │                  │     • Suspicious API Calls            │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ Security Hub     │ ◄── Compliance Monitoring             │
│  │                  │     • CIS Benchmarks                  │
│  │                  │     • PCI-DSS                         │
│  │                  │     • AWS Foundational                │
│  │                  │     • NIST 800-53                     │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ AWS CloudTrail   │ ◄── Audit Logging                     │
│  │                  │     • All API Calls                   │
│  │                  │     • Multi-region                    │
│  │                  │     • Log File Validation             │
│  └────────┬─────────┘                                       │
│           │                                                 │
│           ▼                                                 │
│  ┌──────────────────┐                                       │
│  │ AWS Config       │ ◄── Configuration Compliance          │
│  │                  │     • Resource Tracking               │
│  │                  │     • Compliance Rules                │
│  │                  │     • Change Notifications            │
│  └──────────────────┘                                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Components**:
- **GuardDuty**: Intelligent threat detection using ML
- **Security Hub**: Centralized security findings
- **CloudTrail**: Comprehensive audit logging
- **Config**: Configuration tracking and compliance

**Key Features**:
- ✅ Real-time threat detection
- ✅ Automated compliance checks
- ✅ Complete audit trail
- ✅ Configuration drift detection
- ✅ Integration with EventBridge for automation

---

## Security & Compliance

### Compliance Frameworks

| Framework | Status | Automation | Coverage |
|-----------|--------|------------|----------|
| **PCI-DSS** | ✅ Enabled | Security Hub Standard | Card data protection |
| **CIS Benchmark** | ✅ Enabled | Security Hub Standard | Infrastructure hardening |
| **AWS Foundational** | ✅ Enabled | Security Hub Standard | AWS best practices |
| **NIST 800-53** | ✅ Enabled | Security Hub Standard | Federal compliance |
| **GDPR** | ✅ Implemented | Encryption, Access Controls | Data privacy |
| **FCA** | ✅ Implemented | Audit Logging, Data Protection | Financial services |

### Compliance Controls

#### PCI-DSS Controls
- ✅ Network segmentation (requirement 1)
- ✅ Encryption at rest and in transit (requirement 3 & 4)
- ✅ Access control and authentication (requirement 7 & 8)
- ✅ Network monitoring (requirement 10)
- ✅ Vulnerability management (requirement 11)

#### GDPR Controls
- ✅ Data encryption (Article 32)
- ✅ Access controls (Article 32)
- ✅ Audit logging (Article 30)
- ✅ Data deletion capabilities (Article 17)
- ✅ Data breach notification (Article 33)

#### FCA Controls
- ✅ Operational resilience
- ✅ Data protection
- ✅ Audit trails
- ✅ Change management
- ✅ Business continuity

---

## Identity & Access Management

### Multi-Account Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    ORGANIZATION ROOT                        │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            IAM Identity Center (SSO)                 │  │
│  │                      ↓                                │  │
│  │         Okta SAML Federation                         │  │
│  └───────────────────┬──────────────────────────────────┘  │
│                      │                                      │
│      ┌───────────────┼───────────────┐                     │
│      │               │               │                     │
│  ┌───▼────┐     ┌───▼────┐     ┌───▼────┐                │
│  │Network │     │Workload│     │Shared  │                │
│  │Account │     │Account │     │Services│                │
│  └────────┘     └────────┘     └────────┘                │
└─────────────────────────────────────────────────────────────┘
```

**Features**:
- ✅ Centralized SSO with Okta
- ✅ Cross-account role assumption
- ✅ Least privilege IAM policies
- ✅ Service Control Policies (SCPs)
- ✅ IAM Access Analyzer

---

## Network Security

### VPC Security Features

| Feature | Implementation | Purpose |
|---------|----------------|----------|
| **VPC Flow Logs** | All VPCs | Traffic analysis and forensics |
| **Private Subnets** | No IGW | Internet isolation for workloads |
| **NAT Gateways** | Hub VPC only | Controlled internet egress |
| **VPC Endpoints** | PrivateLink | Secure AWS service access |
| **Network ACLs** | All subnets | Stateless filtering |
| **Security Groups** | All resources | Stateful micro-segmentation |

### Traffic Inspection

```
 ALL Internet-bound Traffic
           |
           ▼
    Inspection VPC
    (Network Firewall)
           |
      ┌────┴────┐
      │ Inspect │
      │ Filter  │
      │ Log     │
      └────┬────┘
           |
     Transit Gateway
           |
    ┌──────┴──────┐
    ▼             ▼
 Allowed      Denied
```

---

## Secrets Management

### Credential Storage

| Secret Type | Storage | Rotation | Access |
|-------------|---------|----------|--------|
| **Database Passwords** | Secrets Manager | Automatic (30 days) | IAM roles only |
| **API Keys** | Secrets Manager | Manual | IAM roles only |
| **TLS Certificates** | ACM/Secrets Manager | Automatic | IAM roles only |
| **SSH Keys** | Parameter Store | Manual | IAM roles only |
| **Application Configs** | Parameter Store | N/A | IAM roles only |

### Secret Rotation

```bash
# Automatic rotation configured for:
- RDS database credentials (30 days)
- Aurora database credentials (30 days)
- Service account passwords (90 days)
```

---

## Incident Response

### Automated Responses

| Event | Detection | Response |
|-------|-----------|----------|
| **Suspicious API Call** | GuardDuty | SNS alert, Lambda remediation |
| **Compromised Instance** | GuardDuty | Isolate security group |
| **Failed SSH Attempts** | CloudWatch Logs | Rate limiting, IP block |
| **Unauthorized Access** | CloudTrail | SNS alert, revoke credentials |
| **Config Drift** | Config Rules | SNS alert, auto-remediation |

### Security Playbooks

1. **Data Breach Response**
   - Isolate affected resources
   - Capture forensics (snapshots, logs)
   - Notify security team
   - Rotate credentials

2. **DDoS Attack**
   - Shield Advanced auto-mitigation
   - Scale infrastructure automatically
   - Enable additional WAF rules

3. **Compromised Credentials**
   - Immediate credential revocation
   - Session termination
   - Access log analysis
   - Force password reset

---

## Logging & Monitoring

### Log Retention

| Log Type | Retention | Storage | Encryption |
|----------|-----------|---------|------------|
| **CloudTrail** | 365 days | S3 | KMS |
| **VPC Flow Logs** | 90 days | CloudWatch | KMS |
| **Application Logs** | 30 days | CloudWatch | KMS |
| **Network Firewall** | 90 days | S3 | KMS |
| **WAF Logs** | 90 days | S3 | KMS |
| **Access Logs** | 365 days | S3 | KMS |

### Monitoring Dashboards

- **Security Dashboard**: GuardDuty findings, Security Hub scores
- **Compliance Dashboard**: Config compliance, security findings
- **Network Dashboard**: VPC flow metrics, firewall denials
- **Application Dashboard**: API metrics, error rates

---

## Security Best Practices

### Implemented Best Practices

- ✅ **Least Privilege**: All IAM roles follow minimum required permissions
- ✅ **Defense in Depth**: Multiple security layers at each tier
- ✅ **Encryption Everywhere**: At rest and in transit
- ✅ **Immutable Infrastructure**: No SSH access to production
- ✅ **Automated Patching**: Systems Manager for OS updates
- ✅ **Network Segmentation**: VPCs isolated by function
- ✅ **Zero Trust**: No implicit trust between services
- ✅ **Audit Everything**: Comprehensive logging enabled

### Security Checklist

- [ ] MFA enabled for all users
- [ ] Root account not used
- [ ] CloudTrail enabled in all regions
- [ ] GuardDuty enabled
- [ ] Security Hub enabled
- [ ] Config enabled with required rules
- [ ] VPC Flow Logs enabled
- [ ] S3 buckets not public
- [ ] EBS volumes encrypted
- [ ] RDS databases encrypted
- [ ] Secrets in Secrets Manager
- [ ] IAM Access Analyzer enabled

---

## POC Security Considerations

### POC Configuration

| Security Control | POC Status | Production Status |
|------------------|------------|-------------------|
| **Client VPN** | ❌ Disabled | ✅ Enabled with Okta MFA |
| **EKS mTLS** | ❌ Disabled (no EKS) | ✅ Enabled via Istio |
| **Remote State Encryption** | ⚠️ Local file | ✅ S3 with KMS |
| **Network Firewall** | ✅ Enabled | ✅ Enabled |
| **WAF** | ✅ Enabled | ✅ Enabled |
| **GuardDuty** | ✅ Enabled | ✅ Enabled |
| **Security Hub** | ✅ Enabled | ✅ Enabled |

### Security Notes for POC

⚠️ **Important**: The POC configuration disables some security features:
- **No Client VPN**: Use AWS Systems Manager Session Manager for access
- **Local State**: State file not encrypted at rest in S3
- **No EKS mTLS**: EKS module disabled, service mesh not active

For full security posture, re-enable production features. See [POC-CHANGES.md](POC-CHANGES.md).

---

## Related Documentation

- [POC Changes](POC-CHANGES.md) - Security implications of POC config
- [Network Architecture](Network%20Architecture.md) - Network security design
- [Components](Components.md) - Security component details
- [README](README.md) - Main documentation

---

**Last Updated**: 2024-01-XX  
**Maintained by**: Security & Platform Engineering Team

