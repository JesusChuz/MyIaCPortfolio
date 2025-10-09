terraform { 
  backend "azurerm" {
    resource_group_name   = "tfstatestoragecontapp"
    storage_account_name  = "tfstatestoragecontapp"
    container_name        = "tfstate-contapp"
    key                   = "aks-flask-prod.terraform.tfstate"
  }
}
