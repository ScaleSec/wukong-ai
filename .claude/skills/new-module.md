---
name: new-module
description: Guided workflow for creating new compliant Terraform modules (multi-cloud, multi-framework)
---

## Overview

This compound workflow guides the creation of a new Terraform module that is:
- Architecturally sound and follows established patterns
- Compliant with the configured framework
- Secure by design
- Well documented

**Adapts to:** FedRAMP, GovRAMP, CMMC | Azure, AWS, GCP

## Required Context

**CRITICAL: Before starting module creation, you MUST read the session context:**

1. Read `/.claude/session-context.md` - Current engagement configuration
2. Read the cloud provider data file:
   - Azure: `/.claude/data/clouds/azure.yaml`
   - AWS: `/.claude/data/clouds/aws.yaml`
   - GCP: `/.claude/data/clouds/gcp.yaml`
3. Read the framework data file:
   - FedRAMP: `/.claude/data/frameworks/fedramp.yaml`
   - GovRAMP: `/.claude/data/frameworks/govramp.yaml`
   - CMMC: `/.claude/data/frameworks/cmmc.yaml`
4. Reference cloud-specific examples:
   - `/examples/{cloud}/encryption.tf`
   - `/examples/{cloud}/logging.tf`
   - `/examples/{cloud}/network-isolation.tf`

If no session context exists, inform the user to run `/init` first.

## Instructions

When creating a new module, follow these steps:

### Step 1: Requirements Gathering

Ask the user:
1. What cloud resource(s) should this module provision?
2. What is the primary use case?
3. Are there specific compliance requirements beyond the standard baseline?
4. Should this integrate with existing modules (secrets manager, logging, etc.)?

### Step 2: Architecture Design (Architect Perspective)

Design the module structure based on session context:

1. **File Structure:**
   ```
   modules/[resource-name]/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   ├── versions.tf (if specific provider requirements)
   └── README.md
   ```

2. **Variable Design (Cloud-Specific):**

   **Azure:**
   - Required: project_name, environment, location, resource_group_name
   - Required for compliance: log_analytics_workspace_id
   - Tags via `tags` variable

   **AWS:**
   - Required: project_name, environment, region
   - Required for compliance: cloudwatch_log_group_arn
   - Tags via `tags` variable

   **GCP:**
   - Required: project_name, project_id, environment, region
   - Required for compliance: logging_bucket_name
   - Labels via `labels` variable (lowercase only)

3. **Output Design:**
   - id, name (always required)
   - Resource-specific outputs for downstream modules

4. **Resource Naming:**
   - Follow pattern: `${var.project_name}-${var.environment}-[suffix]`

### Step 3: Compliance Implementation (Compliance Perspective)

Implement controls based on the configured framework. Reference `/examples/{cloud}/` for patterns.

#### Control Implementation by Cloud

**Azure (azurerm):**
```hcl
# SC-8 / 3.13.8: Transmission Confidentiality
minimum_tls_version = "1.2"

# SC-28 / 3.13.16: Protection at Rest
infrastructure_encryption_enabled = true

# AU-2, AU-12 / 3.3.1, 3.3.2: Audit Events
resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "${var.project_name}-diag"
  target_resource_id         = azurerm_[resource].this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AuditEvent" }
  enabled_log { category = "AllLogs" }
  metric { category = "AllMetrics" }
}

# SC-7, AC-4 / 3.13.1, 3.1.3: Network Isolation
public_network_access_enabled = false

resource "azurerm_private_endpoint" "this" {
  name                = "${var.project_name}-${var.environment}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.project_name}-psc"
    private_connection_resource_id = azurerm_[resource].this.id
    is_manual_connection           = false
    subresource_names              = ["[subresource]"]
  }
}
```

