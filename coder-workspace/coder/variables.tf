variable "tf_org" {
  description = "Organization name of your AKS workspace"
  type        = string
  default     = ""
} 

variable "tfc_aks_workspace_name" {
  description = "TFC workspace name of the AKS"
  type        = string
  default     = ""
}

variable "k8s_namespace" {
  description = "Value of namespace that contains coder and its db"
  type        = string
  default     = "coder-ns"
}

variable "db_user" {
  description = "User name of Postgresql"
  type        = string
  default     = ""
}

variable "db_pwd" {
  description = "Password of Postgresql"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_name" {
  description = "Name of DB"
  type        = string  
  default     = "code-db"
}

variable "tenant_id" {
  default      = ""
  description  = "Azure Tenant ID" 
}

variable "subscription_id" {
  default      = ""
  description  = "Azure Subscription ID" 
}
