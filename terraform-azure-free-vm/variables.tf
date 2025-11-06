variable "resource_group_location" {
  default     = "japaneast"
  description = "Location of the resource group."
}

variable "vpn_port_number" {
  default     = "12345"
  description = "VPN Port Number"
}

variable "vpn_web_port_number" {
  default = "12346"
  description = "VPN Web Port Number"
}

variable "admin_name" {
  default     = "cyrus"
  description = "User name to login to the VM"
}

variable "admin_password" {
  default     = "Password1234!"
  description = "Password to login to the VM"
}

variable "shadowsocks_port" {
  default     = "18388"
  description = "ShadowSocks Port Number"
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}
