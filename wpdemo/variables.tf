variable "sku" {
  default     = "B1"
  description = "Price tier of the web app server"
}

variable "webapp_suffix" {
  default     = "cyrus"
  description = "The Web app name"
}

variable "webapp_name" {
  default     = "wpdemo"
  description = "The Web app name"
}

variable "webapp_location" {
  default     = "East Asia"
  description = "Location of the web app"
}