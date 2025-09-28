terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.0.0"
    }
  }
}
provider "azurerm" {
  features {}
}

variable "location" {
  default = "West Europe"
}

# Base names without suffix
variable "base_rg_name" {
  default = "rg-functionapp-demo"
}
variable "base_function_app_name" {
  default = "funcappdemo"
}
variable "base_storage_account_name" {
  default = "stfuncdemo"
}
variable "base_plan_name" {
  default = "asp-func-demo"
}
variable "base_vnet_name" {
  default = "vnet-func-demo"
}
variable "base_subnet_name" {
  default = "subnet-func-demo"
}

# Generate a 3-char unique ID (lowercase for storage account compliance)
resource "random_string" "suffix" {
  length  = 3
  upper   = false
  special = false
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.base_rg_name}-${random_string.suffix.result}"
  location = var.location
}

# Storage Account (must be globally unique, lowercase only)
resource "azurerm_storage_account" "sa" {
  name                     = "${lower(var.base_storage_account_name)}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = false
}

# App Service Plan (Elastic Premium)
resource "azurerm_service_plan" "plan" {
  name                = "${var.base_plan_name}-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Windows"
  sku_name            = "EP1"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.base_vnet_name}-${random_string.suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Subnet for Function App integration
resource "azurerm_subnet" "subnet" {
  name                 = "${var.base_subnet_name}-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
}

# Service Bus Namespace
resource "azurerm_servicebus_namespace" "sb" {
  name                = "sbns-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
}

# Service Bus Queue
resource "azurerm_servicebus_queue" "queue" {
  name                = "queue1"
  namespace_id        = azurerm_servicebus_namespace.sb.id
}

# Service Bus Topic
resource "azurerm_servicebus_topic" "topic" {
  name                = "topic1"
  namespace_id        = azurerm_servicebus_namespace.sb.id
}

# Service Bus Topic Subscription (acts as consumer group)
resource "azurerm_servicebus_subscription" "subscription" {
  name               = "sub1"
  topic_id           = azurerm_servicebus_topic.topic.id
  max_delivery_count = 10
}

# Service Bus Connection String (primary key from RootManageSharedAccessKey)
data "azurerm_servicebus_namespace_authorization_rule" "root" {
  name         = "RootManageSharedAccessKey"
  namespace_id = azurerm_servicebus_namespace.sb.id
}

# Function App (Windows) with Service Bus connection string in App Settings
resource "azurerm_windows_function_app" "func" {
  name                       = "${var.base_function_app_name}-${random_string.suffix.result}"
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  service_plan_id            = azurerm_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  https_only                 = true

  site_config {
    application_stack {
      dotnet_version = "v8.0"
    }
    vnet_route_all_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    FUNCTIONS_EXTENSION_VERSION = "~4"

    # Add Service Bus connection string
    SERVICEBUS_CONNECTION = data.azurerm_servicebus_namespace_authorization_rule.root.primary_connection_string
  }
}

# VNet Integration (unchanged)
resource "azurerm_app_service_virtual_network_swift_connection" "vnet_integration" {
  app_service_id = azurerm_windows_function_app.func.id
  subnet_id      = azurerm_subnet.subnet.id
}

# Private DNS Zones for Storage services
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "file" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "queue" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone" "table" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# Link DNS zones with the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "blob-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "file" {
  name                  = "file-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.file.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue" {
  name                  = "queue-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.queue.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone_virtual_network_link" "table" {
  name                  = "table-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.table.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Private Endpoints for Storage services
resource "azurerm_private_endpoint" "blob" {
  name                = "pe-blob-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "blobConnection"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

  depends_on = [azurerm_windows_function_app.func]
}

resource "azurerm_private_endpoint" "file" {
  name                = "pe-file-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "fileConnection"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "file-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.file.id]
  }

  depends_on = [azurerm_windows_function_app.func]
}

resource "azurerm_private_endpoint" "queue" {
  name                = "pe-queue-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "queueConnection"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "queue-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.queue.id]
  }

  depends_on = [azurerm_windows_function_app.func]
}

resource "azurerm_private_endpoint" "table" {
  name                = "pe-table-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "tableConnection"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "table-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.table.id]
  }

  depends_on = [azurerm_windows_function_app.func]
}


