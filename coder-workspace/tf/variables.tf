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

variable "file_share_size_gb" {
  description = "Size of the file share in GB"
  type        = number
  default     = 10
}

variable "vm_size" {
  description = "Size of the virtual machine for the AKS node pool"
  type        = string
  default     = "Standard_DS2_v2"
}