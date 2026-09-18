#====================================================================
# DATA VPC MODULE
# Main configuration for Data VPC in Workload Account
# Components: S3, Airflow, Glue, Lambda, DataZone, Lake Formation
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

data "aws_prefix_list" "s3" {
  filter {
    name   = "prefix-list-name"
    values = ["com.amazonaws.${data.aws_region.current.name}.s3"]
  }
}

#====================================================================
# VPC
#====================================================================

resource "aws_vpc" "data" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-vpc"
  })
}

#====================================================================
# SUBNETS - Private (Glue, Lambda, Airflow)
#====================================================================

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.data.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-private-${count.index + 1}"
    Tier = "Private"
  })
}

#====================================================================
# SUBNETS - TGW Attachment
#====================================================================

resource "aws_subnet" "tgw" {
  count             = 3
  vpc_id            = aws_vpc.data.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 3)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-tgw-${count.index + 1}"
    Tier = "TGW"
  })
}

#====================================================================
# ROUTE TABLES
#====================================================================

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.data.id

  route {
    cidr_block         = "0.0.0.0/0"
    transit_gateway_id = var.transit_gateway_id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "tgw" {
  count          = 3
  subnet_id      = aws_subnet.tgw[count.index].id
  route_table_id = aws_route_table.private.id
}

#====================================================================
# KMS KEY FOR DATA VPC
#====================================================================

resource "aws_kms_key" "data" {
  description             = "KMS key for Data VPC resources"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
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
        Sid    = "Allow Glue Service"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
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
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-kms"
  })
}

resource "aws_kms_alias" "data" {
  name          = "alias/${var.project_name}-${var.environment}-data"
  target_key_id = aws_kms_key.data.key_id
}

#====================================================================
# S3 BUCKETS - DATA INGESTION
#====================================================================

resource "aws_s3_bucket" "data_ingestion" {
  bucket = "${var.project_name}-${var.environment}-data-ingestion-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-ingestion"
    Tier = "DATA INGESTION"
  })
}

resource "aws_s3_bucket_versioning" "data_ingestion" {
  bucket = aws_s3_bucket.data_ingestion.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_ingestion" {
  bucket = aws_s3_bucket.data_ingestion.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "data_ingestion" {
  bucket = aws_s3_bucket.data_ingestion.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data_ingestion" {
  bucket = aws_s3_bucket.data_ingestion.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

#====================================================================
# S3 BUCKETS - DATA LAYER (RAW, CURATED, PROCESSED)
#====================================================================

# Raw Data Layer
resource "aws_s3_bucket" "data_raw" {
  bucket = "${var.project_name}-${var.environment}-data-raw-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name      = "${var.project_name}-${var.environment}-data-raw"
    Tier      = "DATA STORAGE"
    DataLayer = "Raw"
  })
}

resource "aws_s3_bucket_versioning" "data_raw" {
  bucket = aws_s3_bucket.data_raw.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_raw" {
  bucket = aws_s3_bucket.data_raw.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "data_raw" {
  bucket = aws_s3_bucket.data_raw.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Curated Data Layer
resource "aws_s3_bucket" "data_curated" {
  bucket = "${var.project_name}-${var.environment}-data-curated-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name      = "${var.project_name}-${var.environment}-data-curated"
    Tier      = "DATA STORAGE"
    DataLayer = "Curated"
  })
}

resource "aws_s3_bucket_versioning" "data_curated" {
  bucket = aws_s3_bucket.data_curated.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_curated" {
  bucket = aws_s3_bucket.data_curated.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "data_curated" {
  bucket = aws_s3_bucket.data_curated.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Processed Data Layer
resource "aws_s3_bucket" "data_processed" {
  bucket = "${var.project_name}-${var.environment}-data-processed-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name      = "${var.project_name}-${var.environment}-data-processed"
    Tier      = "DATA STORAGE"
    DataLayer = "Processed"
  })
}

resource "aws_s3_bucket_versioning" "data_processed" {
  bucket = aws_s3_bucket.data_processed.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_processed" {
  bucket = aws_s3_bucket.data_processed.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "data_processed" {
  bucket = aws_s3_bucket.data_processed.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#====================================================================
# EVENT SOURCES - EVENTBRIDGE
#====================================================================

resource "aws_cloudwatch_event_bus" "data_events" {
  name = "${var.project_name}-${var.environment}-data-events"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-events"
  })
}

# S3 Event Notification to EventBridge
resource "aws_s3_bucket_notification" "data_ingestion" {
  bucket      = aws_s3_bucket.data_ingestion.id
  eventbridge = true
}

