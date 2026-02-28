# Azure Logging Patterns
# Control Implementations: AU-2, AU-3, AU-6, AU-12

# ==============================================================================
# AU-2, AU-12: Audit Events and Audit Record Generation
# ==============================================================================

# Log Analytics Workspace (Central logging destination)
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-${var.environment}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"

  # AU-11: Audit Record Retention (90 days minimum for most frameworks)
  retention_in_days = 90

  # Enable features
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  tags = local.tags
}

# Diagnostic Settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "${var.project_name}-kv-diag"
  target_resource_id         = azurerm_key_vault.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # AU-2: Audit events to capture
  enabled_log {
    category = "AuditEvent"
  }

  # All logs for comprehensive auditing
  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  # AU-3: Content of audit records (metrics provide context)
  metric {
    category = "AllMetrics"
  }
}

# Diagnostic Settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "${var.project_name}-storage-diag"
  target_resource_id         = "${azurerm_storage_account.example.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # AU-2: Storage read/write/delete operations
  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "AllMetrics"
  }
}

# Diagnostic Settings for Azure SQL
resource "azurerm_monitor_diagnostic_setting" "sql" {
  name                       = "${var.project_name}-sql-diag"
  target_resource_id         = azurerm_mssql_database.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # AU-2: SQL audit events
  enabled_log {
    category = "SQLSecurityAuditEvents"
  }

  enabled_log {
    category = "DevOpsOperationsAudit"
  }

  enabled_log {
    category = "QueryStoreRuntimeStatistics"
  }

  metric {
    category = "AllMetrics"
  }
}

# Activity Log export to Log Analytics
resource "azurerm_monitor_diagnostic_setting" "activity_log" {
  name                       = "${var.project_name}-activity-diag"
  target_resource_id         = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # AU-2: Subscription-level activity
  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Recommendation"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Autoscale"
  }

  enabled_log {
    category = "ResourceHealth"
  }
}

# ==============================================================================
# AU-6: Audit Review, Analysis, and Reporting
# ==============================================================================

# Alert rule for security events
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "security_alert" {
  name                = "${var.project_name}-security-alert"
  location            = var.location
  resource_group_name = var.resource_group_name

  scopes              = [azurerm_log_analytics_workspace.main.id]
  description         = "Alert on security-related events"
  severity            = 1
  enabled             = true
  evaluation_frequency = "PT5M"
  window_duration     = "PT5M"

  criteria {
    query = <<-QUERY
      AzureActivity
      | where CategoryValue == "Security"
      | where ActivityStatusValue == "Failed"
    QUERY

    operator                = "GreaterThan"
    threshold               = 0
    time_aggregation_method = "Count"
  }

  action {
    action_groups = [azurerm_monitor_action_group.security.id]
  }

  tags = local.tags
}

# Action group for notifications
resource "azurerm_monitor_action_group" "security" {
  name                = "${var.project_name}-security-ag"
  resource_group_name = var.resource_group_name
  short_name          = "security"

  email_receiver {
    name          = "security-team"
    email_address = var.security_email
  }

  tags = local.tags
}

# ==============================================================================
# Microsoft Sentinel (SIEM) Integration
# ==============================================================================

# Sentinel workspace solution
resource "azurerm_log_analytics_solution" "sentinel" {
  solution_name         = "SecurityInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}

# Azure Activity data connector
resource "azurerm_sentinel_data_connector_azure_activity" "activity" {
  name                       = "${var.project_name}-activity-connector"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.main.workspace_id
}

# Sentinel onboarding
resource "azurerm_sentinel_log_analytics_workspace_onboarding" "main" {
  workspace_id                 = azurerm_log_analytics_workspace.main.id
  customer_managed_key_enabled = false
}

# ==============================================================================
# Reusable Diagnostic Settings Module Pattern
# ==============================================================================

# This pattern can be used as a module for any resource
variable "diagnostic_settings" {
  description = "Map of resources requiring diagnostic settings"
  type = map(object({
    resource_id = string
    log_categories = list(string)
    metric_categories = list(string)
  }))
  default = {}
}

resource "azurerm_monitor_diagnostic_setting" "dynamic" {
  for_each = var.diagnostic_settings

  name                       = "${each.key}-diag"
  target_resource_id         = each.value.resource_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
    }
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

data "azurerm_subscription" "current" {}
