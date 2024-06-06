variable "db_username" {
  default = "widemodbadm"
}

variable "db_password" {
  default = "xxxxxxxxxxxxx"
}

variable "resource_group_name" {
  default = "wi-demo-rg"
}

variable "location" {
  default = "eastasia"
}

variable "acr_name" {
  default = "widemoacr"
}

variable "acr_sku" {
  default = "Basic"
}

variable "aks_name" {
  default = "wi-demo-aks"
}

variable "aks_node_count" {
  default = 1
}

variable "aks_vm_size" {
  default = "Standard_B2s"
}

variable "db_name" {
  default = "wi-demo-db"
}

variable "db_svr_name" {
  default = "wi-demo-db-svr"
}

variable "db_sku" {
  default = "Basic"
}

variable "asb_name" {
  default = "wi-demo-asb"
}

variable "asb_queue_name" {
  default = "testQueue"
}

variable "spn_asb_name" {
  default = "wi-demo-spn-asb"
}

variable "spn_db_name" {
  default = "wi-demo-spn-db"
}