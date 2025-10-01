terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
}


# Random suffix
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  numeric = true
  special = false
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-aks-${random_string.suffix.result}"
  location = "East US"
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "aksdemo${random_string.suffix.result}"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Lock for AKS managed node resource group
resource "azurerm_management_lock" "aks_mc_lock" {
  name       = "lock-aks-mc-rg"
  scope      = azurerm_kubernetes_cluster.aks.node_resource_group_id
  lock_level = "CanNotDelete"
  notes      = "This lock prevents accidental deletion of the AKS managed cluster node resource group."
}

# Kubernetes provider config
provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}


# Namespace
resource "kubernetes_namespace" "flask" {
  metadata {
    name = "flask-app"
  }
}

# Flask Deployment with Python 3.11 image
resource "kubernetes_deployment" "flask" {
  metadata {
    name      = "flask-deployment"
    namespace = kubernetes_namespace.flask.metadata[0].name
    labels = {
      app = "flask"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "flask"
      }
    }

    template {
      metadata {
        labels = {
          app = "flask"
        }
      }

      spec {
        container {
          name  = "flask"
          image = "tiangolo/meinheld-gunicorn-flask:python3.9"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# Service (LoadBalancer for public access)
resource "kubernetes_service" "flask" {
  metadata {
    name      = "flask-service"
    namespace = kubernetes_namespace.flask.metadata[0].name
  }

  spec {
    selector = {
      app = "flask"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}