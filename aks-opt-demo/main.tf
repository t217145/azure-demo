terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aks-demo-rg" {
  name     = "aks-demo"
  location = "East Asia"
}

resource "azurerm_kubernetes_cluster" "aks-demo" {
  name                = "aks-demo"
  location            = azurerm_resource_group.aks-demo-rg.location
  resource_group_name = azurerm_resource_group.aks-demo-rg.name
  dns_prefix          = "aks-demo"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2ds_v4"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "aks-demo-pool-general" {
  name                  = "general"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-demo.id
  vm_size    = "Standard_D2ds_v4"
  node_count            = 1
  node_labels			= {
	  "nodeType" = "general"
  }
  mode = "User"
  enable_auto_scaling = true
  max_count = 10    
}

resource "azurerm_kubernetes_cluster_node_pool" "aks-demo-pool-compute" {
  name                  = "compute"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-demo.id
  vm_size    = "Standard_F2s_v2"
  node_count            = 1
  node_labels			= {
	  "nodeType" = "compute"
  }
  mode = "User"
  enable_auto_scaling = true
  max_count = 10
}

resource "azurerm_kubernetes_cluster_node_pool" "aks-demo-pool-memory" {
  name                  = "memory"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-demo.id
  vm_size    = "Standard_E2as_v4"
  node_count            = 1
  node_labels			= {
	  "nodeType" = "memory"
  }
  mode = "User"
  enable_auto_scaling = true
  max_count = 10
}