#====================================================================
# DISASTER RECOVERY INFRASTRUCTURE
# Multi-Region DR with Pilot Light Strategy
# Primary: eu-west-1 (Ireland) → DR: eu-west-2 (London)
#====================================================================

#====================================================================
# DR ROUTE 53 HEALTH CHECKS & FAILOVER
#====================================================================

# Health check for primary region
resource "aws_route53_health_check" "primary_region" {
  count = var.enable_dr ? 1 : 0

  fqdn              = var.public_hosted_zone_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(
    var.common_tags,
    {
      Name   = "${var.project_name}-${var.environment}-primary-health-check"
      Region = var.aws_region
      Purpose = "Primary Region Health Monitoring"
    }
  )
}

# CloudWatch alarm for primary region health check
resource "aws_cloudwatch_metric_alarm" "primary_region_unhealthy" {
  count = var.enable_dr ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-primary-region-unhealthy"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1.0
  alarm_description   = "This metric monitors primary region health"
  treat_missing_data  = "breaching"

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary_region[0].id
  }

  alarm_actions = [aws_sns_topic.dr_failover[0].arn]
  ok_actions    = [aws_sns_topic.dr_failover[0].arn]

  tags = var.common_tags
}

# SNS topic for DR failover notifications
resource "aws_sns_topic" "dr_failover" {
  count = var.enable_dr ? 1 : 0

  name              = "${var.project_name}-${var.environment}-dr-failover-notifications"
  display_name      = "DR Failover Notifications"
  kms_master_key_id = aws_kms_key.dr[0].id

  tags = var.common_tags
}

resource "aws_sns_topic_subscription" "dr_failover_email" {
  count = var.enable_dr ? 1 : 0

  topic_arn = aws_sns_topic.dr_failover[0].arn
  protocol  = "email"
  endpoint  = var.security_alert_email
}

#====================================================================
# DR KMS KEY
#====================================================================

resource "aws_kms_key" "dr" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr

  description             = "KMS key for DR encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = true

  tags = merge(
    var.common_tags,
    {
      Name   = "${var.project_name}-${var.environment}-dr-kms"
      Region = var.dr_region
    }
  )
}

resource "aws_kms_alias" "dr" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr

  name          = "alias/${var.project_name}-${var.environment}-dr"
  target_key_id = aws_kms_key.dr[0].key_id
}

#====================================================================
# DR HUB VPC (Core Networking)
#====================================================================

module "dr_hub_vpc" {
  count = var.enable_dr ? 1 : 0

  source = "./Modules/hub-vpc"

  providers = {
    aws = aws.dr_networking
  }

  project_name = var.project_name
  environment  = "${var.environment}-dr"
  vpc_cidr     = var.dr_hub_vpc_cidr

  transit_gateway_id     = module.dr_transit_gateway[0].transit_gateway_id
  transit_gateway_route_table_id = module.dr_transit_gateway[0].shared_services_route_table_id

  tags = merge(
    var.common_tags,
    {
      Region    = var.dr_region
      DRPurpose = "Disaster Recovery"
      Failover  = var.dr_strategy
    }
  )
}

#====================================================================
# DR TRANSIT GATEWAY
#====================================================================

module "dr_transit_gateway" {
  count = var.enable_dr ? 1 : 0

  source = "./Modules/transit-gateway"

  providers = {
    aws.networking = aws.dr_networking
    aws.workload   = aws.dr_workload
    aws.shared_services = aws.dr_shared_services
  }

  project_name = var.project_name
  environment  = "${var.environment}-dr"

  amazon_side_asn = var.transit_gateway_asn + 1000 # Different ASN for DR
  cidr_blocks     = ["10.299.0.0/24"] # DR TGW CIDR

  # Attach DR VPCs
  networking_vpc_id      = module.dr_hub_vpc[0].vpc_id
  networking_vpc_cidr    = var.dr_hub_vpc_cidr
  networking_subnet_ids  = module.dr_hub_vpc[0].tgw_attachment_subnet_ids

  workload_vpc_id      = module.dr_workload_vpc[0].vpc_id
  workload_vpc_cidr    = var.dr_workload_vpc_cidr
  workload_subnet_ids  = module.dr_workload_vpc[0].tgw_attachment_subnet_ids

