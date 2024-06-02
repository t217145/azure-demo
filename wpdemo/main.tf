resource "azurerm_resource_group" "wpdemorg" {
  name     = var.webapp_name
  location = var.webapp_location
}

resource "azurerm_service_plan" "wpdemoplan" {
  name                = "${var.webapp_name}plan"
  resource_group_name = azurerm_resource_group.wpdemorg.name
  location            = azurerm_resource_group.wpdemorg.location
  os_type             = "Linux"
  sku_name            = var.sku
}

resource "azurerm_app_service" "wpdemo" {
  name                  = "${var.webapp_name}-${var.webapp_suffix}"
  resource_group_name   = azurerm_resource_group.wpdemorg.name
  location              = azurerm_service_plan.wpdemoplan.location
  app_service_plan_id   = azurerm_service_plan.wpdemoplan.id

  site_config {
    linux_fx_version = "COMPOSE|${base64encode(file("./docker-compose.yml"))}"
  }
}