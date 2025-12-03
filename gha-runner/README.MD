# GitHub Actions Runner (Terraform) — Azure AKS

Abstract
---
This repository contains a Terraform project that deploys GitHub Actions runners into a Kubernetes cluster running on Azure AKS using the Actions Runner Controller (ARC) with auto-scaling capabilities.

- Deploys GitHub Actions Runner Scale Set Controller — manages the lifecycle and auto-scaling of runners.
- Deploys GitHub Actions Runner Scale Set — creates dynamically scaled runner pods on the AKS cluster.

Architecture
---
- Azure AKS Cluster — existing Kubernetes cluster hosting the GitHub Actions runners.
- GitHub Actions Runner Scale Set Controller — deployed via Helm to manage runner lifecycle and scaling.
- GitHub Actions Runner Scale Set — deployed via Helm with dynamic scaling based on job queue.
- Kubernetes Namespace — dedicated namespace (`gha-demo-ns`) for all runner resources.
- GitHub App Authentication — uses GitHub App credentials for runner registration and management.
- Ephemeral Runners — temporary runner pods that scale up/down based on workflow demand.

Providers and authentication
---
Providers used (defined in providers.tf):
- azurerm — Azure Resource Manager (>= 4.0)
- kubernetes — Kubernetes provider (>= 2.30)
- helm — Helm provider for chart releases (>= 2.13)

Authentication notes:
- Production: use OIDC for azurerm (provider "azurerm" with use_oidc = true). This is the recommended secure approach for GitHub Actions / CI.
- Local/testing: you may comment out use_oidc and authenticate locally with `az login` or service principal credentials.
- Kubernetes and Helm providers authenticate using the AKS cluster credentials retrieved via data source from azurerm_kubernetes_cluster.

Terraform components (high level)
---
- Azure resources (data sources):
  - azurerm_kubernetes_cluster — reference to existing AKS cluster for provider configuration.
- Kubernetes resources:
  - kubernetes_namespace — dedicated namespace for runner resources (gha-demo-ns).
- Helm releases:
  - helm_release for GHA Runner Scale Set Controller — manages runner lifecycle.
  - helm_release for GHA Runner Scale Set — creates and scales runner pods.
- Cleanup resources:
  - null_resource with local-exec provisioner — removes finalizers during destruction to handle stuck resources.

Single-workspace flow
---
1. Ensure an AKS cluster exists and provide its name and resource group.
2. Create a GitHub App with appropriate permissions for runner management (see GitHub documentation on Actions Runner Controller).
3. Configure Terraform variables with GitHub App credentials, runner configuration, and AKS details.
4. Run terraform init, terraform plan, and terraform apply.
5. Runners will automatically register with your GitHub organization/repository and scale based on workflow demand.

Inputs / Variables
---
Below are variables present in this Terraform configuration (from variables.tf):

- github_app_id (string, sensitive) — GitHub Actions App ID — default: ""
- github_app_installation_id (string, sensitive) — GitHub Actions App Installation ID — default: ""
- github_app_private_key (string, sensitive) — GitHub Actions App Private Key — default: ""
- runner_group (string) — GitHub Actions runner group — default: ""
- runner_scaleset_name (string) — GitHub Actions runner scale set name — default: ""
- github_config_url (string) — URL of the GitHub repository or organization — default: ""
- subscription_id (string) — The Azure Subscription ID where the AKS cluster is located — default: ""
- tenant_id (string) — The Azure Tenant ID where the AKS cluster is located — default: ""
- aks_cluster_name (string) — AKS Cluster name — default: ""
- aks_resource_group (string) — AKS Cluster Resource Group name — default: ""

Notes about variables
- Sensitive values (github_app_id, github_app_installation_id, github_app_private_key) should be provided via secure means (Terraform Cloud variables, environment variables TF_VAR_*, or terraform.tfvars kept out of VCS).
- The runner_scaleset_name must be unique within your GitHub organization.
- github_config_url should be in the format: https://github.com/{org} or https://github.com/{org}/{repo}.
- Ensure the AKS cluster exists and is accessible before applying this Terraform configuration.

Deploy (high-level)
---
1. Prepare prerequisites:
   - Ensure an AKS cluster exists in your Azure subscription.
   - Create a GitHub App with appropriate permissions (see GitHub documentation).
   - Generate and securely store the GitHub App credentials (ID, Installation ID, Private Key).
2. Configure variables:
   - Create a terraform.tfvars file or set environment variables (TF_VAR_*) with your values.
   - Example:
     ```
     github_app_id              = "your-app-id"
     github_app_installation_id = "your-installation-id"
     github_app_private_key     = "your-private-key"
     runner_scaleset_name       = "my-runner-scale-set"
     github_config_url          = "https://github.com/your-org"
     subscription_id            = "your-subscription-id"
     tenant_id                  = "your-tenant-id"
     aks_cluster_name           = "my-aks-cluster"
     aks_resource_group         = "my-resource-group"
     ```
3. Deploy:
   - terraform init
   - terraform plan -out gha.plan
   - terraform apply gha.plan
4. Verify:
   - Check that the controller and runner scale set pods are running: `kubectl get pods -n gha-demo-ns`
   - Verify runners appear in your GitHub repository/organization settings.

Cleanup
---
- Run terraform destroy to remove all resources.
- Note: The null_resource provisioner will automatically attempt to remove Kubernetes finalizers to prevent stuck resources during deletion.
- Example:
  - terraform destroy

Author
---
Created by Cyrus Cheng  
GitHub: https://github.com/t217145
