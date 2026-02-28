# AWS Encryption Patterns
# Control Implementations: SC-8, SC-28, SC-12

# ==============================================================================
# SC-8: Transmission Confidentiality and Integrity
# ==============================================================================

# Application Load Balancer with TLS 1.2+
resource "aws_lb" "example" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = local.tags
}

# SC-8: HTTPS Listener with secure TLS policy
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"
  protocol          = "HTTPS"

  # SC-8: TLS 1.2+ with strong ciphers
  ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}

# Redirect HTTP to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# CloudFront with TLS
resource "aws_cloudfront_distribution" "example" {
  enabled = true

  # SC-8: Minimum TLS version
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.cloudfront_certificate_arn
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

  origin {
    domain_name = aws_lb.example.dns_name
    origin_id   = "alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "alb"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = local.tags
}

# ==============================================================================
# SC-28: Protection of Information at Rest
# ==============================================================================

# S3 Bucket with encryption
resource "aws_s3_bucket" "example" {
  bucket = "${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = local.tags
}

# SC-28: Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      # Use customer-managed KMS key
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# EBS Volume encryption (default)
resource "aws_ebs_encryption_by_default" "example" {
  enabled = true
}

# EBS Default KMS Key
resource "aws_ebs_default_kms_key" "example" {
  key_arn = aws_kms_key.ebs.arn
}

# RDS with encryption
resource "aws_db_instance" "example" {
  identifier     = "${var.project_name}-${var.environment}-db"
  engine         = "postgres"
  engine_version = "15"
  instance_class = "db.t3.medium"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # SC-28: Storage encryption with CMK
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds.arn

  # SC-7: Network isolation
  db_subnet_group_name   = aws_db_subnet_group.example.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # AU-9: Enhanced monitoring
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = local.tags
}

# DynamoDB with encryption
resource "aws_dynamodb_table" "example" {
  name         = "${var.project_name}-${var.environment}-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # SC-28: Server-side encryption with CMK
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  tags = local.tags
}

# ==============================================================================
# SC-12: Cryptographic Key Establishment and Management
# ==============================================================================

# KMS Key for S3
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 30

  # SC-12: Enable automatic key rotation
  enable_key_rotation = true

  # Key policy allowing account root and specific roles
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
        Sid    = "Allow S3 Service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# KMS Key for EBS
resource "aws_kms_key" "ebs" {
  description             = "KMS key for EBS encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project_name}-${var.environment}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

# KMS Key for RDS
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# KMS Key for DynamoDB
resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.tags
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.project_name}-${var.environment}-dynamodb"
  target_key_id = aws_kms_key.dynamodb.key_id
}

# Secrets Manager for sensitive data
resource "aws_secretsmanager_secret" "example" {
  name        = "${var.project_name}-${var.environment}-secret"
  description = "Application secrets"
  kms_key_id  = aws_kms_key.secrets.arn

  # SC-12: Secret rotation
  recovery_window_in_days = 30

  tags = local.tags
}

resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.tags
}

# ==============================================================================
# Common Variables and Locals
# ==============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "compliance_framework" {
  description = "Compliance framework (FedRAMP, GovRAMP, CMMC)"
  type        = string
  default     = "FedRAMP"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

locals {
  tags = merge(var.tags, {
    Environment         = var.environment
    ComplianceFramework = var.compliance_framework
    ManagedBy           = "Terraform"
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
