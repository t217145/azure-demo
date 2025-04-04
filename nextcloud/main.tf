# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}-rg"
  location = var.location
}

# Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = "${var.name_prefix}stg${random_id.storage_suffix.dec}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_id" "storage_suffix" {
  keepers = {
    resource_group_name = azurerm_resource_group.rg.name
  }
  byte_length = 4
}

# File Share
resource "azurerm_storage_share" "file_share" {
  name                 = "${var.name_prefix}files"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = var.storage_size_gb
}

# App Service Plan
resource "azurerm_service_plan" "app_service_plan" {
  name                = "${var.name_prefix}plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# Web App
resource "azurerm_linux_web_app" "web_app" {
  name                = "${var.name_prefix}app${random_id.storage_suffix.dec}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  app_settings = {
    NEXTCLOUD_ADMIN_USER     = var.admin_id
    NEXTCLOUD_ADMIN_PASSWORD = var.admin_pwd
  }  

  site_config {
    application_stack {
      docker_image_name   = "nextcloud:latest"
      docker_registry_url = "https://docker.io"
    }
  }

  storage_account {
    access_key = azurerm_storage_account.storage.primary_access_key
    account_name = azurerm_storage_account.storage.name
    name = azurerm_storage_share.file_share.name
    share_name = azurerm_storage_share.file_share.name
    type = "AzureFiles"
    mount_path = "/var/www/html"
  }
}