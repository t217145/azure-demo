output "namespace" {
  description = "The Kubernetes namespace for the GitHub Actions runner"
  value       = kubernetes_namespace.gha_runner_ns.metadata[0].name
}

output "gha_runner_controller_release" {
  description = "Helm release name for the GHA runner controller"
  value       = helm_release.gha_runner_controller.name
}

output "gha_runner_scale_set_release" {
  description = "Helm release name for the GHA runner scale set"
  value       = helm_release.gha_runner_scale_set.name
}

output "runner_scale_set_name" {
  description = "Name of the GitHub Actions runner scale set"
  value       = var.runner_scaleset_name
}