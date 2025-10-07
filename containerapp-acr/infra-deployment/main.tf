terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.0.0"
    }
  }
}

variable "subscription_id" {
  description = "My subscription id"
  type        = string
}

provider "azurerm" {
  features {}
  subscription_id = "${var.subscription_id}"
}
# -------------------------------
# Resource Group
# -------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-containerapp-demo"
  location = "East US"
}

# -------------------------------
# Container App Environment
# -------------------------------
resource "azurerm_container_app_environment" "env" {
  name                = "cae-demo-env"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# -------------------------------
# Container App
# -------------------------------
resource "azurerm_container_app" "app" {
  name                         = "demoapp"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  template {
    container {
      name   = "demo-container"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true # exposes a public endpoint
    target_port      = 80
    transport        = "auto"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
