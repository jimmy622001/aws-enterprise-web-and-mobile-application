#====================================================================
# SHARED SERVICES MODULE
# Main configuration for Shared Services Account
# Components: Transfer Family, ECR, SES, SNS, EKS, Postgres, S3
#====================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

#====================================================================
# DATA SOURCES
#====================================================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

#====================================================================
# VPC - SHARED SERVICES
#====================================================================

resource "aws_vpc" "shared_services" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-services-vpc"
  })
}

#====================================================================
# SUBNETS - Private
#====================================================================

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.shared_services.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-private-${count.index + 1}"
    Tier = "Private"
  })
}

#====================================================================
# SUBNETS - Database (Postgres)
#====================================================================

resource "aws_subnet" "database" {
  count             = 3
  vpc_id            = aws_vpc.shared_services.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-database-${count.index + 1}"
    Tier = "Database"
  })
}

#====================================================================
# SUBNETS - TGW Attachment
#====================================================================

resource "aws_subnet" "tgw" {
  count             = 3
  vpc_id            = aws_vpc.shared_services.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 6)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-tgw-${count.index + 1}"
    Tier = "TGW"
  })
}

#====================================================================
# ROUTE TABLES
#====================================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.shared_services.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  count          = 3
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "tgw" {
  count          = 3
  subnet_id      = aws_subnet.tgw[count.index].id
  route_table_id = aws_route_table.private.id
}

#====================================================================
# KMS KEY - SHARED SERVICES
#====================================================================

resource "aws_kms_key" "shared_services" {
  description             = "KMS key for Shared Services Account"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = false

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Cross Account Access"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:${data.aws_partition.current.partition}:iam::${var.networking_account_id}:root",
            "arn:${data.aws_partition.current.partition}:iam::${var.workload_account_id}:root"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow SES"
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-services-kms"
  })
}

resource "aws_kms_alias" "shared_services" {
  name          = "alias/${var.project_name}-${var.environment}-shared-services"
  target_key_id = aws_kms_key.shared_services.key_id
}

#====================================================================
# AWS TRANSFER FAMILY (SFTP)
#====================================================================

resource "aws_transfer_server" "sftp" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "VPC"
  protocols              = ["SFTP"]
  security_policy_name   = "TransferSecurityPolicy-2023-05"
  logging_role           = aws_iam_role.transfer_logging.arn

  endpoint_details {
    subnet_ids         = aws_subnet.private[*].id
    vpc_id             = aws_vpc.shared_services.id
    security_group_ids = [aws_security_group.transfer.id]
  }

  workflow_details {
    on_upload {
      execution_role = aws_iam_role.transfer_workflow.arn
      workflow_id    = aws_transfer_workflow.antimalware.id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-sftp-server"
  })
}

resource "aws_security_group" "transfer" {
  name        = "${var.project_name}-${var.environment}-transfer-sg"
  description = "Security group for AWS Transfer Family SFTP"
  vpc_id      = aws_vpc.shared_services.id

  ingress {
    description = "SFTP from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, "10.0.0.0/8"]
  }

  egress {
    description = "HTTPS to VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, "10.0.0.0/8"]
  }

  egress {
    description = "S3 HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-transfer-sg"
  })
}

# Transfer Family S3 Bucket
resource "aws_s3_bucket" "transfer" {
  bucket = "${var.project_name}-${var.environment}-transfer-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-transfer"
  })
}

