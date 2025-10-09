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
variable "location_name" {
  description = "The region"
  type        = string
}
variable "containerapprg_name"{
  description = "The resource group name"
  type        = string
}
variable "containerappenv_name" {
  description = "My container app environment"
  type        = string
}
variable "containerapp_name" {
  description = "My container app name"
  type        = string
}
variable "container_name" {
  description = "My container name"
  type        = string
}
variable "container_image" {
  description = "My image name"
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
  name     = var.containerapprg_name
  location = var.location_name
}

# -------------------------------
# Container App Environment
# -------------------------------
resource "azurerm_container_app_environment" "env" {
  name                = var.containerappenv_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# -------------------------------
# Container App
# -------------------------------
resource "azurerm_container_app" "app" {
  name                         = var.containerapp_name
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  template {
    container {
      name   = var.container_name
      image  = var.container_image
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
