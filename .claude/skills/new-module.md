---
name: new-module
description: Guided workflow for creating new GovRAMP-compliant Terraform modules
---

## Overview

This compound workflow guides the creation of a new Terraform module that is:
- Architecturally sound and follows established patterns
- GovRAMP compliant with proper control implementations
- Secure by design
- Well documented

## Instructions

When creating a new module, follow these steps:

### Step 1: Requirements Gathering

Ask the user:
1. What Azure resource(s) should this module provision?
2. What is the primary use case?
3. Are there specific compliance requirements beyond standard GovRAMP?
4. Should this integrate with existing modules (e.g., Key Vault, Log Analytics)?

### Step 2: Architecture Design (Architect Perspective)

Design the module structure:

1. **File Structure:**
   ```
   modules/[resource-name]/
   ├── main.tf
   ├── variables.tf
   ├── outputs.tf
   ├── versions.tf (if specific provider requirements)
   └── README.md
   ```

2. **Variable Design:**
   - Required: project_name, environment, location, resource_group_name
   - Required for compliance: log_analytics_workspace_id
   - Resource-specific variables with sensible defaults
   - Feature flags for optional components

3. **Output Design:**
   - id, name (always required)
   - Resource-specific outputs for downstream modules

4. **Resource Naming:**
   - Follow pattern: `${var.project_name}-${var.environment}-[suffix]`

### Step 3: Compliance Implementation (Compliance Perspective)

Identify and implement required controls:

1. **SC-8 (Transmission Confidentiality):**
   ```hcl
   minimum_tls_version = "1.2"
   ```

2. **SC-28 (Protection at Rest):**
   ```hcl
   infrastructure_encryption_enabled = true
   ```

3. **AU-2, AU-12 (Audit Events):**
   ```hcl
   resource "azurerm_monitor_diagnostic_setting" "this" {
     name                       = "${var.project_name}-diag"
     target_resource_id         = azurerm_[resource].this.id
     log_analytics_workspace_id = var.log_analytics_workspace_id

     enabled_log { category = "AuditEvent" }
     enabled_log { category = "AllLogs" }
     metric { category = "AllMetrics" }
   }
   ```

4. **SC-7, AC-4 (Network Isolation):**
   ```hcl
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

5. **Tags (CM-8):**
   ```hcl
   tags = merge(var.tags, {
     Environment         = var.environment
     ComplianceFramework = "GovRAMP"
     ManagedBy          = "Terraform"
   })
   ```

### Step 4: Security Hardening (Security Perspective)

Apply security best practices:

1. **Disable public access by default**
2. **Enable encryption everywhere**
3. **Use managed identities instead of keys**
4. **Configure diagnostic settings**
5. **Add network rules if applicable**
6. **Document any security considerations**

### Step 5: Documentation (Documentation Perspective)

Create comprehensive documentation:

1. **README.md with:**
   - Overview and purpose
   - GovRAMP control mappings table
   - Usage example
   - Input/output tables
   - Security considerations

2. **Inline comments for:**
   - Control implementations
   - Security decisions
   - Complex logic

## Output Template

### main.tf

```hcl
# [Module Name] Module
# GovRAMP Compliant Azure [Resource Type]
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
    ComplianceFramework = "GovRAMP"
    ManagedBy          = "Terraform"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "azurerm_[resource_type]" "this" {
  name                = "${local.resource_name}-[suffix]"
  location            = var.location
  resource_group_name = var.resource_group_name

  # SC-8: Transmission Confidentiality
  minimum_tls_version = "1.2"

  # SC-28: Protection at Rest
  # [encryption settings specific to resource]

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

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AllLogs"
  }

  metric {
    category = "AllMetrics"
  }
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

### variables.tf

```hcl
# Required Variables
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
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

### outputs.tf

```hcl
output "id" {
  description = "Resource ID"
  value       = azurerm_[resource_type].this.id
}

output "name" {
  description = "Resource name"
  value       = azurerm_[resource_type].this.name
}

output "private_endpoint_id" {
  description = "Private endpoint ID (if enabled)"
  value       = var.enable_private_endpoint ? azurerm_private_endpoint.this[0].id : null
}
```

### README.md

```markdown
# [Module Name]

## Overview

This module provisions a GovRAMP-compliant Azure [Resource Type] with:
- TLS 1.2+ encryption in transit
- Encryption at rest
- Optional private endpoint for network isolation
- Diagnostic settings for audit logging

## GovRAMP Control Implementation

| Control ID | Control Name | Implementation |
|------------|--------------|----------------|
| SC-8 | Transmission Confidentiality | TLS 1.2+ enforced |
| SC-28 | Protection at Rest | [Encryption method] |
| AU-2 | Audit Events | Diagnostic settings enabled |
| AU-12 | Audit Record Generation | All logs sent to Log Analytics |
| SC-7 | Boundary Protection | Private endpoint (optional) |
| AC-4 | Information Flow Enforcement | Private endpoint (optional) |

## Usage

\`\`\`hcl
module "[module_name]" {
  source = "../modules/[module-name]"

  project_name        = "myproject"
  environment         = "prod"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.this.name

  # Required for compliance
  log_analytics_workspace_id = module.log_analytics.id
  private_endpoint_subnet_id = module.vnet.private_endpoint_subnet_id

  tags = {
    Application = "MyApp"
  }
}
\`\`\`

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name for resource naming | string | n/a | yes |
| environment | Environment (dev, staging, prod) | string | n/a | yes |
| location | Azure region | string | n/a | yes |
| resource_group_name | Resource group name | string | n/a | yes |
| log_analytics_workspace_id | Log Analytics ID for diagnostics | string | n/a | yes |
| private_endpoint_subnet_id | Subnet ID for private endpoint | string | null | no |
| enable_diagnostic_settings | Enable diagnostic settings | bool | true | no |
| enable_private_endpoint | Enable private endpoint | bool | true | no |
| enable_public_access | Enable public access | bool | false | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| id | Resource ID |
| name | Resource name |
| private_endpoint_id | Private endpoint ID (if enabled) |

## Security Considerations

1. **Public Access:** Disabled by default. Only enable for development with caution.
2. **Private Endpoint:** Recommended for production to ensure network isolation.
3. **Encryption:** All data encrypted at rest and in transit.
4. **Logging:** All audit events sent to Log Analytics for compliance.
\`\`\`
```

## Completion Checklist

Before finalizing the module, verify:

- [ ] All required variables present (project_name, environment, location, resource_group_name)
- [ ] log_analytics_workspace_id for diagnostics
- [ ] Diagnostic settings resource created
- [ ] TLS 1.2+ configured
- [ ] Encryption at rest enabled
- [ ] Private endpoint option available
- [ ] Public access disabled by default
- [ ] Standard outputs (id, name)
- [ ] GovRAMP tags applied
- [ ] Control mappings documented in README
- [ ] terraform validate passes
- [ ] terraform fmt passes
