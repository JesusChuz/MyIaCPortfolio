subscription_id = "8412747f-ace3-4b85-8ef7-4e8c0eab877d"
//backend
resource_groupname = "tfstatestoragecontapp"
location_name = "Canada Central"
storage_name = "tfstatestoragecontapp"
storage_tier = "Standard"
storage_replication_type = "LRS"
storagecontainer_name = "tfstate-contapp"
storage_container_access_type = "private"

//containerapp variables
containerapprg_name = "rg-containerapp-demo"
containerappenv_name = "cae-demo-env"
containerapp_name = "demoapp"
container_name = "demo-container"
container_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"

