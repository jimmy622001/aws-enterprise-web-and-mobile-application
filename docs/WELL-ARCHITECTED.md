# AWS Well-Architected Alignment

This document maps the project to the 6 AWS Well-Architected pillars and points to existing repository evidence.

## 1. Security
- Existing: `README.md` [Security First section], `docs/Security Architecture.md` (security design), `modules/security/*`, `main.tf` security modules.
- Controls:
  - AWS Network Firewall, WAF and OWASP rules in `modules/cloudfront-waf/main.tf`
  - Secrets Manager/KMS encryption in `variables.tf`, `dr-infrastructure.tf`
  - GuardDuty/Security Hub integration in `SUPPLY_CHAIN_SECURITY_STRATEGY.md` and `docs/DR-IMPLEMENTATION-SUMMARY.md`

## 2. Reliability
- Existing: `dr-infrastructure.tf`, `docs/DR-DEPLOYMENT-GUIDE.md`, `docs/DR-IMPLEMENTATION-SUMMARY.md`
- Controls:
  - Multi-region primary (eu-west-1) + DR (eu-west-2)
  - Route53 health checks + failover routing
  - Cross-region Aurora replication + warm standby
  - HUB+Spoke/TGW with multi-AZ networking

## 3. Performance Efficiency
- Existing: `README.md` networking and container orchestration sections; `Modules/eks/*`; `dr-infrastructure.tf` perf insights.
- Controls:
  - EKS auto-scaling (HPA + Karpenter)
  - ALB, MSI/Endpoint design, data services (MSK, Aurora, Redshift)
  - X-Ray + CloudWatch metrics for tuning

## 4. Cost Optimization
- Existing: `README.md` Cost Optimization, `docs/QUICK-REFERENCE.md`, `docs/WORKSPACE-IMPLEMENTATION-SUMMARY.md`, `docs/DR-IMPLEMENTATION-SUMMARY.md`
- Controls:
  - Warm standby, autoscaling, instance rightsize guidance
  - `infracost` call in README
  - price-class restriction in CloudFront (prod/non-prod)

## 5. Operational Excellence
- Existing: `docs/BRANCH-STRATEGY.md`, `docs/DR-DEPLOYMENT-GUIDE.md`, `docs/WORKSPACE-IMPLEMENTATION-SUMMARY.md`, existing checklists and runbooks
- Controls:
  - Automated deployments and post-deploy tests
  - Logging/alerts (CloudWatch alarms + SNS notifications)
  - Documentation for DR drills

## 6. Sustainability
- Existing (inferred): cost-efficiency strategy in DR + autoscaling design
- Recommended explicit additions:
  - sustainability KPI section in this docs page
  - mention of instance right-sizing, spot usage, and standby warm-vs-active decisions

## High-level status
- [x] Security: complete
- [x] Reliability: complete
- [x] Performance Efficiency: complete
- [x] Cost Optimization: complete
- [x] Operational Excellence: complete
- [ ] Sustainability: partial; explicit KPIs needed

## Next steps (recommended)
1. Add `docs/WELL-ARCHITECTED.md` to top-level `README.md` Table of Contents.
2. Add a short matrix card in `docs/WORKSPACE-IMPLEMENTATION-SUMMARY.md` or main `README.md`.
3. Run and capture audit commands:
   - `terraform validate`
   - `tfsec .`
   - `infracost breakdown --path .`
   - `aws wellarchitected get-lens-version --lens-alias "wellarchitected"` (optionally via CLI)
