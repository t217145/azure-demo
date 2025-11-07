# Coder Workspace (Terraform) — Azure AKS

Abstract
---
This repository contains a two-workspace Terraform project that provisions infrastructure on Azure and deploys the Coder workspace into a Kubernetes cluster.

- Workspace 1 (aks): creates Azure resources — Resource Group, AKS cluster, Storage Account and Azure File Share (infrastructure).
- Workspace 2 (coder): deploys Coder and its dependencies (PostgreSQL via Helm) into the Kubernetes cluster created by workspace 1.

Architecture
---
- Azure Resource Group — container for the resources.
- AKS Cluster — Kubernetes control plane running Coder.
- Storage Account + Azure File Share — persistent storage for developer workspaces.
- PostgreSQL — deployed in-cluster via Helm (Bitnami/other chart).
- Coder — deployed as a Helm release in a dedicated Kubernetes namespace.
- Kubernetes Secret — holds the DB connection string consumed by Coder.
- Two Terraform workspaces: `aks` (infra) and `coder` (app).

Providers and authentication
---
Providers used (defined in tf/providers.tf under each workspace):
- azurerm — Azure Resource Manager (>= 3.75.0)
- kubernetes — Kubernetes provider (>= 2.23.0)
- helm — Helm provider for chart releases (>= 2.11.0)

Authentication notes:
- Production: use OIDC for azurerm (provider "azurerm" with use_oidc = true). This is the recommended secure approach for GitHub Actions / CI.
- Local/testing: you may comment out use_oidc and authenticate locally with `az login` or service principal credentials.
- The `coder` workspace references the AKS outputs/credentials (via Terraform Cloud workspace outputs or remote state).

Terraform components (high level)
---
- Azure resources (aks workspace):
  - azurerm_resource_group
  - azurerm_kubernetes_cluster (AKS)
  - azurerm_storage_account
  - azurerm_storage_share (Azure Files)
  - role assignment(s) for AKS to access storage
- Kubernetes resources (coder workspace):
  - kubernetes_namespace (e.g., coder-ns)
  - kubernetes_secret (DB connection string)
- Helm releases (coder workspace):
  - helm_release for PostgreSQL (coder-db)
  - helm_release for Coder (coder)

Two-workspace flow
---
1. Deploy aks workspace first. It provisions AKS and storage and exposes outputs (AKS kubeconfig, cluster name, storage resource info).
2. Configure remote state or Terraform Cloud outputs so the coder workspace can consume AKS kubeconfig/connection info.
3. Deploy coder workspace which uses the Kubernetes and Helm providers to install the DB, create the secret and install the Coder Helm chart.

Inputs / Variables
---
Below are variables present in each workspace (copied from the two variables.tf files):

aks workspace (d:\Workspace\GitHub\azure-demo\coder-workspace\tf\aks\variables.tf)
- name_prefix (string) — Prefix for resource names — default: ""
- location (string) — Azure region — default: "eastasia"
- file_share_size_gb (number) — Azure File Share quota in GB — default: 10
- vm_size (string) — AKS node VM size — default: "Standard_DS2_v2"
- tenant_id (string) — Azure Tenant ID — default: ""
- subscription_id (string) — Azure Subscription ID — default: ""

coder workspace (d:\Workspace\GitHub\azure-demo\coder-workspace\tf\coder\variables.tf)
- tf_org (string) — Terraform Cloud org name (if used) — default: ""
- tfc_aks_workspace_name (string) — TFC workspace name of the AKS workspace (for fetching outputs) — default: ""
- k8s_namespace (string) — Namespace containing Coder and DB — default: "coder-ns"
- db_user (string) — PostgreSQL username — default: ""
- db_pwd (string, sensitive) — PostgreSQL password — default: ""
- db_name (string) — Database name — default: "code-db"
- tenant_id (string) — Azure Tenant ID — default: ""
- subscription_id (string) — Azure Subscription ID — default: ""

Notes about variables
- Sensitive values (e.g., db_pwd) should be provided via secure means (Terraform Cloud variables, environment variables TF_VAR_*, or terraform.tfvars kept out of VCS).
- The coder workspace expects access to the AKS credentials/outputs — typical patterns: Terraform Cloud workspace data sources, remote state, or manually provide kubeconfig.

Deploy (high-level)
---
1. Deploy aks workspace:
   - cd tf/aks
   - terraform init
   - terraform plan -out aks.plan
   - terraform apply aks.plan
   - Capture outputs (kubeconfig / cluster name / storage info) or make them available via remote state/Terraform Cloud.
2. Deploy coder workspace:
   - cd tf/coder
   - Set required variables (db credentials, link to AKS outputs or provide kubeconfig)
   - terraform init
   - terraform plan -out coder.plan
   - terraform apply coder.plan

Cleanup
---
- Destroy coder resources first, then the aks/infrastructure workspace.
- Example:
  - cd tf/coder; terraform destroy
  - cd ../aks; terraform destroy

Author
---
Created by Cyrus Cheng  
GitHub: https://github.com/t217145