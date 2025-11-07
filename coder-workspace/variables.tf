variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "cyruscoder"
}

variable "location" {
  description = "The location where resources will be deployed"
  type        = string
  default     = "eastasia"
}

variable "k8s_namespace" {
  description = "Value of namespace that contains coder and its db"
  type        = string
  default     = "coder-ns"
}

variable "file_share_size_gb" {
  description = "Size of the file share in GB"
  type        = number
  default     = 10
}

variable "db_user" {
  description = "User name of postgresql"
  type        = string
  default     = ""
}

variable "db_pwd" {
  description = "Password of postgresql"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_name" {
  description = "Name of DB"
  type        = string  
  default     = "code-db"
}

variable "vm_size" {
  description = "Size of the virtual machine for the AKS node pool"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "tenant_id" {
  default      = ""
  description  = "Azure Tenant ID" 
}

variable "subscription_id" {
  default      = ""
  description  = "Azure Subscription ID" 
}
