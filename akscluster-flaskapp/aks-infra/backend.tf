terraform {
  backend "azurerm" {
    resource_group_name   = "tfstate-rg"
    storage_account_name  = "tfstatestorageaksdemo"
    container_name        = "tfstate"
    key                   = "aks-flask-prod.terraform.tfstate"
  }
}