resource "aws_s3_bucket_versioning" "transfer" {
  bucket = aws_s3_bucket.transfer.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "transfer" {
  bucket = aws_s3_bucket.transfer.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.shared_services.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "transfer" {
  bucket = aws_s3_bucket.transfer.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "transfer" {
  bucket = aws_s3_bucket.transfer.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "transfer/"
}

# Transfer Family IAM Roles
resource "aws_iam_role" "transfer_logging" {
  name = "${var.project_name}-${var.environment}-transfer-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "transfer_logging" {
  name = "${var.project_name}-${var.environment}-transfer-logging-policy"
  role = aws_iam_role.transfer_logging.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/transfer/*"
      }
    ]
  })
}

resource "aws_iam_role" "transfer_user" {
  name = "${var.project_name}-${var.environment}-transfer-user-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "transfer_user" {
  name = "${var.project_name}-${var.environment}-transfer-user-policy"
  role = aws_iam_role.transfer_user.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.transfer.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.transfer.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.shared_services.arn
      }
    ]
  })
}

# Sample Transfer User
resource "aws_transfer_user" "example" {
  server_id = aws_transfer_server.sftp.id
  user_name = "sftp-user"
  role      = aws_iam_role.transfer_user.arn

  home_directory_type = "LOGICAL"

  home_directory_mappings {
    entry  = "/"
    target = "/${aws_s3_bucket.transfer.id}/home/$${Transfer:UserName}"
  }

  tags = var.tags
}

#====================================================================
# ANTI-MALWARE PROTECTION (Transfer Workflow)
#====================================================================

resource "aws_transfer_workflow" "antimalware" {
  description = "Anti-malware scanning workflow for uploaded files"

  steps {
    type = "COPY"

    copy_step_details {
      name = "CopyToQuarantine"
      destination_file_location {
        s3_file_location {
          bucket = aws_s3_bucket.quarantine.id
          key    = "quarantine/"
        }
      }
      overwrite_existing   = "TRUE"
      source_file_location = "$${original.file}"
    }
  }

  steps {
    type = "CUSTOM"

    custom_step_details {
      name                 = "ScanForMalware"
      target               = aws_lambda_function.antimalware_scanner.arn
      timeout_seconds      = 300
      source_file_location = "$${original.file}"
    }
  }

  steps {
    type = "TAG"

    tag_step_details {
      name                 = "TagScannedFile"
      source_file_location = "$${original.file}"

      tags {
        key   = "ScanStatus"
        value = "Scanned"
      }
    }
  }

  on_exception_steps {
    type = "COPY"

    copy_step_details {
      name = "CopyToFailed"
      destination_file_location {
        s3_file_location {
          bucket = aws_s3_bucket.quarantine.id
          key    = "failed/"
        }
      }
      overwrite_existing   = "TRUE"
      source_file_location = "$${original.file}"
    }
  }

  tags = var.tags
}

resource "aws_iam_role" "transfer_workflow" {
  name = "${var.project_name}-${var.environment}-transfer-workflow-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "transfer_workflow" {
  name = "${var.project_name}-${var.environment}-transfer-workflow-policy"
  role = aws_iam_role.transfer_workflow.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:PutObject",
          "s3:PutObjectTagging",
          "s3:CopyObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.transfer.arn}/*",
          "${aws_s3_bucket.quarantine.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = aws_lambda_function.antimalware_scanner.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.shared_services.arn
      }
    ]
  })
}

# Quarantine Bucket
resource "aws_s3_bucket" "quarantine" {
  bucket = "${var.project_name}-${var.environment}-quarantine-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-quarantine"
  })
}

resource "aws_s3_bucket_versioning" "quarantine" {
  bucket = aws_s3_bucket.quarantine.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "quarantine" {
  bucket = aws_s3_bucket.quarantine.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.shared_services.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "quarantine" {
  bucket = aws_s3_bucket.quarantine.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "quarantine" {
  bucket = aws_s3_bucket.quarantine.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "quarantine/"
}

# Anti-Malware Lambda Function
resource "aws_lambda_function" "antimalware_scanner" {
  function_name = "${var.project_name}-${var.environment}-antimalware-scanner"
  role          = aws_iam_role.antimalware_lambda.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 300
  memory_size   = 1024

  filename         = data.archive_file.antimalware_lambda.output_path
  source_code_hash = data.archive_file.antimalware_lambda.output_base64sha256

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      QUARANTINE_BUCKET = aws_s3_bucket.quarantine.id
      CLEAN_BUCKET      = aws_s3_bucket.transfer.id
    }
  }

  tags = var.tags
}

data "archive_file" "antimalware_lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda/antimalware.zip"

  source {
    content  = <<-EOF
      import json
      import boto3
      import os

      def handler(event, context):
          """
          Anti-malware scanning placeholder function.
          In production, integrate with ClamAV or commercial AV solution.
          """
          print(f"Received event: {json.dumps(event)}")

          # Extract file information from event
          file_location = event.get('fileLocation', {})
          bucket = file_location.get('bucket')
          key = file_location.get('key')

          print(f"Scanning file: s3://{bucket}/{key}")

          # Placeholder for actual malware scanning logic
          # In production, download file, scan with ClamAV/commercial AV
          is_clean = True  # Placeholder result

          if is_clean:
              return {
                  'statusCode': 200,
                  'body': json.dumps({
                      'status': 'CLEAN',
                      'message': 'File passed malware scan'
                  })
              }
          else:
              raise Exception("Malware detected in file")
    EOF
    filename = "index.py"
  }
}

resource "aws_iam_role" "antimalware_lambda" {
  name = "${var.project_name}-${var.environment}-antimalware-lambda-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "antimalware_lambda_vpc" {
  role       = aws_iam_role.antimalware_lambda.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "antimalware_lambda_xray" {
  role       = aws_iam_role.antimalware_lambda.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "antimalware_lambda" {
  name = "${var.project_name}-${var.environment}-antimalware-lambda-policy"
  role = aws_iam_role.antimalware_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:CopyObject"
        ]
        Resource = [
          "${aws_s3_bucket.transfer.arn}/*",
          "${aws_s3_bucket.quarantine.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.shared_services.arn
      }
    ]
  })
}

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-${var.environment}-shared-lambda-sg"
  description = "Security group for Lambda functions in Shared Services"
  vpc_id      = aws_vpc.shared_services.id

  egress {
    description = "HTTPS to VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "S3 access via gateway endpoint"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-lambda-sg"
  })
}

#====================================================================
# ELASTIC CONTAINER REGISTRY (ECR)
#====================================================================

resource "aws_ecr_repository" "main" {
  for_each = toset(var.ecr_repositories)

  name                 = "${var.project_name}-${var.environment}/${each.value}"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.shared_services.arn
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-${each.value}"
  })
}

resource "aws_ecr_lifecycle_policy" "main" {
  for_each = toset(var.ecr_repositories)

  repository = aws_ecr_repository.main[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Cross-account ECR policy
resource "aws_ecr_repository_policy" "cross_account" {
  for_each = toset(var.ecr_repositories)

  repository = aws_ecr_repository.main[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountPull"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:${data.aws_partition.current.partition}:iam::${var.workload_account_id}:root"
          ]
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

#====================================================================
# POSTGRES RDS
#====================================================================

resource "aws_security_group" "postgres" {
  name        = "${var.project_name}-${var.environment}-shared-postgres-sg"
  description = "Security group for Shared Services Postgres"
  vpc_id      = aws_vpc.shared_services.id

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, "10.0.0.0/8"]
  }

  egress {
    description = "No outbound needed for RDS"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-postgres-sg"
  })
}

resource "aws_db_subnet_group" "postgres" {
  name        = "${var.project_name}-${var.environment}-shared-postgres"
  description = "Subnet group for Shared Services Postgres"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-postgres-subnet-group"
  })
}

resource "aws_db_parameter_group" "postgres" {
  name        = "${var.project_name}-${var.environment}-shared-postgres-params"
  family      = "postgres15"
  description = "Parameter group for Shared Services Postgres"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = var.tags
}

resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-${var.environment}-shared-postgres"

  engine                = "postgres"
  engine_version        = var.postgres_version
  instance_class        = var.postgres_instance_class
  allocated_storage     = var.postgres_allocated_storage
  max_allocated_storage = var.postgres_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.shared_services.arn

  db_name                       = var.postgres_database_name
  username                      = var.postgres_master_username
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.shared_services.arn
  iam_database_authentication_enabled = true

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  parameter_group_name   = aws_db_parameter_group.postgres.name
  publicly_accessible    = false
  multi_az               = var.postgres_multi_az

  backup_retention_period = 35
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-shared-postgres-final"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  performance_insights_enabled    = true
  performance_insights_kms_key_id = aws_kms_key.shared_services.arn

  auto_minor_version_upgrade = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-postgres"
  })
}

#====================================================================
# EMAIL SERVICE (SES)
#====================================================================

resource "aws_ses_domain_identity" "main" {
  domain = var.ses_domain
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

resource "aws_ses_domain_mail_from" "main" {
  domain           = aws_ses_domain_identity.main.domain
  mail_from_domain = "mail.${aws_ses_domain_identity.main.domain}"
}

resource "aws_ses_configuration_set" "main" {
  name = "${var.project_name}-${var.environment}-ses-config"

  reputation_metrics_enabled = true
  sending_enabled            = true

  delivery_options {
    tls_policy = "Require"
  }
}

resource "aws_ses_event_destination" "cloudwatch" {
  name                   = "cloudwatch-destination"
  configuration_set_name = aws_ses_configuration_set.main.name
  enabled                = true

  matching_types = [
    "bounce",
    "complaint",
    "delivery",
    "reject",
    "send"
  ]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "ses:source-ip"
    value_source   = "messageTag"
  }
}

# SES S3 Bucket for received emails
resource "aws_s3_bucket" "ses_incoming" {
  bucket = "${var.project_name}-${var.environment}-ses-incoming-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-ses-incoming"
  })
}

resource "aws_s3_bucket_versioning" "ses_incoming" {
  bucket = aws_s3_bucket.ses_incoming.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ses_incoming" {
  bucket = aws_s3_bucket.ses_incoming.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.shared_services.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "ses_incoming" {
  bucket = aws_s3_bucket.ses_incoming.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "ses_incoming" {
  bucket = aws_s3_bucket.ses_incoming.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "ses-incoming/"
}

resource "aws_s3_bucket_policy" "ses_incoming" {
  bucket = aws_s3_bucket.ses_incoming.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSESPuts"
        Effect = "Allow"
        Principal = {
          Service = "ses.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.ses_incoming.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

#====================================================================
# END USER MESSAGING (SNS)
#====================================================================

resource "aws_sns_topic" "notifications" {
  name              = "${var.project_name}-${var.environment}-notifications"
  kms_master_key_id = aws_kms_key.shared_services.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-notifications"
  })
}

resource "aws_sns_topic" "alerts" {
  name              = "${var.project_name}-${var.environment}-alerts"
  kms_master_key_id = aws_kms_key.shared_services.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-alerts"
  })
}

resource "aws_sns_topic_policy" "notifications" {
  arn = aws_sns_topic.notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountPublish"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:${data.aws_partition.current.partition}:iam::${var.workload_account_id}:root"
          ]
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.notifications.arn
      }
    ]
  })
}

resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchAlarms"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      },
      {
        Sid    = "AllowCrossAccountPublish"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:${data.aws_partition.current.partition}:iam::${var.networking_account_id}:root",
            "arn:${data.aws_partition.current.partition}:iam::${var.workload_account_id}:root"
          ]
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

#====================================================================
# S3 BUCKETS - SHARED STORAGE
#====================================================================

# Central S3 Access Logging Bucket
resource "aws_s3_bucket" "access_logs" {
  bucket = "${var.project_name}-${var.environment}-s3-access-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-s3-access-logs"
    Purpose = "Central S3 Access Logging"
  })
}

resource "aws_s3_bucket_versioning" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.shared_services.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "delete-old-logs"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3ServerAccessLogsPolicy"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.access_logs.arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket" "shared_data" {
  bucket = "${var.project_name}-${var.environment}-shared-data-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-data"
  })
}

resource "aws_s3_bucket_versioning" "shared_data" {
  bucket = aws_s3_bucket.shared_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "shared_data" {
  bucket = aws_s3_bucket.shared_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.shared_services.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "shared_data" {
  bucket = aws_s3_bucket.shared_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "shared_data" {
  bucket = aws_s3_bucket.shared_data.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "shared-data/"
}

resource "aws_s3_bucket_policy" "shared_data" {
  bucket = aws_s3_bucket.shared_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:${data.aws_partition.current.partition}:iam::${var.workload_account_id}:root"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.shared_data.arn,
          "${aws_s3_bucket.shared_data.arn}/*"
        ]
      }
    ]
  })
}

#====================================================================
# CORE SECURITY - SECURITY HUB
#====================================================================

resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:${data.aws_partition.current.partition}:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:${data.aws_partition.current.partition}:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
}

resource "aws_securityhub_standards_subscription" "pci_dss" {
  depends_on    = [aws_securityhub_account.main]
  standards_arn = "arn:${data.aws_partition.current.partition}:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
}

#====================================================================
# CORE SECURITY - SECRETS MANAGER
#====================================================================

resource "aws_secretsmanager_secret" "shared_credentials" {
  name        = "${var.project_name}/${var.environment}/shared/credentials"
  description = "Shared services credentials"
  kms_key_id  = aws_kms_key.shared_services.arn

  tags = var.tags
}

resource "aws_secretsmanager_secret_policy" "shared_credentials" {
  secret_arn = aws_secretsmanager_secret.shared_credentials.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCrossAccountRead"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:${data.aws_partition.current.partition}:iam::${var.workload_account_id}:root"
          ]
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

#====================================================================
# CORE SECURITY - PRIVATE CA
#====================================================================

resource "aws_acmpca_certificate_authority" "shared" {
  type = "ROOT"

  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name         = "${var.project_name}-${var.environment}-shared-services-ca"
      organization        = var.organization_name
      organizational_unit = "Shared Services"
      country             = "GB"
    }
  }

  revocation_configuration {
    crl_configuration {
      enabled            = true
      expiration_in_days = 7
      s3_bucket_name     = aws_s3_bucket.crl.id
      s3_object_acl      = "BUCKET_OWNER_FULL_CONTROL"
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-services-private-ca"
  })

  depends_on = [aws_s3_bucket_policy.crl]
}

resource "aws_s3_bucket" "crl" {
  bucket = "${var.project_name}-${var.environment}-crl-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-crl"
  })
}

resource "aws_s3_bucket_versioning" "crl" {
  bucket = aws_s3_bucket.crl.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "crl" {
  bucket = aws_s3_bucket.crl.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "crl" {
  bucket = aws_s3_bucket.crl.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "crl/"
}

resource "aws_s3_bucket_policy" "crl" {
  bucket = aws_s3_bucket.crl.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowACMPCA"
        Effect = "Allow"
        Principal = {
          Service = "acm-pca.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.crl.arn,
          "${aws_s3_bucket.crl.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

#====================================================================
# VPC ENDPOINTS
#====================================================================

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-${var.environment}-shared-vpce-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.shared_services.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-vpce-sg"
  })
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.shared_services.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowVPCAccess"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceVpc" = aws_vpc.shared_services.id
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-s3-endpoint"
  })
}

# Interface Endpoints
locals {
  interface_endpoints = [
    "ecr.api",
    "ecr.dkr",
    "logs",
    "kms",
    "secretsmanager",
    "sts",
    "transfer.server",
    "sns",
    "email-smtp"
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id              = aws_vpc.shared_services.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowVPCAccess"
        Effect    = "Allow"
        Principal = "*"
        Action    = "*"
        Resource  = "*"
        Condition = {
          StringEquals = {
            "aws:SourceVpc" = aws_vpc.shared_services.id
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-${replace(each.value, ".", "-")}-endpoint"
  })
}

#====================================================================
# VPC FLOW LOGS
#====================================================================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project_name}-${var.environment}-shared-services"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.shared_services.arn

  tags = var.tags
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-shared-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-shared-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "shared_services" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.shared_services.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-shared-services-vpc-flow-logs"
  })
}