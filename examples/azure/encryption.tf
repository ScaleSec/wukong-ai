# Azure Encryption Patterns
# Control Implementations: SC-8, SC-28, SC-12

# ==============================================================================
# SC-8: Transmission Confidentiality and Integrity
# ==============================================================================

# TLS 1.2+ enforcement for Storage Account
resource "azurerm_storage_account" "example" {
  name                     = "${var.project_name}${var.environment}st"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  # SC-8: Enforce TLS 1.2 minimum
  min_tls_version = "TLS1_2"

  # SC-8: Require HTTPS
  https_traffic_only_enabled = true

  tags = local.tags
}

# TLS 1.2+ enforcement for Key Vault
resource "azurerm_key_vault" "example" {
  name                = "${var.project_name}-${var.environment}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # SC-8: TLS is enforced by default on Key Vault
  # No explicit setting needed - Azure enforces TLS 1.2+

  # SC-7: Network isolation
  public_network_access_enabled = false

  tags = local.tags
}

# TLS for Azure SQL
resource "azurerm_mssql_server" "example" {
  name                         = "${var.project_name}-${var.environment}-sql"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  # SC-8: Minimum TLS version
  minimum_tls_version = "1.2"

  tags = local.tags
}

# ==============================================================================
# SC-28: Protection of Information at Rest
# ==============================================================================

# Storage Account with encryption
resource "azurerm_storage_account" "encrypted" {
  name                     = "${var.project_name}${var.environment}enc"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  # SC-28: Infrastructure encryption (double encryption)
  infrastructure_encryption_enabled = true

  # SC-28: Blob encryption with customer-managed key (optional)
  # Requires Key Vault key and identity
  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

# Customer-managed key for Storage Account
resource "azurerm_storage_account_customer_managed_key" "example" {
  storage_account_id = azurerm_storage_account.encrypted.id
  key_vault_id       = azurerm_key_vault.example.id
  key_name           = azurerm_key_vault_key.storage.name
}

# Azure SQL with Transparent Data Encryption (TDE)
resource "azurerm_mssql_database" "example" {
  name      = "${var.project_name}-${var.environment}-db"
  server_id = azurerm_mssql_server.example.id

  # SC-28: TDE is enabled by default
  # For customer-managed keys, use azurerm_mssql_server_transparent_data_encryption
}

# Cosmos DB with encryption
resource "azurerm_cosmosdb_account" "example" {
  name                = "${var.project_name}-${var.environment}-cosmos"
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  # SC-28: Encryption at rest is enabled by default
  # For CMK, use key_vault_key_id

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  tags = local.tags
}

# ==============================================================================
# SC-12: Cryptographic Key Establishment and Management
# ==============================================================================

# Key Vault for key management
resource "azurerm_key_vault" "keys" {
  name                       = "${var.project_name}-${var.environment}-keys"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium" # HSM-backed keys
  soft_delete_retention_days = 90
  purge_protection_enabled   = true # Required for CMK

  # SC-12: Enable RBAC for key management
  enable_rbac_authorization = true

  tags = local.tags
}

# Encryption key with rotation
resource "azurerm_key_vault_key" "storage" {
  name         = "storage-encryption-key"
  key_vault_id = azurerm_key_vault.keys.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  # SC-12: Key rotation policy
  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }
    expire_after         = "P365D"
    notify_before_expiry = "P30D"
  }
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

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
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

data "azurerm_client_config" "current" {}
