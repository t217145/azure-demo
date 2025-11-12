variable "github_app_id" {
  description = "GitHub Actions App Id"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub Actions App Installation Id"
  type        = string
  sensitive   = true
}

variable "github_app_private_key" {
  description = "GitHub Actions App Private Key"
  type        = string
  sensitive   = true
}

variable "runner_group" {
  description = "GitHub Actions runner group"
  type        = string
  default     = ""
}

variable "runner_scaleset_name" {
  description = "GitHub Actions runner scale set name"
  type        = string
}

variable "github_config_url" {
  description = "URL of the GitHub repository or organization"
  type        = string
  default     = ""
}

variable "subscription_id" {
  description = "The Azure Subscription ID where the AKS cluster is located."
  type        = string
}

variable "tenant_id" {
  description = "The Azure Tenant ID where the AKS cluster is located."
  type        = string  
}

variable "aks_cluster_name" {
  description = "AKS Cluster name"
  type        = string
}

variable "aks_resource_group" {
  description = "AKS Cluster Resource Group name"
  type        = string
}