# EventBridge Rule for S3 Object Created
resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name           = "${var.project_name}-${var.environment}-s3-object-created"
  description    = "Trigger on S3 object creation in data ingestion bucket"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.data_ingestion.id]
      }
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "glue_trigger" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "TriggerGlueWorkflow"
  arn       = aws_glue_workflow.data_pipeline.arn
  role_arn  = aws_iam_role.eventbridge_glue.arn
}

#====================================================================
# GLUE DATA CATALOG
#====================================================================

resource "aws_glue_catalog_database" "main" {
  name        = "${var.project_name}_${var.environment}_data_catalog"
  description = "Main data catalog for ${var.project_name} ${var.environment}"

  create_table_default_permission {
    permissions = ["ALL"]

    principal {
      data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
    }
  }

  tags = var.tags
}

# Raw Data Table
resource "aws_glue_catalog_table" "raw_data" {
  name          = "raw_data"
  database_name = aws_glue_catalog_database.main.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification" = "parquet"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.data_raw.id}/data/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    columns {
      name = "id"
      type = "string"
    }

    columns {
      name = "timestamp"
      type = "timestamp"
    }

    columns {
      name = "data"
      type = "string"
    }
  }
}

#====================================================================
# GLUE WORKFLOW - DATA PIPELINE
#====================================================================

resource "aws_glue_workflow" "data_pipeline" {
  name        = "${var.project_name}-${var.environment}-data-pipeline"
  description = "Main data processing pipeline"

  default_run_properties = {
    "environment" = var.environment
    "project"     = var.project_name
  }

  tags = var.tags
}

#====================================================================
# GLUE JOBS - CUSTOM GLUE JOBS
#====================================================================

resource "aws_glue_job" "custom_etl" {
  name     = "${var.project_name}-${var.environment}-custom-etl"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.id}/scripts/custom_etl.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--TempDir"                          = "s3://${aws_s3_bucket.glue_temp.id}/temp/"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = "s3://${aws_s3_bucket.glue_temp.id}/spark-logs/"
    "--source_bucket"                    = aws_s3_bucket.data_ingestion.id
    "--target_bucket"                    = aws_s3_bucket.data_raw.id
    "--encryption-type"                  = "sse-kms"
    "--kms-key-id"                       = aws_kms_key.data.arn
  }

  glue_version      = "4.0"
  worker_type       = var.glue_worker_type
  number_of_workers = var.glue_number_of_workers
  timeout           = 60

  execution_property {
    max_concurrent_runs = 2
  }

  security_configuration = aws_glue_security_configuration.main.name

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-custom-etl"
    Type = "Custom Glue Jobs"
  })
}

#====================================================================
# GLUE JOBS - AGGREGATION GLUE JOBS
#====================================================================

resource "aws_glue_job" "aggregation" {
  name     = "${var.project_name}-${var.environment}-aggregation"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.id}/scripts/aggregation.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--TempDir"                          = "s3://${aws_s3_bucket.glue_temp.id}/temp/"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--source_bucket"                    = aws_s3_bucket.data_raw.id
    "--target_bucket"                    = aws_s3_bucket.data_curated.id
    "--encryption-type"                  = "sse-kms"
    "--kms-key-id"                       = aws_kms_key.data.arn
  }

  glue_version      = "4.0"
  worker_type       = var.glue_worker_type
  number_of_workers = var.glue_number_of_workers
  timeout           = 120

  execution_property {
    max_concurrent_runs = 2
  }

  security_configuration = aws_glue_security_configuration.main.name

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-aggregation"
    Type = "Aggregation Glue Jobs"
  })
}

#====================================================================
# GLUE JOBS - EXTRACT TO FILE GLUE JOBS
#====================================================================

resource "aws_glue_job" "extract_to_file" {
  name     = "${var.project_name}-${var.environment}-extract-to-file"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.glue_scripts.id}/scripts/extract_to_file.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--job-bookmark-option"              = "job-bookmark-enable"
    "--TempDir"                          = "s3://${aws_s3_bucket.glue_temp.id}/temp/"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--source_bucket"                    = aws_s3_bucket.data_curated.id
    "--target_bucket"                    = aws_s3_bucket.data_processed.id
    "--output_format"                    = "csv"
    "--encryption-type"                  = "sse-kms"
    "--kms-key-id"                       = aws_kms_key.data.arn
  }

  glue_version      = "4.0"
  worker_type       = var.glue_worker_type
  number_of_workers = var.glue_number_of_workers
  timeout           = 60

  execution_property {
    max_concurrent_runs = 2
  }

  security_configuration = aws_glue_security_configuration.main.name

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-extract-to-file"
    Type = "Extract to File Glue Jobs"
  })
}

