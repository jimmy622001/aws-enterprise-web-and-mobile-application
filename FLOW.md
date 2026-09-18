# Project Flow — AWS Enterprise Architecture

## What This Platform Does

This platform is a multi-region, enterprise-grade cloud infrastructure built on AWS. It handles everything from a user opening a web or mobile app, through to data being processed, stored, and analysed — all while maintaining a live standby copy in a second region ready to take over if anything goes wrong.

The infrastructure spans three AWS accounts (Networking, Workload, Shared Services) and two regions (Ireland as primary, London as DR), provisioned entirely through Terraform.

---

## End-to-End Request Flow

### 1. User Hits the Application

A user opens the web or mobile app. Their request first hits **CloudFront**, AWS's global content delivery network, which:
- Serves cached static assets from edge locations close to the user
- Applies **WAF (Web Application Firewall)** rules — blocking OWASP Top 10 threats, SQL injection, XSS, and rate-limit violations before the request goes any further
- Enforces HTTPS and geo-restriction policies

### 2. Authentication

Authenticated requests pass through **API Gateway**, which validates **JWT/OAuth tokens** against **Amazon Cognito** (the user identity store). Unauthenticated or invalid requests are rejected here.

### 3. Traffic Enters the Network

Legitimate traffic enters the **Ingress VPC** via an **Application Load Balancer (ALB)**. All traffic — inbound and outbound — is routed through the **Inspection VPC**, where **AWS Network Firewall** performs deep packet inspection, IPS/IDS rules, and domain filtering. Nothing reaches the application layer without passing through this inspection layer.

The **Transit Gateway** acts as the central routing hub connecting all VPCs: Hub, Ingress, Inspection, Workload, Data, and Shared Services.

### 4. Application Processing (EKS)

Requests reach the **Workload VPC**, where **Amazon EKS (Elastic Kubernetes Service)** runs the application workloads:
- Containerised microservices deployed via **Helm charts**
- **Karpenter** handles intelligent node auto-scaling — spinning up the right instance type for the workload rather than over-provisioning
- **Istio service mesh** manages service-to-service communication with mTLS encryption
- **HPA (Horizontal Pod Autoscaler)** scales pods based on CPU/memory demand

Container images are pulled from **ECR (Elastic Container Registry)** in the Shared Services account, with cross-account access controlled via IAM policies.

### 5. Containerised Task Workloads (ECS)

Alongside EKS, **Amazon ECS Fargate** runs in the **Ingress VPC** for task-based workloads — jobs that don't need to be long-running Kubernetes services. This includes background processing tasks, scheduled jobs, and lightweight API services. Fargate removes the need to manage underlying EC2 instances for these workloads.

### 6. Database Layer

Application pods query **Aurora PostgreSQL** (in the Workload VPC) for transactional data. Aurora runs as a multi-AZ cluster with a writer and two reader nodes, providing both high availability and read scaling. Credentials are never hardcoded — they are fetched at runtime from **AWS Secrets Manager**.

**MSK (Managed Streaming for Apache Kafka)** handles event streaming between services — decoupling producers and consumers so that high-throughput events (user actions, transactions, notifications) are processed asynchronously and reliably.

---

## Data Platform Flow

The **Data VPC** is a separate, dedicated environment for analytics and data engineering workloads.

```
Event Sources / Application
        ↓
S3 Landing Bucket  ←  External SFTP uploads (AWS Transfer Family)
        ↓
EventBridge (triggers processing pipeline)
        ↓
Apache Airflow (MWAA) — orchestrates the pipeline
        ↓
AWS Glue Jobs:
  ├── Custom transformation jobs
  ├── Aggregation jobs
  └── Extract-to-file jobs
        ↓
Lake Formation + Glue Data Catalog (governance & discovery)
        ↓
S3 Tiers: Raw → Curated → Processed
        ↓
Amazon Redshift (data warehousing / BI queries)
OpenSearch (log analytics and search)
```

**Apache Airflow (MWAA)** is the orchestration layer — it schedules and monitors all Glue jobs, manages dependencies between pipeline steps, handles retries, and provides a UI for the data engineering team to monitor pipeline health.

**AWS Glue** does the heavy lifting of transforming raw data into clean, structured datasets. Different job types handle different transformation patterns — custom business logic, aggregations for reporting, and file extracts for downstream consumers.

**Lake Formation** enforces data governance — controlling which teams and services can access which datasets, with column-level and row-level security where needed.

---

## External Partner File Transfers

External partners upload files via **AWS Transfer Family (SFTP)**. Every uploaded file is automatically passed through an anti-malware scanning workflow before it reaches the data pipeline:

```
Partner uploads file via SFTP
        ↓
Transfer Family Workflow triggers
        ↓
File copied to Quarantine S3 bucket
        ↓
Lambda (anti-malware scanner) inspects the file
        ↓
Clean: file tagged and moved to Landing Zone → triggers data pipeline
Infected: file moved to failed/ prefix → alert sent via SNS
```

