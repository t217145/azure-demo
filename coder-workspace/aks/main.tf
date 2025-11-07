resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.name_prefix}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.name_prefix}-dns"

  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [ 
    azurerm_resource_group.rg
  ]
}

resource "azurerm_storage_account" "storage" {
  name                     = replace(var.name_prefix, "-", "")
  location                 = var.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [ 
    azurerm_resource_group.rg
  ]
}

resource "azurerm_storage_share" "file_share" {
  name                    = "fileshare"
  storage_account_name    = azurerm_storage_account.storage.name
  quota                   = var.file_share_size_gb
  depends_on = [ 
    azurerm_storage_account.storage
  ]
}

resource "azurerm_role_assignment" "aks_to_storage" {
  principal_id          = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name  = "Storage File Data SMB Share Contributor"
  scope                 = azurerm_storage_account.storage.id
  depends_on = [ 
    azurerm_storage_account.storage,
    azurerm_kubernetes_cluster.aks
  ]
}