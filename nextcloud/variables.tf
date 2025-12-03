# Variables
variable "admin_id" {
  description = "NextCloud admin username"
  type        = string
  default     = ""
}

variable "admin_pwd" {
  description = "NextCloud admin password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "name_prefix" {
  default     = "ncdrive"
  description = "Resource group name"
}

variable "location" {
  default     = "eastasia"
  description = "Azure region"
}

variable "storage_size_gb" {
  default     = 10
  description = "File share quota size in GB"
}

variable "price_tier" {
  default     = "B1"
  description = "App Service Plan pricing tier, e.g. B1, P0v4"
}

variable "tenant_id" {
  default      = ""
  description  = "Azure Tenant ID" 
}

variable "subscription_id" {
  default      = ""
  description  = "Azure Subscription ID" 
}
