terraform {
  backend "azurerm" {
    resource_group_name   = "tfstate-rg-contapp"
    storage_account_name  = "tfstatestoragecontapp"
    container_name        = "tfstate-contapp"
    key                   = "aks-flask-prod.terraform.tfstate"
  }
}