**AWS (aws):**
```hcl
# SC-8 / 3.13.8: Transmission Confidentiality
ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"

# SC-28 / 3.13.16: Protection at Rest
resource "aws_kms_key" "this" {
  description             = "${var.project_name} encryption key"
  enable_key_rotation     = true
  deletion_window_in_days = 30
}

# AU-2, AU-12 / 3.3.1, 3.3.2: Audit Events
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/${var.project_name}/${var.environment}"
  retention_in_days = 90
  kms_key_id        = aws_kms_key.logs.arn
}

# SC-7, AC-4 / 3.13.1, 3.1.3: Network Isolation
resource "aws_vpc_endpoint" "this" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.[service]"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true
}
```

**GCP (google):**
```hcl
# SC-8 / 3.13.8: Transmission Confidentiality
resource "google_compute_ssl_policy" "this" {
  name            = "${var.project_name}-${var.environment}-ssl"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

# SC-28 / 3.13.16: Protection at Rest
resource "google_kms_crypto_key" "this" {
  name            = "${var.project_name}-${var.environment}-key"
  key_ring        = google_kms_key_ring.this.id
  rotation_period = "7776000s"  # 90 days
  purpose         = "ENCRYPT_DECRYPT"
}

# AU-2, AU-12 / 3.3.1, 3.3.2: Audit Events
resource "google_logging_project_sink" "this" {
  name                   = "${var.project_name}-${var.environment}-sink"
  destination            = "storage.googleapis.com/${google_storage_bucket.logs.name}"
  unique_writer_identity = true
}

# SC-7, AC-4 / 3.13.1, 3.1.3: Network Isolation
resource "google_compute_global_address" "private_ip" {
  name          = "${var.project_name}-${var.environment}-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_id
}
```

#### Compliance Tags/Labels

```hcl
# Azure/AWS (tags)
locals {
  tags = merge(var.tags, {
    Environment         = var.environment
    ComplianceFramework = var.compliance_framework  # From session context
    ManagedBy           = "Terraform"
  })
}

# GCP (labels - lowercase only)
locals {
  labels = merge(var.labels, {
    environment          = lower(var.environment)
    compliance-framework = lower(replace(var.compliance_framework, " ", "-"))
    managed-by           = "terraform"
  })
}
```

### Step 4: Security Hardening (Security Perspective)

Apply security best practices (all clouds):

1. **Disable public access by default**
2. **Enable encryption everywhere** (CMK/KMS preferred)
3. **Use managed/workload identities instead of keys**
4. **Configure audit logging**
5. **Add network rules/security groups if applicable**
6. **Document any security considerations**

Reference cloud-specific security checks from the security agent.

### Step 5: Documentation (Documentation Perspective)

Create comprehensive documentation:

1. **README.md with:**
   - Overview and purpose
   - Compliance control mappings table (framework-specific)
   - Usage example (cloud-specific)
   - Input/output tables
   - Security considerations

2. **Inline comments for:**
   - Control implementations with IDs
   - Security decisions
   - Complex logic

## Output Templates

### Azure Module Template

#### main.tf
```hcl
# [Module Name] Module
# [Framework] Compliant Azure [Resource Type]
#
# Control Implementations:
# - SC-8: TLS 1.2+ enforced
# - SC-28: Encryption at rest enabled
# - AU-2/AU-12: Diagnostic settings configured
# - SC-7/AC-4: Private endpoint (optional)

locals {
  resource_name = "${var.project_name}-${var.environment}"

  default_tags = {
    Environment         = var.environment
    ComplianceFramework = var.compliance_framework
    ManagedBy           = "Terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_[resource_type]" "this" {
  name                = "${local.resource_name}-[suffix]"
  location            = var.location
  resource_group_name = var.resource_group_name

  # SC-8: Transmission Confidentiality
  minimum_tls_version = "1.2"

  # SC-7: Boundary Protection
  public_network_access_enabled = var.enable_public_access ? true : false

  tags = local.tags
}

# AU-2, AU-12: Audit Events
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.enable_diagnostic_settings ? 1 : 0

  name                       = "${local.resource_name}-diag"
  target_resource_id         = azurerm_[resource_type].this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log { category = "AuditEvent" }
  enabled_log { category = "AllLogs" }
  metric { category = "AllMetrics" }
}

# SC-7, AC-4: Network Isolation (Private Endpoint)
resource "azurerm_private_endpoint" "this" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${local.resource_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${local.resource_name}-psc"
    private_connection_resource_id = azurerm_[resource_type].this.id
    is_manual_connection           = false
    subresource_names              = ["[subresource]"]
  }

  tags = local.tags
}
```

