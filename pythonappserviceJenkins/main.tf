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

# Random suffix for uniqueness
resource "random_string" "rg_suffix" {
  length  = 4
  upper   = false
  numeric = true
  special = false
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-appservice-${random_string.rg_suffix.result}"
  location = "Canada Central"
}

# App Service Plan (Linux, Basic tier)
resource "azurerm_service_plan" "asp" {
  name                = "asp-linux-${random_string.rg_suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "S1"
}

# Web App (Linux, Python 3.11)
resource "azurerm_linux_web_app" "app" {
  name                = "webapp-${random_string.rg_suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    always_on = true

    application_stack {
      python_version = "3.11"
    }
  }
}

# Deployment Slot (Staging, Python 3.11)
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.app.id

  site_config {
    always_on = true

    application_stack {
      python_version = "3.11"
    }
  }
}
