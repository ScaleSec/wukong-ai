# GCP Logging Patterns
# Control Implementations: AU-2, AU-3, AU-6, AU-12

# ==============================================================================
# AU-2, AU-12: Audit Events and Audit Record Generation
# ==============================================================================

# Log Bucket for centralized logging
resource "google_logging_project_bucket_config" "main" {
  project        = var.project_id
  location       = var.region
  bucket_id      = "${var.project_name}-${var.environment}-logs"

  # AU-11: Audit Record Retention (90 days minimum)
  retention_days = 90

  # SC-28: CMEK encryption (optional)
  # cmek_settings {
  #   kms_key_name = google_kms_crypto_key.logging.id
  # }

  description = "Centralized audit logging bucket"
}

# Log Sink to route all audit logs to bucket
resource "google_logging_project_sink" "audit" {
  name        = "${var.project_name}-${var.environment}-audit-sink"
  project     = var.project_id
  destination = "logging.googleapis.com/projects/${var.project_id}/locations/${var.region}/buckets/${google_logging_project_bucket_config.main.bucket_id}"

  # AU-2: Capture all admin activity and data access
  filter = <<-EOT
    logName:("cloudaudit.googleapis.com/activity" OR
             "cloudaudit.googleapis.com/data_access" OR
             "cloudaudit.googleapis.com/system_event" OR
             "cloudaudit.googleapis.com/policy")
  EOT

  unique_writer_identity = true
}

# Grant the sink's writer identity access to the bucket
resource "google_project_iam_member" "sink_writer" {
  project = var.project_id
  role    = "roles/logging.bucketWriter"
  member  = google_logging_project_sink.audit.writer_identity
}

# Log Sink to BigQuery for analysis
resource "google_logging_project_sink" "bigquery" {
  name        = "${var.project_name}-${var.environment}-bq-sink"
  project     = var.project_id
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.logs.dataset_id}"

  filter = <<-EOT
    logName:("cloudaudit.googleapis.com/activity" OR
             "cloudaudit.googleapis.com/data_access")
  EOT

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# BigQuery dataset for log analysis
resource "google_bigquery_dataset" "logs" {
  dataset_id = "${replace(var.project_name, "-", "_")}_${var.environment}_logs"
  project    = var.project_id
  location   = var.region

  # AU-11: Retention
  default_table_expiration_ms = 7776000000 # 90 days

  labels = local.labels
}

# Grant sink writer access to BigQuery
resource "google_bigquery_dataset_iam_member" "sink_writer" {
  dataset_id = google_bigquery_dataset.logs.dataset_id
  project    = var.project_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.bigquery.writer_identity
}

# ==============================================================================
# Data Access Audit Logs (AU-2, AU-3)
# ==============================================================================

# Enable data access audit logs for all services
resource "google_project_iam_audit_config" "all_services" {
  project = var.project_id
  service = "allServices"

  # AU-2: Log all data reads and writes
  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# Specific audit config for sensitive services
resource "google_project_iam_audit_config" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "google_project_iam_audit_config" "bigquery" {
  project = var.project_id
  service = "bigquery.googleapis.com"

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

# ==============================================================================
# AU-6: Audit Review, Analysis, and Reporting
# ==============================================================================

# Monitoring Notification Channel (Email)
resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Security Team Email"
  type         = "email"

  labels = {
    email_address = var.security_email
  }
}

# Alert Policy for IAM changes
resource "google_monitoring_alert_policy" "iam_changes" {
  project      = var.project_id
  display_name = "IAM Policy Changes"
  combiner     = "OR"

  conditions {
    display_name = "IAM policy modified"

    condition_matched_log {
      filter = <<-EOT
        protoPayload.methodName=("SetIamPolicy" OR
                                 "google.iam.admin.v1.CreateServiceAccount" OR
                                 "google.iam.admin.v1.DeleteServiceAccount")
      EOT

      label_extractors = {
        "method" = "EXTRACT(protoPayload.methodName)"
        "actor"  = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  alert_strategy {
    notification_rate_limit {
      period = "300s"
    }
  }

  documentation {
    content   = "IAM policy was modified. Review the change for compliance."
    mime_type = "text/markdown"
  }
}

# Alert Policy for unauthorized access attempts
resource "google_monitoring_alert_policy" "unauthorized_access" {
  project      = var.project_id
  display_name = "Unauthorized Access Attempts"
  combiner     = "OR"

  conditions {
    display_name = "Permission denied"

    condition_matched_log {
      filter = <<-EOT
        protoPayload.status.code=7
      EOT
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  alert_strategy {
    notification_rate_limit {
      period = "60s"
    }
  }
}

# Alert Policy for Cloud SQL admin operations
resource "google_monitoring_alert_policy" "sql_admin" {
  project      = var.project_id
  display_name = "Cloud SQL Admin Operations"
  combiner     = "OR"

  conditions {
    display_name = "SQL admin operation"

    condition_matched_log {
      filter = <<-EOT
        resource.type="cloudsql_database"
        protoPayload.methodName=~"cloudsql\\..*\\.(delete|update|create)"
      EOT
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}

# ==============================================================================
# Security Command Center
# ==============================================================================

# Organization-level SCC is typically enabled via console or org policies
# Project-level findings can be exported

resource "google_logging_project_sink" "scc" {
  name        = "${var.project_name}-${var.environment}-scc-sink"
  project     = var.project_id
  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.scc_findings.name}"

  filter = <<-EOT
    resource.type="security_command_center_finding"
  EOT

  unique_writer_identity = true
}

resource "google_pubsub_topic" "scc_findings" {
  name    = "${var.project_name}-${var.environment}-scc-findings"
  project = var.project_id

  labels = local.labels
}

resource "google_pubsub_topic_iam_member" "scc_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.scc_findings.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.scc.writer_identity
}

# ==============================================================================
# VPC Flow Logs
# ==============================================================================

# Flow logs are enabled on subnetworks
resource "google_compute_subnetwork" "private_with_logs" {
  name          = "${var.project_name}-${var.environment}-private-logged"
  project       = var.project_id
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.main.id

  # Enable VPC Flow Logs
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
    filter_expr          = "true"
  }

  private_ip_google_access = true
}

# ==============================================================================
# Log Metrics for compliance dashboards
# ==============================================================================

resource "google_logging_metric" "failed_logins" {
  name    = "failed_logins"
  project = var.project_id

  filter = <<-EOT
    protoPayload.authenticationInfo.principalEmail:*
    protoPayload.status.code=16
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"

    labels {
      key         = "principal"
      value_type  = "STRING"
      description = "The principal that failed to authenticate"
    }
  }

  label_extractors = {
    "principal" = "EXTRACT(protoPayload.authenticationInfo.principalEmail)"
  }
}

resource "google_logging_metric" "api_errors" {
  name    = "api_errors"
  project = var.project_id

  filter = <<-EOT
    severity>=ERROR
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
  }
}

# ==============================================================================
# Variables
# ==============================================================================

variable "security_email" {
  description = "Email for security alerts"
  type        = string
  default     = "security@example.com"
}
