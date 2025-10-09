terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.0.0"
    }
  }
  required_version = ">= 1.3.0"
}

variable "subscription_id" {
  description = "My subscription id"
  type        = string
}
variable "location_name" {
  description = "The region"
  type        = string
}
variable "resource_groupname"{
  description = "The resource group name"
  type        = string
}
variable "storage_name"{
  description = "The name of the storage account"
  type        = string
}
variable "storage_tier"{
  description = "The tier for the storage account"
  type        = string
}
variable "storage_replication_type"{
  description = "The replication type for the storage account"
  type        = string
}
variable "storagecontainer_name"{
  description = "The storage container name"
  type        = string
}
variable "storage_container_access_type"{
  description = "The access type for the storage container"
  type        = string
}

provider "azurerm" {
  features {}
  subscription_id = "${var.subscription_id}"
}

# Resource Group for Terraform state
resource "azurerm_resource_group" "tfstate_rg" {
  name     = var.resource_groupname
  location = var.location_name
}

# Storage Account for Terraform state
resource "azurerm_storage_account" "tfstate_sa" {
  name                     = var.storage_name  # Must be globally unique
  resource_group_name      = azurerm_resource_group.tfstate_rg.name
  location                 = azurerm_resource_group.tfstate_rg.location
  account_tier             = var.storage_tier
  account_replication_type = var.storage_replication_type

  blob_properties {
    versioning_enabled = true
  }
}

# Blob Container for Terraform state
resource "azurerm_storage_container" "tfstate_container" {
  name                  = var.storagecontainer_name
  storage_account_name  = azurerm_storage_account.tfstate_sa.name
  container_access_type = var.storage_container_access_type
}
