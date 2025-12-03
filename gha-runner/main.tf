resource "kubernetes_namespace" "gha_runner_ns" {
  metadata {
    name = local.namespace
  }
}

resource "helm_release" "gha_runner_controller" {
  name       = local.gha_runner_controller_name
  namespace  = kubernetes_namespace.gha_runner_ns.metadata[0].name
  repository = local.gha_runner_repository
  chart      = "gha-runner-scale-set-controller"
  version    = "0.12.1"

  values = [
    yamlencode({
      replicaCount = 1
      image = {
        repository = "ghcr.io/actions/gha-runner-scale-set-controller"
        pullPolicy = "IfNotPresent"
        tag        = "canary"
      }
      namespaceOverride = local.namespace
      serviceAccount = {
        create = true
        name   = "${local.gha_runner_controller_name}-gha-rs-controller"
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.gha_runner_ns,
    null_resource.remove_all_finalizers_dynamic
  ]

  wait    = true
  timeout = 600
}

resource "helm_release" "gha_runner_scale_set" {
  name       = local.gha_runner_scale_set_name
  repository = local.gha_runner_repository
  chart      = "gha-runner-scale-set"
  version    = "0.12.1"
  namespace  = kubernetes_namespace.gha_runner_ns.metadata[0].name
  values = [
    yamlencode({
      githubConfigUrl = var.github_config_url
      githubConfigSecret = {
        github_app_id              = var.github_app_id
        github_app_installation_id = var.github_app_installation_id
        github_app_private_key     = var.github_app_private_key
      }
      maxRunners         = 1
      minRunners         = 1
      runnerGroup        = var.runner_group
      runnerScaleSetName = var.runner_scaleset_name
      template = {
        spec = {
          containers = [{
            name    = "runner"
            image   = "ghcr.io/actions/actions-runner:latest"
            command = ["/home/runner/run.sh"]
          }]
        }
      }
      namespaceOverride = local.namespace
      controllerServiceAccount = {
        namespace = local.namespace
        name      = "${local.gha_runner_controller_name}-gha-rs-controller"
      }
    })
  ]

  depends_on = [
    helm_release.gha_runner_controller,
    kubernetes_namespace.gha_runner_ns,
    null_resource.remove_all_finalizers_dynamic
  ]
}

resource "null_resource" "remove_all_finalizers_dynamic" {
  provisioner "local-exec" {
    interpreter = ["bash", "-c"]
    when    = destroy
    command = <<EOT
      sleep 20  # Wait for Helm to delete the resources

      for kind in $(kubectl api-resources --namespaced=true -o name); do
        for name in $(kubectl get $kind -n "gha-demo-ns" -o jsonpath="{.items[*].metadata.name}" 2>/dev/null); do
          echo "Attempting to remove finalizer from $kind/$name"
          kubectl patch $kind $name \
            -n "gha-demo-ns" \
            --type=json \
            -p='[{"op": "remove", "path": "/metadata/finalizers"}]' \
            2>/dev/null || echo "No finalizer or patch failed for $kind/$name"
        done
      done

      for name in $(kubectl get autoscalingrunnerset.actions.github.com -n "gha-demo-ns" -o jsonpath="{.items[*].metadata.name}" 2>/dev/null); do
        kubectl patch autoscalingrunnerset.actions.github.com $name \
          -n "gha-demo-ns" \
          --type=json \
          -p='[{"op": "remove", "path": "/metadata/finalizers"}]' \
          2>/dev/null || echo "No finalizer or patch failed for AutoscalingRunnerSet/$name"
      done

      # Explicitly handle EphemeralRunner CR
      for name in $(kubectl get ephemeralrunner.actions.github.com -n "gha-demo-ns" -o jsonpath="{.items[*].metadata.name}" 2>/dev/null); do
        kubectl patch ephemeralrunner.actions.github.com $name \
          -n "gha-demo-ns" \
          --type=json \
          -p='[{"op": "remove", "path": "/metadata/finalizers"}]' \
          2>/dev/null || echo "No finalizer or patch failed for EphemeralRunner/$name"
      done

      # Explicitly handle EphemeralRunnerSet CR
      for name in $(kubectl get ephemeralrunnerset.actions.github.com -n "gha-demo-ns" -o jsonpath="{.items[*].metadata.name}" 2>/dev/null); do
        kubectl patch ephemeralrunnerset.actions.github.com $name \
          -n "gha-demo-ns" \
          --type=json \
          -p='[{"op": "remove", "path": "/metadata/finalizers"}]' \
          2>/dev/null || echo "No finalizer or patch failed for EphemeralRunnerSet/$name"
      done
    EOT
  }
}