  shared_services_vpc_id      = module.dr_shared_services_vpc[0].vpc_id
  shared_services_vpc_cidr    = var.dr_shared_services_vpc_cidr
  shared_services_subnet_ids  = module.dr_shared_services_vpc[0].private_subnet_ids

  tags = merge(
    var.common_tags,
    {
      Region    = var.dr_region
      DRPurpose = "Disaster Recovery"
    }
  )
}

#====================================================================
# DR WORKLOAD VPC (Application Layer)
#====================================================================

module "dr_workload_vpc" {
  count = var.enable_dr ? 1 : 0

  source = "./Modules/workload-vpc"

  providers = {
    aws = aws.dr_workload
  }

  project_name = var.project_name
  environment  = "${var.environment}-dr"
  vpc_cidr     = var.dr_workload_vpc_cidr

  transit_gateway_id = module.dr_transit_gateway[0].transit_gateway_id

  # Pilot light - minimal endpoints
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  enable_ecr_endpoints     = var.enable_eks
  enable_secrets_endpoint  = true

  tags = merge(
    var.common_tags,
    {
      Region    = var.dr_region
      DRPurpose = "Disaster Recovery"
    }
  )
}

#====================================================================
# DR DATA VPC (Database Layer)
#====================================================================

module "dr_data_vpc" {
  count = var.enable_dr ? 1 : 0

  source = "./Modules/data-vpc"

  providers = {
    aws = aws.dr_workload
  }

  project_name = var.project_name
  environment  = "${var.environment}-dr"
  vpc_cidr     = var.dr_data_vpc_cidr

  transit_gateway_id = module.dr_transit_gateway[0].transit_gateway_id

  tags = merge(
    var.common_tags,
    {
      Region    = var.dr_region
      DRPurpose = "Disaster Recovery"
    }
  )
}

#====================================================================
# DR SHARED SERVICES VPC
#====================================================================

module "dr_shared_services_vpc" {
  count = var.enable_dr ? 1 : 0

  source = "./Modules/shared-services"

  providers = {
    aws = aws.dr_shared_services
  }

  project_name = var.project_name
  environment  = "${var.environment}-dr"
  vpc_cidr     = var.dr_shared_services_vpc_cidr

  transit_gateway_id = module.dr_transit_gateway[0].transit_gateway_id

  # DR-specific configuration
  postgres_instance_class        = var.dr_postgres_instance_class
  postgres_allocated_storage     = 50 # Smaller for DR
  postgres_max_allocated_storage = 100
  postgres_multi_az              = false # Single AZ for pilot light

  ses_domain = "dr.${var.ses_domain}"

  ecr_repositories = var.ecr_repositories

  tags = merge(
    var.common_tags,
    {
      Region    = var.dr_region
      DRPurpose = "Disaster Recovery"
    }
  )
}

#====================================================================
# DR AURORA DATABASE (Read Replica from Primary)
#====================================================================

# Aurora Global Database - Primary cluster is in main.tf
resource "aws_rds_global_cluster" "workload" {
  count = var.enable_dr ? 1 : 0

  global_cluster_identifier = "${var.project_name}-${var.environment}-workload-global"
  engine                    = "aurora-postgresql"
  engine_version            = var.aurora_engine_version
  database_name             = var.aurora_database_name
  storage_encrypted         = true

  depends_on = [
    module.data_vpc
  ]
}

# DR Aurora Cluster (Secondary region)
resource "aws_rds_cluster" "dr_workload" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr_workload

  cluster_identifier        = "${var.project_name}-${var.environment}-dr-workload-cluster"
  engine                    = "aurora-postgresql"
  engine_version            = var.aurora_engine_version
  global_cluster_identifier = aws_rds_global_cluster.workload[0].id

  db_subnet_group_name = module.dr_data_vpc[0].db_subnet_group_name
  vpc_security_group_ids = [module.dr_data_vpc[0].aurora_security_group_id]

  # Encryption
  storage_encrypted = true
  kms_key_id        = aws_kms_key.dr[0].arn

  # Pilot light - keep minimal
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = "${var.project_name}-${var.environment}-dr-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  deletion_protection       = var.environment == "prod"
  iam_database_authentication_enabled = true

  # No backup needed - this is a replica
  backup_retention_period = 1

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-dr-workload-cluster"
      Region    = var.dr_region
      DRPurpose = "Aurora Global Database Secondary"
    }
  )

  depends_on = [
    aws_rds_global_cluster.workload
  ]

  lifecycle {
    ignore_changes = [
      global_cluster_identifier,
      replication_source_identifier
    ]
  }
}