#====================================================================
# GLUE WORKFLOW TRIGGERS
#====================================================================

resource "aws_glue_trigger" "start_workflow" {
  name          = "${var.project_name}-${var.environment}-start-workflow"
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.data_pipeline.name

  actions {
    job_name = aws_glue_job.custom_etl.name
  }

  tags = var.tags
}

resource "aws_glue_trigger" "aggregation_trigger" {
  name          = "${var.project_name}-${var.environment}-aggregation-trigger"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.data_pipeline.name

  predicate {
    conditions {
      job_name = aws_glue_job.custom_etl.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.aggregation.name
  }

  tags = var.tags
}

resource "aws_glue_trigger" "extract_trigger" {
  name          = "${var.project_name}-${var.environment}-extract-trigger"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.data_pipeline.name

  predicate {
    conditions {
      job_name = aws_glue_job.aggregation.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.extract_to_file.name
  }

  tags = var.tags
}

#====================================================================
# GLUE SECURITY CONFIGURATION
#====================================================================

resource "aws_glue_security_configuration" "main" {
  name = "${var.project_name}-${var.environment}-glue-security"

  encryption_configuration {
    cloudwatch_encryption {
      cloudwatch_encryption_mode = "SSE-KMS"
      kms_key_arn                = aws_kms_key.data.arn
    }

    job_bookmarks_encryption {
      job_bookmarks_encryption_mode = "CSE-KMS"
      kms_key_arn                   = aws_kms_key.data.arn
    }

    s3_encryption {
      s3_encryption_mode = "SSE-KMS"
      kms_key_arn        = aws_kms_key.data.arn
    }
  }
}

#====================================================================
# GLUE SUPPORTING BUCKETS
#====================================================================

resource "aws_s3_bucket" "glue_scripts" {
  bucket = "${var.project_name}-${var.environment}-glue-scripts-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-glue-scripts"
  })
}

resource "aws_s3_bucket_versioning" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "glue_scripts" {
  bucket = aws_s3_bucket.glue_scripts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "glue_temp" {
  bucket = "${var.project_name}-${var.environment}-glue-temp-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-glue-temp"
  })
}

resource "aws_s3_bucket_versioning" "glue_temp" {
  bucket = aws_s3_bucket.glue_temp.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "glue_temp" {
  bucket = aws_s3_bucket.glue_temp.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "glue_temp" {
  bucket = aws_s3_bucket.glue_temp.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "glue_temp" {
  bucket = aws_s3_bucket.glue_temp.id

  rule {
    id     = "cleanup-temp"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

#====================================================================
# AMAZON MWAA (AIRFLOW)
#====================================================================

resource "aws_s3_bucket" "airflow" {
  bucket = "${var.project_name}-${var.environment}-airflow-${data.aws_caller_identity.current.account_id}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-airflow"
  })
}

resource "aws_s3_bucket_versioning" "airflow" {
  bucket = aws_s3_bucket.airflow.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "airflow" {
  bucket = aws_s3_bucket.airflow.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.data.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "airflow" {
  bucket = aws_s3_bucket.airflow.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload empty DAGs folder structure
resource "aws_s3_object" "airflow_dags" {
  bucket = aws_s3_bucket.airflow.id
  key    = "dags/"
  source = "/dev/null"
}

resource "aws_s3_object" "airflow_requirements" {
  bucket  = aws_s3_bucket.airflow.id
  key     = "requirements.txt"
  content = <<-EOF
    apache-airflow-providers-amazon>=8.0.0
    boto3>=1.28.0
  EOF
}

resource "aws_security_group" "airflow" {
  name        = "${var.project_name}-${var.environment}-airflow-sg"
  description = "Security group for MWAA Airflow"
  vpc_id      = aws_vpc.data.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Self reference"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    description = "HTTPS to VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, "10.0.0.0/8"]
  }

  egress {
    description = "S3 access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-airflow-sg"
  })
}

resource "aws_mwaa_environment" "airflow" {
  name = "${var.project_name}-${var.environment}-airflow"

  airflow_version       = var.airflow_version
  environment_class     = var.airflow_environment_class
  max_workers           = var.airflow_max_workers
  min_workers           = var.airflow_min_workers
  schedulers            = 2
  webserver_access_mode = "PRIVATE_ONLY"

  dag_s3_path          = "dags/"
  requirements_s3_path = "requirements.txt"
  source_bucket_arn    = aws_s3_bucket.airflow.arn
  execution_role_arn   = aws_iam_role.airflow_role.arn
  kms_key              = aws_kms_key.data.arn

  network_configuration {
    security_group_ids = [aws_security_group.airflow.id]
    subnet_ids         = slice(aws_subnet.private[*].id, 0, 2)
  }

  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }

    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }

    task_logs {
      enabled   = true
      log_level = "INFO"
    }

    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }

    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  airflow_configuration_options = {
    "core.default_timezone"         = "utc"
    "webserver.default_ui_timezone" = "utc"
    "core.load_examples"            = "false"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-airflow"
  })

  depends_on = [
    aws_s3_object.airflow_dags,
    aws_s3_object.airflow_requirements
  ]
}

