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
  sku_name            = "Y1"
}

# Function App (Windows)
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
  }  
}
