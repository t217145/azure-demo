# Coder Workspace (Terraform) — Azure AKS

Abstract
---
This Terraform project provisions an Azure-based Coder workspace on AKS with persistent file storage. It creates the resource group, an AKS cluster, a storage account and Azure File Share, and outputs key values for post-deploy access.

Architecture
---
- Azure Resource Group — container for all resources
- AKS Cluster — Kubernetes control plane to run the Coder service
- Storage Account + Azure File Share — persistent storage mounted into workloads
- Role assignments and networking configured via AKS defaults
- PostgreSQL Database — managed by Helm chart for Coder data persistence
- Coder Application — deployed via Helm chart for developer workspace management

Authentication
---
This project uses OpenID Connect (OIDC) for Azure authentication in production environments. OIDC enables secure, token-based authentication between GitHub Actions and Azure without storing credentials.

OIDC Setup Requirements:
1. Configure Azure AD application with appropriate permissions
2. Set up GitHub Actions OIDC provider in Azure AD
3. Configure GitHub repository with required Azure OIDC settings:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

For local development:
- Comment out `use_oidc = true` and use Azure CLI authentication
- Run `az login` before running Terraform commands
- Ensure you have the necessary Azure role assignments

For production deployments:
- Keep `use_oidc = true` enabled
- Use GitHub Actions workflow with OIDC authentication
- Store sensitive values in GitHub Secrets

Terraform components
---
Primary Terraform resources are defined in `azure-demo/coder-workspace/tf/main.tf`:

Azure Resources:
- `azurerm_resource_group.rg` — root resource group
- `azurerm_kubernetes_cluster.aks` — AKS cluster used to host Coder
- `azurerm_storage_account.storage` — storage account for files
- `azurerm_storage_share.file_share` — Azure Files share mounted by pods
- `azurerm_role_assignment.aks_to_storage` — RBAC for AKS to access storage

Kubernetes Resources:
- `kubernetes_namespace.coder_ns` — namespace for Coder deployment
- `kubernetes_secret.coder_db_url` — secret containing database connection string

Helm Releases:
- `helm_release.coder_db` — PostgreSQL database deployment
- `helm_release.coder` — Coder application deployment

Provider and requirements
---
The following providers are configured in `azure-demo/coder-workspace/tf/providers.tf`:

- `azurerm` (>= 3.75.0) — Azure Resource Manager provider for Azure resources
- `kubernetes` (>= 2.23.0) — Provider for Kubernetes resources
- `helm` (>= 2.11.0) — Provider for Helm chart deployments

Inputs / Variables
---
See [`azure-demo/coder-workspace/tf/variables.tf`](azure-demo/coder-workspace/tf/variables.tf) for the configurable inputs:

Infrastructure variables:
- `name_prefix` (string) - Default: `cyruscoder` - Prefix used for all Azure resource names
- `location` (string) - Default: `eastasia` - Azure region to deploy resources
- `vm_size` (string) - Default: `Standard_DS2_v2` - VM size for AKS node pool
- `file_share_size_gb` (number) - Default: `10` - Size in GB for Azure File Share

Kubernetes/Namespace variables:
- `k8s_namespace` (string) - Default: `coder` - Kubernetes namespace for Coder deployment

Database variables:
- `db_helm_name` (string) - Default: `coder-db` - Helm release name for PostgreSQL
- `db_name` (string) - Default: `coder` - PostgreSQL database name
- `db_user` (string) - Default: `coder` - PostgreSQL username
- `db_pwd` (string) - Default: `coder` - PostgreSQL password (should be changed in production)

Each variable can be overridden by:
- Setting environment variables (TF_VAR_variable_name)
- Using -var flag in terraform command
- Creating a terraform.tfvars file

Outputs
---
The project publishes outputs in [`azure-demo/coder-workspace/tf/outputs.tf`](azure-demo/coder-workspace/tf/outputs.tf):

- `aks_name` — name of the AKS cluster (`azurerm_kubernetes_cluster.aks`).
- `rg_name` — name of the resource group (`azurerm_resource_group.rg`).

How to deploy
---
1. Change defaults in [`azure-demo/coder-workspace/tf/variables.tf`](azure-demo/coder-workspace/tf/variables.tf) as needed.
2. From the `azure-demo/coder-workspace/tf` directory run:
   - `terraform init`
   - `terraform plan -out main.tfplan`
   - `terraform apply main.tfplan`
3. After apply, get outputs:
   - `terraform output --raw aks_name`
   - `terraform output --raw rg_name`

Clean up
---
After testing, to clean up the resources, execute following:
1. From the `azure-demo/coder-workspace/tf` directory run:
   - `terraform apply -destroy -auto-approve`

Relevant files
---
- [`azure-demo/coder-workspace/tf/main.tf`](azure-demo/coder-workspace/tf/main.tf) — main resources (AKS, storage, file share, etc.)
- [`azure-demo/coder-workspace/tf/providers.tf`](azure-demo/coder-workspace/tf/providers.tf) — provider & required versions
- [`azure-demo/coder-workspace/tf/variables.tf`](azure-demo/coder-workspace/tf/variables.tf) — variables and defaults
- [`azure-demo/coder-workspace/tf/outputs.tf`](azure-demo/coder-workspace/tf/outputs.tf) — outputs

Author
---
Created by Cyrus Cheng
- GitHub: [github.com/t217145](https://github.com/t217145)
- Project Repository: [azure-demo/coder-workspace](https://github.com/t217145/azure-demo/tree/main/coder-workspace)