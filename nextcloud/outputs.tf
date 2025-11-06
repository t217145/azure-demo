output "nextcloud_url" {
  value = "https://${azurerm_linux_web_app.web_app.default_hostname}"
  description = "URL of the NextCloud instance"
}

output "admin_credentials" {
  value = "Username: ${var.admin_id}, Password: ${var.admin_pwd}"
  description = "Default admin credentials for NextCloud"
  sensitive = true
}
