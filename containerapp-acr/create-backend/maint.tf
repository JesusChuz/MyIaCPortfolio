terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.0.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
}

# Resource Group for Terraform state
resource "azurerm_resource_group" "tfstate_rg" {
  name     = "tfstate-rg-contapp"
  location = "Canada Central"
}

# Storage Account for Terraform state
resource "azurerm_storage_account" "tfstate_sa" {
  name                     = "tfstatestoragecontapp"  # Must be globally unique
  resource_group_name      = azurerm_resource_group.tfstate_rg.name
  location                 = azurerm_resource_group.tfstate_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }
}

# Blob Container for Terraform state
resource "azurerm_storage_container" "tfstate_container" {
  name                  = "tfstate-contapp"
  storage_account_name  = azurerm_storage_account.tfstate_sa.name
  container_access_type = "private"
}
