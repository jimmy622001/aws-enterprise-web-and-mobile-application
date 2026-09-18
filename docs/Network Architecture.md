### Network Architecture

#### VPC Layout

| VPC | Account | CIDR (Prod) | Purpose |
|-----|---------|-------------|---------|
| **Hub VPC** | Networking | 10.0.0.0/16 | Central connectivity, DNS, NAT |
| **Private Ingress VPC** | Networking | 10.1.0.0/16 | Client VPN for colleague access |
| **Inspection VPC** | Networking | 10.2.0.0/16 | Network Firewall (all traffic inspection) |
| **Workload VPC** | Workload | 10.10.0.0/16 | EKS, Aurora, MSK, Lambda |
| **Ingress VPC** | Workload | 10.11.0.0/16 | ALB, NLB, ECS Fargate (NGINX) |
| **Data VPC** | Workload | 10.12.0.0/16 | Glue, Airflow, Lake Formation |
| **Shared Services VPC** | Shared Services | 10.20.0.0/16 | ECR, Transfer Family, PostgreSQL |

#### Traffic Flow