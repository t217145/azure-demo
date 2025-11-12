locals {
  namespace                  = "gha-demo-ns"
  gha_runner_scale_set_name  = "gha-runner-scale-set"
  gha_runner_controller_name = "gha-runner-scale-set-ctr"
  gha_runner_repository      = "oci://ghcr.io/actions/actions-runner-controller-charts"
}