# DR Aurora Instance (Pilot Light - Single Instance)
resource "aws_rds_cluster_instance" "dr_workload" {
  count = var.enable_dr ? var.dr_aurora_instance_count : 0

  provider = aws.dr_workload

  identifier         = "${var.project_name}-${var.environment}-dr-workload-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.dr_workload[0].id
  instance_class     = var.dr_aurora_instance_class
  engine             = "aurora-postgresql"
  engine_version     = var.aurora_engine_version

  # Performance Insights
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.dr[0].arn

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.dr_rds_monitoring[0].arn

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-dr-workload-instance-${count.index + 1}"
      Region    = var.dr_region
      DRPurpose = "Aurora Read Replica"
    }
  )
}

# IAM role for DR RDS monitoring
resource "aws_iam_role" "dr_rds_monitoring" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr_workload

  name = "${var.project_name}-${var.environment}-dr-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
  ]

  tags = var.common_tags
}

#====================================================================
# S3 CROSS-REGION REPLICATION
#====================================================================

# Create DR S3 buckets with replication from primary
resource "aws_s3_bucket" "dr_data" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr_workload

  bucket = "${var.project_name}-${var.environment}-dr-data-${var.dr_region}"

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-dr-data"
      Region    = var.dr_region
      DRPurpose = "Cross-Region Replication Target"
    }
  )
}

resource "aws_s3_bucket_versioning" "dr_data" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr_workload

  bucket = aws_s3_bucket.dr_data[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "dr_data" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr_workload

  bucket = aws_s3_bucket.dr_data[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dr_data" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr_workload

  bucket = aws_s3_bucket.dr_data[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.dr[0].arn
    }
  }
}

#====================================================================
# ECR CROSS-REGION REPLICATION
#====================================================================

# ECR replication configuration for DR
resource "aws_ecr_replication_configuration" "dr" {
  count = var.enable_dr ? 1 : 0

  replication_configuration {
    rule {
      destination {
        region      = var.dr_region
        registry_id = var.workload_account_id
      }

      repository_filter {
        filter      = "*"
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}

#====================================================================
# DR ROUTE 53 FAILOVER RECORDS
#====================================================================

# Create failover records for automatic DR activation
resource "aws_route53_record" "primary_failover" {
  count = var.enable_dr && var.dr_failover_mode == "automatic" ? 1 : 0

  zone_id = module.networking_dns.public_hosted_zone_id
  name    = var.public_hosted_zone_name
  type    = "A"

  set_identifier = "primary"
  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary_region[0].id

  alias {
    name                   = module.cloudfront_waf.web_distribution_domain_name
    zone_id                = module.cloudfront_waf.web_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dr_failover" {
  count = var.enable_dr && var.dr_failover_mode == "automatic" ? 1 : 0

  zone_id = module.networking_dns.public_hosted_zone_id
  name    = var.public_hosted_zone_name
  type    = "A"

  set_identifier = "secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }

  # Points to DR CloudFront distribution (would need to create DR CloudFront)
  alias {
    name                   = aws_cloudfront_distribution.dr[0].domain_name
    zone_id                = aws_cloudfront_distribution.dr[0].hosted_zone_id
    evaluate_target_health = false
  }
}

#====================================================================
# DR CLOUDFRONT DISTRIBUTION (Pilot Light)
#====================================================================

resource "aws_cloudfront_distribution" "dr" {
  count = var.enable_dr ? 1 : 0

  provider = aws.us_east_1

  enabled             = var.dr_strategy != "pilot-light" # Disabled for pilot light
  is_ipv6_enabled     = true
  comment             = "DR CloudFront Distribution for ${var.project_name}-${var.environment}"
  price_class         = "PriceClass_100" # Europe only for cost optimization
  web_acl_id          = module.cloudfront_waf.web_waf_acl_arn

  origin {
    domain_name = module.dr_workload_vpc[0].alb_dns_name
    origin_id   = "DR-ALB"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Custom-Header"
      value = var.cloudfront_custom_header_value
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "DR-ALB"

    forwarded_values {
      query_string = true
      headers      = ["Host", "CloudFront-Forwarded-Proto"]

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn_us_east_1
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-dr-cloudfront"
      Region    = var.dr_region
      DRPurpose = "Failover Distribution"
      Enabled   = var.dr_strategy != "pilot-light"
    }
  )
}

#====================================================================
# DR MONITORING & DASHBOARDS
#====================================================================

resource "aws_cloudwatch_dashboard" "dr_monitoring" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr

  dashboard_name = "${var.project_name}-${var.environment}-dr-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Route53", "HealthCheckStatus", { stat = "Average", label = "Primary Region Health" }],
            ["AWS/RDS", "DatabaseConnections", { stat = "Average", label = "DR Aurora Connections" }],
            ["AWS/RDS", "ReplicaLag", { stat = "Average", label = "Aurora Replication Lag" }]
          ]
          period = 300
          stat   = "Average"
          region = var.dr_region
          title  = "DR Health Metrics"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/S3", "ReplicationLatency", { stat = "Average", label = "S3 Replication Lag" }]
          ]
          period = 300
          stat   = "Average"
          region = var.dr_region
          title  = "Data Replication Status"
        }
      }
    ]
  })
}