#### variables.tf (Azure)
```hcl
# Required Variables
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "compliance_framework" {
  description = "Compliance framework (FedRAMP, GovRAMP, CMMC)"
  type        = string
  default     = "FedRAMP"
}

# Compliance Variables
variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for diagnostic settings (AU-2, AU-12)"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint (SC-7, AC-4)"
  type        = string
  default     = null
}

# Feature Flags
variable "enable_diagnostic_settings" {
  description = "Enable diagnostic settings for logging (AU-2)"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint for network isolation (SC-7)"
  type        = bool
  default     = true
}

variable "enable_public_access" {
  description = "Enable public network access (NOT recommended for production)"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

### AWS Module Template

#### main.tf
```hcl
# [Module Name] Module
# [Framework] Compliant AWS [Resource Type]
#
# Control Implementations:
# - SC-8: TLS 1.2+ enforced
# - SC-28: KMS encryption enabled
# - AU-2/AU-12: CloudWatch logging configured
# - SC-7/AC-4: VPC endpoint (optional)

locals {
  resource_name = "${var.project_name}-${var.environment}"

  default_tags = {
    Environment         = var.environment
    ComplianceFramework = var.compliance_framework
    ManagedBy           = "Terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "aws_[resource_type]" "this" {
  # Resource configuration

  tags = local.tags
}

# AU-2, AU-12: Audit Events
resource "aws_cloudwatch_log_group" "this" {
  count = var.enable_logging ? 1 : 0

  name              = "/aws/${var.project_name}/${var.environment}/[resource]"
  retention_in_days = 90
  kms_key_id        = var.kms_key_arn

  tags = local.tags
}

# SC-7, AC-4: Network Isolation (VPC Endpoint)
resource "aws_vpc_endpoint" "this" {
  count = var.enable_vpc_endpoint ? 1 : 0

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.[service]"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.endpoint[0].id]
  private_dns_enabled = true

  tags = local.tags
}
```

#### variables.tf (AWS)
```hcl
# Required Variables
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "compliance_framework" {
  description = "Compliance framework (FedRAMP, GovRAMP, CMMC)"
  type        = string
  default     = "FedRAMP"
}

# Compliance Variables
variable "kms_key_arn" {
  description = "KMS key ARN for encryption (SC-28)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for network isolation (SC-7)"
  type        = string
  default     = null
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for VPC endpoint (SC-7)"
  type        = list(string)
  default     = []
}

# Feature Flags
variable "enable_logging" {
  description = "Enable CloudWatch logging (AU-2)"
  type        = bool
  default     = true
}

variable "enable_vpc_endpoint" {
  description = "Enable VPC endpoint for network isolation (SC-7)"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

### GCP Module Template

#### main.tf
```hcl
# [Module Name] Module
# [Framework] Compliant GCP [Resource Type]
#
# Control Implementations:
# - SC-8: TLS 1.2+ enforced
# - SC-28: CMEK encryption enabled
# - AU-2/AU-12: Cloud Logging configured
# - SC-7/AC-4: Private Service Connect (optional)

locals {
  resource_name = "${var.project_name}-${var.environment}"

  default_labels = {
    environment          = lower(var.environment)
    compliance-framework = lower(replace(var.compliance_framework, " ", "-"))
    managed-by           = "terraform"
  }

  labels = merge(local.default_labels, var.labels)
}

resource "google_[resource_type]" "this" {
  name    = "${local.resource_name}-[suffix]"
  project = var.project_id

  labels = local.labels
}

# AU-2, AU-12: Audit Events
resource "google_logging_project_sink" "this" {
  count = var.enable_logging ? 1 : 0

  name                   = "${local.resource_name}-sink"
  project                = var.project_id
  destination            = "storage.googleapis.com/${var.logging_bucket_name}"
  unique_writer_identity = true

  filter = "resource.type = [resource_type]"
}

# SC-7, AC-4: Network Isolation (Private Service Connect)
resource "google_compute_global_address" "private_ip" {
  count = var.enable_private_service_connect ? 1 : 0

  name          = "${local.resource_name}-private-ip"
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = var.vpc_id
}
```

#### variables.tf (GCP)
```hcl
# Required Variables
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
  description = "GCP region for resources"
  type        = string
}

variable "compliance_framework" {
  description = "Compliance framework (FedRAMP, GovRAMP, CMMC)"
  type        = string
  default     = "FedRAMP"
}

# Compliance Variables
variable "kms_key_id" {
  description = "KMS crypto key ID for encryption (SC-28)"
  type        = string
  default     = null
}

variable "logging_bucket_name" {
  description = "Cloud Storage bucket for logs (AU-2)"
  type        = string
}

variable "vpc_id" {
  description = "VPC network ID for private connectivity (SC-7)"
  type        = string
  default     = null
}

# Feature Flags
variable "enable_logging" {
  description = "Enable Cloud Logging sink (AU-2)"
  type        = bool
  default     = true
}

variable "enable_private_service_connect" {
  description = "Enable Private Service Connect (SC-7)"
  type        = bool
  default     = true
}

# Labels
variable "labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}
```

### outputs.tf (All Clouds)
```hcl
output "id" {
  description = "Resource ID"
  value       = {provider}_{resource_type}.this.id
}

output "name" {
  description = "Resource name"
  value       = {provider}_{resource_type}.this.name
}

# Cloud-specific outputs as needed
```

### README.md Template
```markdown
# [Module Name]

## Overview

This module provisions a [Framework]-compliant [Cloud] [Resource Type] with:
- TLS 1.2+ encryption in transit
- Encryption at rest (CMK/KMS/CMEK)
- Optional private connectivity for network isolation
- Audit logging for compliance

## Session Context

This module is designed for:
- **Cloud Provider:** [Azure/AWS/GCP]
- **Compliance Framework:** [FedRAMP/GovRAMP/CMMC]

## Control Implementation

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| SC-8 / 3.13.8 | Transmission Confidentiality | TLS 1.2+ enforced |
| SC-28 / 3.13.16 | Protection at Rest | [Encryption method] |
| AU-2 / 3.3.1 | Audit Events | Logging enabled |
| AU-12 / 3.3.2 | Audit Record Generation | Logs sent to [destination] |
| SC-7 / 3.13.1 | Boundary Protection | Private connectivity (optional) |
| AC-4 / 3.1.3 | Information Flow Enforcement | Private connectivity (optional) |

## Usage

[Cloud-specific usage example]

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|

## Outputs

| Name | Description |
|------|-------------|

## Security Considerations

1. **Public Access:** Disabled by default. Only enable for development with caution.
2. **Private Connectivity:** Recommended for production to ensure network isolation.
3. **Encryption:** All data encrypted at rest and in transit using managed keys.
4. **Logging:** All audit events captured for compliance requirements.
```

## Completion Checklist

Before finalizing the module, verify based on session context:

### All Clouds
- [ ] All required variables present (project_name, environment, region/location)
- [ ] Compliance framework variable included
- [ ] Logging/diagnostic configuration present
- [ ] Encryption at rest enabled
- [ ] Private connectivity option available
- [ ] Public access disabled by default
- [ ] Standard outputs (id, name)
- [ ] Control mappings documented in README
- [ ] terraform validate passes
- [ ] terraform fmt passes

### Azure-Specific
- [ ] resource_group_name variable
- [ ] log_analytics_workspace_id for diagnostics
- [ ] Tags applied with ComplianceFramework

### AWS-Specific
- [ ] kms_key_arn for encryption
- [ ] vpc_id and private_subnet_ids for VPC endpoints
- [ ] Tags applied with ComplianceFramework

### GCP-Specific
- [ ] project_id variable
- [ ] logging_bucket_name for audit logs
- [ ] Labels applied (lowercase) with compliance-framework