#====================================================================
# LAMBDA FUNCTIONS
#====================================================================

resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-${var.environment}-data-lambda-sg"
  description = "Security group for Data Lambda functions"
  vpc_id      = aws_vpc.data.id

  egress {
    description = "HTTPS to VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "S3 access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    prefix_list_ids = [data.aws_prefix_list.s3.id]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-lambda-sg"
  })
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-data-lambda-role"

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

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_data_access" {
  name = "${var.project_name}-${var.environment}-lambda-data-access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_ingestion.arn,
          "${aws_s3_bucket.data_ingestion.arn}/*",
          aws_s3_bucket.data_raw.arn,
          "${aws_s3_bucket.data_raw.arn}/*",
          aws_s3_bucket.data_curated.arn,
          "${aws_s3_bucket.data_curated.arn}/*",
          aws_s3_bucket.data_processed.arn,
          "${aws_s3_bucket.data_processed.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [aws_kms_key.data.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:BatchStopJobRun"
        ]
        Resource = "*"
      }
    ]
  })
}

#====================================================================
# LAKE FORMATION
#====================================================================

resource "aws_lakeformation_data_lake_settings" "main" {
  admins = [aws_iam_role.lakeformation_admin.arn]

  create_database_default_permissions {
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }
}

resource "aws_iam_role" "lakeformation_admin" {
  name = "${var.project_name}-${var.environment}-lakeformation-admin"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lakeformation.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lakeformation_admin" {
  role       = aws_iam_role.lakeformation_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationDataAdmin"
}

resource "aws_lakeformation_resource" "data_raw" {
  arn      = aws_s3_bucket.data_raw.arn
  role_arn = aws_iam_role.lakeformation_admin.arn
}

resource "aws_lakeformation_resource" "data_curated" {
  arn      = aws_s3_bucket.data_curated.arn
  role_arn = aws_iam_role.lakeformation_admin.arn
}

resource "aws_lakeformation_resource" "data_processed" {
  arn      = aws_s3_bucket.data_processed.arn
  role_arn = aws_iam_role.lakeformation_admin.arn
}

resource "aws_lakeformation_permissions" "glue_database" {
  principal   = aws_iam_role.glue_role.arn
  permissions = ["ALL"]

  database {
    name = aws_glue_catalog_database.main.name
  }
}

#====================================================================
# DATAZONE (Data Governance)
#====================================================================

resource "aws_datazone_domain" "main" {
  name                  = "${var.project_name}-${var.environment}-datazone"
  domain_execution_role = aws_iam_role.datazone_role.arn
  kms_key_identifier    = aws_kms_key.data.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-datazone"
  })
}

resource "aws_iam_role" "datazone_role" {
  name = "${var.project_name}-${var.environment}-datazone-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datazone.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "datazone_policy" {
  name = "${var.project_name}-${var.environment}-datazone-policy"
  role = aws_iam_role.datazone_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:*",
          "lakeformation:*",
          "s3:GetObject",
          "s3:ListBucket",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

#====================================================================
# IAM ROLES
#====================================================================

# Glue Role
resource "aws_iam_role" "glue_role" {
  name = "${var.project_name}-${var.environment}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "glue_s3_access" {
  name = "${var.project_name}-${var.environment}-glue-s3-access"
  role = aws_iam_role.glue_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.data_ingestion.arn,
          "${aws_s3_bucket.data_ingestion.arn}/*",
          aws_s3_bucket.data_raw.arn,
          "${aws_s3_bucket.data_raw.arn}/*",
          aws_s3_bucket.data_curated.arn,
          "${aws_s3_bucket.data_curated.arn}/*",
          aws_s3_bucket.data_processed.arn,
          "${aws_s3_bucket.data_processed.arn}/*",
          aws_s3_bucket.glue_scripts.arn,
          "${aws_s3_bucket.glue_scripts.arn}/*",
          aws_s3_bucket.glue_temp.arn,
          "${aws_s3_bucket.glue_temp.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [aws_kms_key.data.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "lakeformation:GetDataAccess"
        ]
        Resource = "*"
      }
    ]
  })
}

