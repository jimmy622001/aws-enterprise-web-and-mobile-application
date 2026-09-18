terraform/
├── main.tf                    # Root module configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── providers.tf               # Provider configurations
│
├── environments/
│   ├── dev.tfvars            # Development variables
│   ├── staging.tfvars        # Staging variables
│   ├── uat.tfvars            # UAT variables
│   └── prod.tfvars           # Production variables
│
└── modules/
├── networking-dns/        # Route 53, DNS Firewall
├── hub-vpc/              # Hub VPC, NAT, Resolver
├── private-ingress-vpc/  # Client VPN (Okta SAML)
├── inspection-vpc/       # Network Firewall
├── transit-gateway/      # Transit Gateway, VPN
├── workload-vpc/         # EKS, Aurora, MSK, Cognito
├── ingress-vpc/          # ALB, NLB, ECS Fargate
├── data-vpc/             # Glue, Airflow, Lake Formation
├── cloudfront-waf/       # CloudFront, WAF, Shield, API GW
├── eks/                  # EKS, Istio, IRSA
├── shared-services/      # ECR, Transfer Family, SES
└── security/             # GuardDuty, Security Hub, CloudTrail