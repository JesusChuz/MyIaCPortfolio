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

variable "base_rg_name" {
  default = "rg-vm-demo"
}

# =====================
# VM Configuration
# =====================
variable "vm_size" {
  description = "Size of the Linux VM"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "vm_admin_ssh_key_path" {
  default = "D:/ssh/jesus_azure.pub"
}


variable "vm_subnet_prefix" {
  description = "CIDR prefix for VM subnet"
  type        = list(string)
  default     = ["10.0.2.0/24"]
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

resource "azurerm_public_ip" "vm_pip" {
  name                = "pip-vm-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.base_vnet_name}-${random_string.suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "subnet-vm-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.vm_subnet_prefix
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-vm-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-ubuntu22-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = file(var.vm_admin_ssh_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_recovery_services_vault" "vault" {
  name                = "vault-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  soft_delete_enabled = true
}

resource "azurerm_backup_policy_vm" "weekly" {
  name                = "weekly-backup-policy"
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name

  backup {
    frequency = "Weekly"
    time      = "23:00" # UTC time
    weekdays  = ["Sunday"]
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday"]
  }
}

resource "azurerm_backup_protected_vm" "vm_protection" {
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  source_vm_id        = azurerm_linux_virtual_machine.vm.id
  backup_policy_id    = azurerm_backup_policy_vm.weekly.id
}
