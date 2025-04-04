# Variables
variable "admin_id" {
  description = "NextCloud admin username"
  type        = string
  default     = "admin"
}

variable "admin_pwd" {
  description = "NextCloud admin password"
  type        = string
  default     = "password"
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