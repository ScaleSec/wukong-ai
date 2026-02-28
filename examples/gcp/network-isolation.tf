# GCP Network Isolation Patterns
# Control Implementations: SC-7, AC-4, SC-8

# ==============================================================================
# SC-7: Boundary Protection
# ==============================================================================

# VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.project_name}-${var.environment}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# Private Subnet for workloads
resource "google_compute_subnetwork" "private" {
  name          = "${var.project_name}-${var.environment}-private"
  project       = var.project_id
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.main.id

  # AC-4: Enable Private Google Access
  private_ip_google_access = true

  # AU-2: VPC Flow Logs
  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  # Secondary ranges for GKE if needed
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/20"
  }
}

# Cloud Router for NAT
resource "google_compute_router" "main" {
  name    = "${var.project_name}-${var.environment}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.main.id
}

# Cloud NAT for outbound connectivity
resource "google_compute_router_nat" "main" {
  name                               = "${var.project_name}-${var.environment}-nat"
  project                            = var.project_id
  router                             = google_compute_router.main.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # AU-2: NAT logging
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ==============================================================================
# Firewall Rules
# ==============================================================================

# SC-7: Default deny ingress (implicit, but explicit for clarity)
resource "google_compute_firewall" "deny_all_ingress" {
  name        = "${var.project_name}-${var.environment}-deny-all-ingress"
  project     = var.project_id
  network     = google_compute_network.main.name
  direction   = "INGRESS"
  priority    = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow internal communication
resource "google_compute_firewall" "allow_internal" {
  name        = "${var.project_name}-${var.environment}-allow-internal"
  project     = var.project_id
  network     = google_compute_network.main.name
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow IAP for SSH (IA-2: Authenticated access)
resource "google_compute_firewall" "allow_iap_ssh" {
  name        = "${var.project_name}-${var.environment}-allow-iap-ssh"
  project     = var.project_id
  network     = google_compute_network.main.name
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP's IP range
  source_ranges = ["35.235.240.0/20"]

  target_tags = ["allow-ssh"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow health check probes
resource "google_compute_firewall" "allow_health_checks" {
  name        = "${var.project_name}-${var.environment}-allow-health-checks"
  project     = var.project_id
  network     = google_compute_network.main.name
  direction   = "INGRESS"
  priority    = 1000

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  # Google health check ranges
  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = ["allow-health-check"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# ==============================================================================
# AC-4: Information Flow Enforcement (Private Service Connect)
# ==============================================================================

# Private Service Connect endpoint for Google APIs
resource "google_compute_global_address" "psc_google_apis" {
  name         = "${var.project_name}-${var.environment}-psc-google-apis"
  project      = var.project_id
  purpose      = "PRIVATE_SERVICE_CONNECT"
  address_type = "INTERNAL"
  network      = google_compute_network.main.id
  address      = "10.0.255.1"
}

resource "google_compute_global_forwarding_rule" "psc_google_apis" {
  name                  = "${var.project_name}-${var.environment}-psc-google-apis"
  project               = var.project_id
  target                = "all-apis"
  network               = google_compute_network.main.id
  ip_address            = google_compute_global_address.psc_google_apis.id
  load_balancing_scheme = ""
}

# Private DNS zone for googleapis.com
resource "google_dns_managed_zone" "googleapis" {
  name        = "${var.project_name}-${var.environment}-googleapis"
  project     = var.project_id
  dns_name    = "googleapis.com."
  description = "Private zone for Google APIs"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.main.id
    }
  }
}

resource "google_dns_record_set" "googleapis_a" {
  name         = "*.googleapis.com."
  project      = var.project_id
  managed_zone = google_dns_managed_zone.googleapis.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.psc_google_apis.address]
}

# Private DNS zone for gcr.io (Container Registry)
resource "google_dns_managed_zone" "gcr" {
  name        = "${var.project_name}-${var.environment}-gcr"
  project     = var.project_id
  dns_name    = "gcr.io."
  description = "Private zone for GCR"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.main.id
    }
  }
}

resource "google_dns_record_set" "gcr_a" {
  name         = "*.gcr.io."
  project      = var.project_id
  managed_zone = google_dns_managed_zone.gcr.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.psc_google_apis.address]
}

# ==============================================================================
# Service Networking for Cloud SQL, etc.
# ==============================================================================

# Reserve IP range for private services
resource "google_compute_global_address" "private_services" {
  name          = "${var.project_name}-${var.environment}-private-services"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

# Create private connection
resource "google_service_networking_connection" "private_services" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services.name]
}

# ==============================================================================
# Cloud Armor (WAF)
# ==============================================================================

resource "google_compute_security_policy" "main" {
  name    = "${var.project_name}-${var.environment}-security-policy"
  project = var.project_id

  # Default rule - deny all
  rule {
    action   = "deny(403)"
    priority = "2147483647"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    description = "Default deny rule"
  }

  # Allow US traffic
  rule {
    action   = "allow"
    priority = "1000"

    match {
      expr {
        expression = "origin.region_code == 'US'"
      }
    }

    description = "Allow US traffic"
  }

  # Block known malicious IPs (example)
  rule {
    action   = "deny(403)"
    priority = "100"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["192.0.2.0/24"] # Example blocked range
      }
    }

    description = "Block known bad actors"
  }

  # Preconfigured WAF rules
  rule {
    action   = "deny(403)"
    priority = "200"

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }

    description = "XSS protection"
  }

  rule {
    action   = "deny(403)"
    priority = "201"

    match {
      expr {
        expression = "evaluatePreconfiguredExpr('sqli-stable')"
      }
    }

    description = "SQL injection protection"
  }

  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = true
    }
  }
}

# ==============================================================================
# Organization Policies for network security
# ==============================================================================

# These require org-level permissions
# resource "google_org_policy_policy" "restrict_public_ip" {
#   name   = "projects/${var.project_id}/policies/compute.vmExternalIpAccess"
#   parent = "projects/${var.project_id}"
#
#   spec {
#     rules {
#       enforce = "TRUE"
#     }
#   }
# }

# ==============================================================================
# Service Account for network operations
# ==============================================================================

resource "google_service_account" "compute" {
  account_id   = "${var.project_name}-${var.environment}-compute"
  display_name = "Compute Service Account"
  project      = var.project_id
}

# Minimal permissions
resource "google_project_iam_member" "compute_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.compute.email}"
}

resource "google_project_iam_member" "compute_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.compute.email}"
}

# ==============================================================================
# Outputs
# ==============================================================================

output "network_id" {
  value = google_compute_network.main.id
}

output "private_subnet_id" {
  value = google_compute_subnetwork.private.id
}

output "psc_endpoint_ip" {
  value = google_compute_global_address.psc_google_apis.address
}
