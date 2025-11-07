output "coder_service_external_ip" {
  value = data.kubernetes_service.coder.status[0].load_balancer[0].ingress[0].ip
  description = "The external IP address of the Coder service"
}