---

## Disaster Recovery

### Why It Matters

The primary region (Ireland, eu-west-1) runs all production workloads. The DR region (London, eu-west-2) exists to ensure the business can continue operating if Ireland becomes unavailable — whether due to an AWS incident, a deployment failure, or any other outage.

Without DR, a regional failure means complete downtime until the primary is restored. With this architecture, traffic can be redirected to London within minutes, with data loss measured in seconds.

### What's Always Running in London

The DR region runs in **Warm Standby** for production:
- Full VPC networking stack (Hub, Workload, Data, Shared Services VPCs)
- **Aurora Global Database** — a secondary cluster continuously receiving replicated writes from Ireland, with replication lag typically under 1 second
- **EKS cluster** with a minimal number of nodes (2 per node group) — enough to prove the cluster is healthy, not enough to handle full production traffic
- **S3 cross-region replication** — all data buckets replicated in near real-time
- **ECR replication** — all container images automatically replicated on push, so London always has the latest versions ready to deploy
- **Route 53 health checks** — continuously polling the primary region's `/health` endpoint every 30 seconds

### How Automatic Failover Works

```
Route 53 health check fails 3 consecutive times (90 seconds)
        ↓
CloudWatch Alarm transitions to ALARM state
        ↓
EventBridge rule fires → invokes dr-scale-up Lambda
        ↓
Lambda executes in parallel:
  ├── Aurora: scales from 2 → 3 instances, upgrades to production instance class
  ├── EKS: sets Auto Scaling Group desired capacity to 6 nodes
  ├── CloudFront DR distribution: enabled (was disabled in standby)
  └── SNS: sends CRITICAL alert to operations team
        ↓
Route 53 failover record activates → DNS points to DR CloudFront
        ↓
Traffic flows through London
        ↓
Operations team verifies and monitors
```

Total time from health check failure to traffic serving from London: **5–15 minutes** (dominated by DNS propagation and EKS node warm-up).

### The DR Scale-Up Lambda (`lambda/dr-scale-up.py`)

This Lambda function is the automated engine of the failover. It is deployed in the DR region and triggered by EventBridge when the CloudWatch alarm fires. It does four things in sequence:

1. **Scale Aurora** — upgrades existing DR instances to production instance class and creates additional instances to reach the target cluster size
2. **Scale EKS** — finds the DR Auto Scaling Groups by name prefix and sets desired capacity to the production node count, expanding max capacity if needed
3. **Enable CloudFront** — finds the DR distribution by comment tag and enables it if it was disabled (pilot light mode)
4. **Notify** — publishes a detailed status message to the SNS failover topic, listing every action taken and its result

If any step fails, the Lambda catches the exception, sends a separate failure notification with instructions for manual intervention, and returns a 500 status so the failure is visible in CloudWatch Logs.

The Lambda can also be invoked manually for DR drills:
```bash
aws lambda invoke \
  --function-name <project>-prod-dr-scale-up \
  --payload '{"test": true}' \
  output.json
```

### Failback

Once the primary region is restored, the process reverses: Route 53 is updated to point back to Ireland, the DR Aurora cluster is re-attached to the Global Database as a secondary, EKS nodes in London are scaled back down, and the DR CloudFront distribution is disabled.

---

## Security Layers Summary

| Layer | Controls |
|-------|----------|
| Edge | CloudFront geo-blocking, WAF OWASP rules, Shield Standard DDoS protection |
| Network | Network Firewall deep packet inspection, VPC Flow Logs, NACLs, Security Groups |
| Identity | Cognito user pools, Okta SAML for VPN, IAM least-privilege roles |
| Application | API Gateway throttling, JWT validation, mTLS between services (Istio) |
| Data | KMS encryption at rest, TLS 1.2+ in transit, Secrets Manager, RDS IAM auth |
| Files | Anti-malware scanning on every SFTP upload before data pipeline ingestion |
| Audit | CloudTrail, GuardDuty, Security Hub (CIS + PCI-DSS + AWS Foundational standards) |

---

## Observability

- **CloudWatch** dashboards cover infrastructure metrics, application performance, database performance, DR health, and replication lag
- **X-Ray** provides distributed tracing across services so latency bottlenecks can be traced to the specific service or database call
- **Dynatrace** (via PrivateLink) provides APM for deeper application-level monitoring
- **OpenSearch** aggregates logs from all services for search and analytics
- **SNS** delivers alerts to the operations team for any alarm state change, DR event, or replication lag breach

---

## Environment Progression

Code moves through environments before reaching production:

```
dev → poc → staging → main (Production, Ireland)
                            ↓
                      dr-london (auto-sync, London)
```

Each environment uses its own Terraform workspace and `.tfvars` file, controlling instance sizes, node counts, DR strategy, and feature flags independently. DR is disabled entirely for dev and poc to keep costs low, enabled as pilot light for staging and UAT, and enabled as warm standby for production.
