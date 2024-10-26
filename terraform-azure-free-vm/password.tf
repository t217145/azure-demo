resource "random_password" "password" {
  length           = 10
  special          = true
  override_special = "_%@"
}

output "shadowsocks_pwd" {
  value = random_password.password.result
}