# Airflow Role
resource "aws_iam_role" "airflow_role" {
  name = "${var.project_name}-${var.environment}-airflow-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = ["airflow.amazonaws.com", "airflow-env.amazonaws.com"]
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "airflow_policy" {
  name = "${var.project_name}-${var.environment}-airflow-policy"
  role = aws_iam_role.airflow_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject*",
          "s3:GetBucket*",
          "s3:List*"
        ]
        Resource = [
          aws_s3_bucket.airflow.arn,
          "${aws_s3_bucket.airflow.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:airflow-${var.project_name}-${var.environment}*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ]
        Resource = "arn:aws:sqs:${data.aws_region.current.name}:*:airflow-celery-*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:Encrypt"
        ]
        Resource = aws_kms_key.data.arn
      },
      {
        Effect = "Allow"
        Action = [
          "glue:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge Role for Glue
resource "aws_iam_role" "eventbridge_glue" {
  name = "${var.project_name}-${var.environment}-eventbridge-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "eventbridge_glue" {
  name = "${var.project_name}-${var.environment}-eventbridge-glue-policy"
  role = aws_iam_role.eventbridge_glue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:notifyEvent"
        ]
        Resource = aws_glue_workflow.data_pipeline.arn
      }
    ]
  })
}

#====================================================================
# VPC ENDPOINTS
#====================================================================

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project_name}-${var.environment}-data-vpce-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.data.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-vpce-sg"
  })
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.data.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowS3Access"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = [
          "arn:aws:s3:::*"
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-s3-endpoint"
  })
}

# Interface Endpoints
locals {
  interface_endpoints = [
    "glue",
    "lakeformation",
    "logs",
    "kms",
    "secretsmanager",
    "sts",
    "events",
    "airflow.api",
    "airflow.env",
    "airflow.ops"
  ]
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id              = aws_vpc.data.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAll"
        Effect    = "Allow"
        Principal = "*"
        Action    = "*"
        Resource  = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-${replace(each.value, ".", "-")}-endpoint"
  })
}

#====================================================================
# VPC FLOW LOGS
#====================================================================

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.project_name}-${var.environment}-data"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.data.arn

  tags = var.tags
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.project_name}-${var.environment}-data-vpc-flow-logs-role"

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
  name = "${var.project_name}-${var.environment}-data-vpc-flow-logs-policy"
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

resource "aws_flow_log" "data" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.data.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-vpc-flow-logs"
  })
}

#====================================================================
# CORE SECURITY - SECURITY HUB
#====================================================================

resource "aws_securityhub_account" "data" {}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  depends_on    = [aws_securityhub_account.data]
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
}

resource "aws_securityhub_standards_subscription" "cis" {
  depends_on    = [aws_securityhub_account.data]
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
}

#====================================================================
# CORE SECURITY - GUARDDUTY
#====================================================================

resource "aws_guardduty_detector" "data" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  datasources {
    s3_logs {
      enable = true
    }
  }

  tags = var.tags
}

#====================================================================
# CORE SECURITY - SECRETS MANAGER
#====================================================================

resource "aws_secretsmanager_secret" "data_credentials" {
  name        = "${var.project_name}/${var.environment}/data/credentials"
  description = "Data platform credentials"
  kms_key_id  = aws_kms_key.data.arn

  tags = var.tags
}

#====================================================================
# CORE SECURITY - PRIVATE CA
#====================================================================

resource "aws_acmpca_certificate_authority" "data" {
  type = "SUBORDINATE"

  certificate_authority_configuration {
    key_algorithm     = "RSA_4096"
    signing_algorithm = "SHA512WITHRSA"

    subject {
      common_name         = "${var.project_name}-${var.environment}-data-ca"
      organization        = var.organization_name
      organizational_unit = "Data Platform"
      country             = "GB"
    }
  }

  revocation_configuration {
    crl_configuration {
      enabled = false
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-data-private-ca"
  })
}