#====================================================================
# DR LAMBDA FUNCTION FOR AUTO-SCALING (Warm Standby)
#====================================================================

# Lambda function to scale up DR resources during failover
resource "aws_lambda_function" "dr_scale_up" {
  count = var.enable_dr && var.dr_failover_mode == "automatic" ? 1 : 0

  provider = aws.dr

  filename      = "${path.module}/lambda/dr-scale-up.zip"
  function_name = "${var.project_name}-${var.environment}-dr-scale-up"
  role          = aws_iam_role.dr_lambda[0].arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 300

  environment {
    variables = {
      ENVIRONMENT           = var.environment
      DR_REGION            = var.dr_region
      WORKLOAD_ACCOUNT_ID  = var.workload_account_id
      TARGET_AURORA_SIZE   = var.aurora_instance_count
      TARGET_AURORA_CLASS  = var.aurora_instance_class
      TARGET_EKS_NODES     = var.app_node_desired_size
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-dr-scale-up"
      DRPurpose = "Automatic Failover Scaling"
    }
  )
}

# IAM role for DR Lambda
resource "aws_iam_role" "dr_lambda" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr

  name = "${var.project_name}-${var.environment}-dr-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "dr_lambda" {
  count = var.enable_dr ? 1 : 0

  provider = aws.dr

  name = "${var.project_name}-${var.environment}-dr-lambda-policy"
  role = aws_iam_role.dr_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:ModifyDBInstance",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DescribeAutoScalingGroups",
          "cloudfront:UpdateDistribution",
          "cloudfront:GetDistribution",
          "route53:ChangeResourceRecordSets",
          "sns:Publish",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge rule to trigger Lambda on health check failure
resource "aws_cloudwatch_event_rule" "dr_failover_trigger" {
  count = var.enable_dr && var.dr_failover_mode == "automatic" ? 1 : 0

  provider = aws.dr

  name        = "${var.project_name}-${var.environment}-dr-failover-trigger"
  description = "Trigger DR failover when primary region health check fails"

  event_pattern = jsonencode({
    source      = ["aws.cloudwatch"]
    detail-type = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = [aws_cloudwatch_metric_alarm.primary_region_unhealthy[0].alarm_name]
      state = {
        value = ["ALARM"]
      }
    }
  })

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "dr_scale_up" {
  count = var.enable_dr && var.dr_failover_mode == "automatic" ? 1 : 0

  provider = aws.dr

  rule      = aws_cloudwatch_event_rule.dr_failover_trigger[0].name
  target_id = "DRScaleUpLambda"
  arn       = aws_lambda_function.dr_scale_up[0].arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count = var.enable_dr && var.dr_failover_mode == "automatic" ? 1 : 0

  provider = aws.dr

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_scale_up[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dr_failover_trigger[0].arn
}
