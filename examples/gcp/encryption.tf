# GCP Encryption Patterns
# Control Implementations: SC-8, SC-28, SC-12

# ==============================================================================
# SC-8: Transmission Confidentiality and Integrity
# ==============================================================================

# SSL Policy for Load Balancers (TLS 1.2+)
resource "google_compute_ssl_policy" "modern" {
  name            = "${var.project_name}-${var.environment}-ssl-policy"
  profile         = "MODERN"          # TLS 1.2+ with modern ciphers
  min_tls_version = "TLS_1_2"
  project         = var.project_id
}

# For stricter compliance (FedRAMP High)
resource "google_compute_ssl_policy" "restricted" {
  name            = "${var.project_name}-${var.environment}-ssl-restricted"
  profile         = "RESTRICTED"      # FIPS-compliant ciphers
  min_tls_version = "TLS_1_2"
  project         = var.project_id
}

# HTTPS Load Balancer
resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.project_name}-${var.environment}-https-rule"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}

resource "google_compute_target_https_proxy" "default" {
  name             = "${var.project_name}-${var.environment}-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]

  # SC-8: Apply modern SSL policy
  ssl_policy = google_compute_ssl_policy.modern.id
}

# Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "default" {
  name    = "${var.project_name}-${var.environment}-cert"
  project = var.project_id

  managed {
    domains = [var.domain_name]
  }
}

# Cloud SQL with SSL enforcement
resource "google_sql_database_instance" "main" {
  name             = "${var.project_name}-${var.environment}-sql"
  database_version = "POSTGRES_15"
  region           = var.region
  project          = var.project_id

  settings {
    tier = "db-f1-micro"

    # SC-8: Require SSL connections
    ip_configuration {
      require_ssl = true

      # SC-7: No public IP
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }

    # AU-2: Database audit logging
    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }
  }

  deletion_protection = true
}

# ==============================================================================
# SC-28: Protection of Information at Rest
# ==============================================================================

# Cloud Storage with CMEK
resource "google_storage_bucket" "main" {
  name          = "${var.project_name}-${var.environment}-${var.project_id}"
  location      = var.region
  project       = var.project_id
  storage_class = "STANDARD"

  # SC-28: Customer-managed encryption key
  encryption {
    default_kms_key_name = google_kms_crypto_key.storage.id
  }

  # SC-7: Uniform bucket-level access (no ACLs)
  uniform_bucket_level_access = true

  # SC-7: Block public access
  public_access_prevention = "enforced"

  # AU-2: Access logging
  logging {
    log_bucket        = google_storage_bucket.logs.name
    log_object_prefix = "gcs-access-logs/"
  }

  versioning {
    enabled = true
  }

  labels = local.labels
}

# Logging bucket
resource "google_storage_bucket" "logs" {
  name          = "${var.project_name}-${var.environment}-logs-${var.project_id}"
  location      = var.region
  project       = var.project_id
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Lifecycle rule for log retention
  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  labels = local.labels
}

# BigQuery with CMEK
resource "google_bigquery_dataset" "main" {
  dataset_id = "${replace(var.project_name, "-", "_")}_${var.environment}"
  project    = var.project_id
  location   = var.region

  # SC-28: Customer-managed encryption key
  default_encryption_configuration {
    kms_key_name = google_kms_crypto_key.bigquery.id
  }

  labels = local.labels
}

# Compute Engine with CMEK encrypted disk
resource "google_compute_instance" "example" {
  name         = "${var.project_name}-${var.environment}-vm"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }

    # SC-28: Customer-managed encryption key
    kms_key_self_link = google_kms_crypto_key.compute.id
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.private.id

    # SC-7: No external IP
    # (omit access_config block)
  }

  # IA-2: Use service account
  service_account {
    email  = google_service_account.compute.email
    scopes = ["cloud-platform"]
  }

  # Enable Shielded VM
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = local.labels
}

# ==============================================================================
# SC-12: Cryptographic Key Establishment and Management
# ==============================================================================

# Key Ring
resource "google_kms_key_ring" "main" {
  name     = "${var.project_name}-${var.environment}-keyring"
  location = var.region
  project  = var.project_id
}

# Crypto Key for Storage
resource "google_kms_crypto_key" "storage" {
  name            = "storage-key"
  key_ring        = google_kms_key_ring.main.id
  purpose         = "ENCRYPT_DECRYPT"

  # SC-12: 90-day rotation
  rotation_period = "7776000s"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE" # Use "HSM" for FIPS compliance
  }

  labels = local.labels
}

# Crypto Key for BigQuery
resource "google_kms_crypto_key" "bigquery" {
  name            = "bigquery-key"
  key_ring        = google_kms_key_ring.main.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }

  labels = local.labels
}

# Crypto Key for Compute
resource "google_kms_crypto_key" "compute" {
  name            = "compute-key"
  key_ring        = google_kms_key_ring.main.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }

  labels = local.labels
}

# Grant Storage service account access to KMS key
resource "google_kms_crypto_key_iam_member" "storage" {
  crypto_key_id = google_kms_crypto_key.storage.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
}

# Grant BigQuery service account access to KMS key
resource "google_kms_crypto_key_iam_member" "bigquery" {
  crypto_key_id = google_kms_crypto_key.bigquery.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:bq-${data.google_project.current.number}@bigquery-encryption.iam.gserviceaccount.com"
}

# Grant Compute service account access to KMS key
resource "google_kms_crypto_key_iam_member" "compute" {
  crypto_key_id = google_kms_crypto_key.compute.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com"
}

# Secret Manager for sensitive data
resource "google_secret_manager_secret" "example" {
  secret_id = "${var.project_name}-${var.environment}-secret"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.region

        # SC-28: Customer-managed key for secrets
        customer_managed_encryption {
          kms_key_name = google_kms_crypto_key.secrets.id
        }
      }
    }
  }

  labels = local.labels
}

resource "google_kms_crypto_key" "secrets" {
  name            = "secrets-key"
  key_ring        = google_kms_key_ring.main.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "7776000s"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE"
  }

  labels = local.labels
}

# ==============================================================================
# Common Variables and Locals
# ==============================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "compliance_framework" {
  description = "Compliance framework (FedRAMP, GovRAMP, CMMC)"
  type        = string
  default     = "FedRAMP"
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}

locals {
  # Note: GCP uses "labels" not "tags", and keys must be lowercase
  labels = merge(var.labels, {
    environment          = lower(var.environment)
    compliance-framework = lower(replace(var.compliance_framework, " ", "-"))
    managed-by           = "terraform"
  })
}

data "google_project" "current" {
  project_id = var.project_id
}
