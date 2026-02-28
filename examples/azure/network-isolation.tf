# Azure Network Isolation Patterns
# Control Implementations: SC-7, AC-4, SC-8

# ==============================================================================
# SC-7: Boundary Protection
# ==============================================================================

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-${var.environment}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]

  tags = local.tags
}

# Subnet for private endpoints
resource "azurerm_subnet" "private_endpoints" {
  name                 = "${var.project_name}-${var.environment}-pe-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  # Required for private endpoints
  private_endpoint_network_policies = "Disabled"
}

# Subnet for workloads
resource "azurerm_subnet" "workloads" {
  name                 = "${var.project_name}-${var.environment}-workload-snet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  # SC-7: Enable service endpoints for Azure services
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.Sql",
    "Microsoft.KeyVault",
  ]
}

# Network Security Group
resource "azurerm_network_security_group" "workloads" {
  name                = "${var.project_name}-${var.environment}-workload-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # SC-7: Default deny inbound
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SC-7: Allow only necessary traffic (example: HTTPS from load balancer)
  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  tags = local.tags
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "workloads" {
  subnet_id                 = azurerm_subnet.workloads.id
  network_security_group_id = azurerm_network_security_group.workloads.id
}

# ==============================================================================
# AC-4: Information Flow Enforcement (Private Endpoints)
# ==============================================================================

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

# Link DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "${var.project_name}-kv-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = local.tags
}

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "keyvault" {
  name                = "${var.project_name}-${var.environment}-kv-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${var.project_name}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.example.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "keyvault-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }

  tags = local.tags
}

# Private DNS Zone for Storage
resource "azurerm_private_dns_zone" "storage_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_blob" {
  name                  = "${var.project_name}-blob-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage_blob.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = local.tags
}

# Private Endpoint for Storage
resource "azurerm_private_endpoint" "storage" {
  name                = "${var.project_name}-${var.environment}-st-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${var.project_name}-st-psc"
    private_connection_resource_id = azurerm_storage_account.example.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "storage-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_blob.id]
  }

  tags = local.tags
}

# Private DNS Zone for SQL
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "${var.project_name}-sql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = azurerm_virtual_network.main.id
  registration_enabled  = false

  tags = local.tags
}

# Private Endpoint for SQL
resource "azurerm_private_endpoint" "sql" {
  name                = "${var.project_name}-${var.environment}-sql-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.private_endpoints.id

  private_service_connection {
    name                           = "${var.project_name}-sql-psc"
    private_connection_resource_id = azurerm_mssql_server.example.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "sql-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }

  tags = local.tags
}

# ==============================================================================
# Disable Public Access on Resources
# ==============================================================================

# Key Vault - disable public access
resource "azurerm_key_vault" "example" {
  name                          = "${var.project_name}-${var.environment}-kv"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"

  # SC-7: Disable public network access
  public_network_access_enabled = false

  # Network rules (if public access is ever needed temporarily)
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  tags = local.tags
}

# Storage Account - disable public access
resource "azurerm_storage_account" "example" {
  name                     = "${var.project_name}${var.environment}st"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  # SC-7: Disable public blob access
  allow_nested_items_to_be_public = false

  # SC-7: Disable public network access
  public_network_access_enabled = false

  # Network rules
  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.workloads.id]
  }

  tags = local.tags
}

# SQL Server - disable public access
resource "azurerm_mssql_server" "example" {
  name                         = "${var.project_name}-${var.environment}-sql"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password

  # SC-7: Disable public network access
  public_network_access_enabled = false

  tags = local.tags
}

# ==============================================================================
# Azure Firewall (for egress filtering)
# ==============================================================================

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet" # Required name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.254.0/24"]
}

resource "azurerm_public_ip" "firewall" {
  name                = "${var.project_name}-${var.environment}-fw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.tags
}

resource "azurerm_firewall" "main" {
  name                = "${var.project_name}-${var.environment}-fw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  tags = local.tags
}

# Firewall policy with application rules
resource "azurerm_firewall_policy" "main" {
  name                = "${var.project_name}-${var.environment}-fw-policy"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.tags
}

resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "${var.project_name}-rules"
  firewall_policy_id = azurerm_firewall_policy.main.id
  priority           = 100

  # SC-7: Allow only necessary outbound traffic
  application_rule_collection {
    name     = "AllowedDestinations"
    priority = 100
    action   = "Allow"

    rule {
      name = "AllowAzureServices"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["10.0.0.0/16"]
      destination_fqdns = ["*.azure.com", "*.microsoft.com"]
    }
  }

  # Deny all other traffic (implicit, but can be explicit)
  network_rule_collection {
    name     = "DenyAll"
    priority = 1000
    action   = "Deny"

    rule {
      name                  = "DenyInternet"
      protocols             = ["Any"]
      source_addresses      = ["10.0.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["*"]
    }
  }
}
