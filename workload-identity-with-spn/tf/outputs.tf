output "tenant_id" {
  value = azuread_service_principal.spn_asb.application_tenant_id
}

output "spn_asb_client_id" {
  value = azuread_service_principal.spn_asb.client_id
}

output "spn_db_client_id" {
  value = azuread_service_principal.spn_db.client_id
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_admin_username" {
  value = azurerm_container_registry.acr.admin_username
}

output "acr_admin_password" {
  value = azurerm_container_registry.acr.admin_password
  sensitive = true
}

output "spn_asb_name" {
  value = var.spn_asb_name
}

output "spn_db_name" {
  value = var.spn_db_name
}

output "db_username" {
  value = var.db_username
}

output "db_password" {
  value = var.db_password
}

output "acr_name"{
  value = azurerm_container_registry.acr.name
}

output "rg_name"{
  value = var.resource_group_name
}

output "asb_name"{
  value = var.asb_name
}

output "db_svr_name"{
  value = var.db_svr_name
}

output "db_name"{
  value = var.db_name
}

output "asb_queue_name" {
  value = var.asb_queue_name
}