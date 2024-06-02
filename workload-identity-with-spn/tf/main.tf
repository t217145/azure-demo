data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.acr_sku
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  dns_prefix          = var.aks_name

  default_node_pool {
    name       = "default"
    node_count = var.aks_node_count
    vm_size    = var.aks_vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}

resource "azurerm_mssql_server" "db" {
  name                         = var.db_svr_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db_username
  administrator_login_password = var.db_password
}

resource "azurerm_mssql_firewall_rule" "dbfw" {
  name                = "AllowAll"
  server_id           = azurerm_mssql_server.db.id
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "255.255.255.255"
}

resource "azurerm_mssql_database" "db" {
  name           = var.db_name
  server_id      = azurerm_mssql_server.db.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  read_scale     = false
  geo_backup_enabled = false
  storage_account_type = "Local"
  sku_name       = var.db_sku
}

resource "azurerm_servicebus_namespace" "asb" {
  name                = var.asb_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  local_auth_enabled  = false
}

resource "azurerm_servicebus_queue" "testQueue" {
  name         = var.asb_queue_name
  namespace_id = azurerm_servicebus_namespace.asb.id
}

resource "azuread_application" "spn_asb_app" {
  display_name = var.spn_asb_name
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "spn_asb" {
  client_id                    = azuread_application.spn_asb_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_application" "spn_db_app" {
  display_name = var.spn_db_name
  owners       = [data.azurerm_client_config.current.object_id]
}

resource "azuread_service_principal" "spn_db" {
  client_id                    = azuread_application.spn_db_app.client_id
  app_role_assignment_required = false
  owners                       = [data.azurerm_client_config.current.object_id]
}

resource "azurerm_role_assignment" "asb_role_assignment" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_resource_group.rg.name}/providers/Microsoft.ServiceBus/namespaces/${azurerm_servicebus_namespace.asb.name}"
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azuread_service_principal.spn_asb.object_id
}

resource "azurerm_role_assignment" "acr_role" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

resource "null_resource" "enable_workload_identity" {
  depends_on = [azurerm_kubernetes_cluster.aks]
  provisioner "local-exec" {
    command = <<-EOT
      az aks update --resource-group ${azurerm_resource_group.rg.name} --name ${var.aks_name} --enable-oidc-issuer --enable-workload-identity
    EOT
  }
}