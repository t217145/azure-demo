## gha-runner

## Abstract

This Terraform project deploys GitHub Actions self-hosted runners into an Azure Kubernetes Service (AKS) cluster by installing and managing self-hosted GitHub Actions Runner Helm charts. Self-hosted runners let you run GitHub Actions jobs on infrastructure you control (for example AKS), giving you control over CPU/memory, available tools, network access and cost model. See GitHub's official overview: https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners

Key components involved in a Kubernetes-based self-hosted runner solution:
- Namespace: isolates runner controller and runner pods inside the cluster.
- Controller: the Kubernetes controller (e.g. actions-runner-controller) watches custom resources and creates runner pods.
- Custom Resource Definitions (CRDs): CRDs such as Runner, RunnerDeployment, RunnerReplicaSet, HorizontalRunnerAutoscaler (names differ by controller) let you declare the desired runner fleet in Kubernetes YAML.
- Runner pods / scaleset: the actual workloads that register with GitHub and run jobs. Controllers will create/delete pods according to CRD declarations and autoscalers.

Authentication for runners in this project is implemented using a GitHub App. A GitHub App provides the App ID, Installation ID and a private key which the controller uses to authenticate and register ephemeral runner pods with GitHub. See GitHub's guide on creating a GitHub App for details and how to obtain App ID / installation and private key: https://docs.github.com/en/developers/apps/building-github-apps/creating-a-github-app

Null resource function
- This project includes a Terraform "null_resource" that runs during destroy to remove finalizers from the runner-related CRDs. The Helm chart authors add finalizers to CRDs to protect accidental deletion; however, when Terraform manages the Helm release, CRD finalizers can block a clean destroy because Helm/Terraform cannot remove CRDs while finalizers remain. The null resource executes an idempotent patch (kubectl or equivalent) on destroy to remove those finalizers so Terraform can destroy the chart and CRDs cleanly. In short: the null_resource performs cleanup on destroy to avoid finalizer-blocked deletions.

## Terraform project structure

Files in this folder (high level):
- `providers.tf` - configures Terraform providers used to deploy into Azure and the Kubernetes/Helm providers. Note: to run locally comment/uncomment `use_oidc` as needed.
- `main.tf` / `values.yaml` / other TF resources - installs Helm release(s) for the GitHub Actions Runner controller and supporting charts. These create the namespace, controller deployment, CRDs and runner resources.
- `variables.tf` - declares variables consumed by the scripts (GH App IDs, secrets, AKS details, Helm chart values, etc.).
- `gha.tfvars` (example) - user-provided values for local runs (not checked in). Use this to provide the GitHub App credentials and any AKS/cluster overrides.
- `null_resource` block (in one of the .tf files) - runs cleanup on destroy to remove CRD finalizers.

The Terraform code typically:
1. Ensures provider configuration and access to the target Kubernetes cluster (AKS).
2. Installs Helm chart(s) such as `actions-runner-controller` into a dedicated namespace.
3. Creates any needed Kubernetes resources (namespace, secrets) or Helm values for GitHub App auth.
4. Exposes outputs for runner metrics or status.
5. On destroy, executes the null_resource to remove finalizers from runner CRDs so the uninstall can complete.

## Architecture

### a) Terraform resource architecture

- Helm release(s): Terraform manages Helm releases for the GitHub Actions Runner controller and possibly helper charts (image registry, cert manager values, etc.).
- Kubernetes namespace: Helm / Terraform will create a namespace dedicated to the runner controller and runner-related resources.
- Secrets & config: Terraform creates Kubernetes Secrets containing the GitHub App private key, app id and installation id (or instructs the chart to read them from values). These secrets are mounted into the controller deployment so it can authenticate to GitHub.
- null_resource: a Terraform resource configured with lifecycle hooks to run on destroy. The destroy hook executes commands (kubectl patch .../remove finalizers) to remove finalizers from runner CRDs so the chart and CRDs can be deleted.

Visually (Terraform viewpoint):

Terraform -> Helm provider -> Helm release -> K8s namespace + CRDs + Controller Deployment + Runner pods

Null_resource (destroy) -> kubectl patch CRDs to remove finalizers -> allow Helm/Terraform to delete CRDs

### b) Kubernetes resources created by the GitHub Actions Runner helm chart

The exact CRDs and resources vary slightly between implementations, but common resources created by a controller chart such as actions-runner-controller include:
- CRDs (CustomResourceDefinitions):
  - Runner (represents a single runner pod)
  - RunnerDeployment (declarative set for rolling updates)
  - RunnerReplicaSet (managed by the controller)
  - HorizontalRunnerAutoscaler (HRA) (optional autoscaling CRD)
- Controller Deployment: a Kubernetes Deployment / ServiceAccount that runs the controller which watches CRDs and ensures runner pods are created, registered with GitHub, and terminated when no longer needed.
- Runner Pods: ephemeral pods that run the official actions-runner image and register with GitHub via the controller. The controller uses the GitHub App credentials (App ID, Installation ID, private key) kept in secrets.
- ServiceAccount / Roles / RoleBindings: RBAC artifacts that let the controller create pods, CRs, and manage required resources.

These resources combined implement the lifecycle: when you create a RunnerDeployment or Runner object, the controller creates pods that register with GitHub. When the controller deletes a Runner, it deregisters the runner from GitHub and deletes the pod.

Sources for the controller and CRD patterns: the actions-runner-controller project (repo: https://github.com/actions-runner-controller/actions-runner-controller) and the official GitHub documentation on self-hosted runners.

## Variables

This project exposes variables that control deployment. Typical variables and their purpose:
- `github_app_id` (string): GitHub Actions App Id. Used by the controller to authenticate to the GitHub API.
- `github_app_installation_id` (string): GitHub Actions App Installation Id. Specifies the installation ID for the GitHub App.
- `github_app_private_key` (string): GitHub Actions App Private Key. Stored securely to sign authentication requests.
- `runner_group` (string): GitHub Actions runner group. Defaults to an empty string.
- `runner_scaleset_name` (string): GitHub Actions runner scale set name.
- `github_config_url` (string): URL of the GitHub repository or organization. Defaults to an empty string.
- `subscription_id` (string): The Azure Subscription ID where the AKS cluster is located.
- `tenant_id` (string): The Azure Tenant ID where the AKS cluster is located.
- `aks_cluster_name` (string): AKS Cluster name.
- `aks_resource_group` (string): AKS Cluster Resource Group name.

Set these variables in a `gha.tfvars` or via environment/TF Cloud variables. Keep secrets (private key) out of VCS; prefer using secure storage or Terraform Cloud variables with sensitive flags.

## Usage

Local execution (quick):
1. Create a `gha.tfvars` with values for the variables listed above. Example minimal entries:
``` bash
   github_app_id = "<your-app-id>"
   github_installation_id = "<your-installation-id>"
   github_app_private_key = file("/path/to/private-key.pem")
   aks_cluster_name = "<aks-name>"
   aks_resource_group = "<rg-name>"
   runner_namespace = "github-runners"
```
2. If running locally against a kubeconfig, ensure your Kubernetes provider in `providers.tf` points to the cluster or contains a kubeconfig. If the repo sets `use_oidc = true` in `providers.tf` and you are running locally, comment that out so local auth is used.

3. Initialize and apply:

   terraform init -var-file=gha.tfvars
   terraform apply -var-file=gha.tfvars

4. To destroy: `terraform destroy -var-file=gha.tfvars`. The null_resource will run on destroy and remove finalizers from runner CRDs so the uninstall can complete.

Running in Terraform Cloud (recommended for CI-driven infra):
1. Create a Terraform Cloud workspace.
2. Add the required variables to the workspace (sensitive variables for the GitHub App private key and installation id should be marked sensitive). Alternatively, store secrets in a secure secret manager and pass them in at runtime.
3. Create an Azure App Registration in Entra ID (this is the service principal that Terraform Cloud will use to manage Azure resources). In the App Registration's "Authentication" area, add two federated identity credentials: one for the `apply` phase and one for the `plan` phase. The subject for each credential should follow this format:

   `organization:<Terraform organization name>:project:<Terraform project name>:workspace:<Terraform workspace name>:run_phase:<either apply or plan>`

   Useful docs and guidance:
   - Microsoft: Workload identity federation docs (create a federated credential): https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation-create-trust?tabs=azure-portal

   Ensure that you create two separate federated credential records: one with `run_phase:apply` and another with `run_phase:plan`. This distinction is necessary for Terraform Cloud to authenticate correctly during both phases.

4. Once the federated credential is added and Terraform Cloud workspace variables are configured (including the GitHub App credentials), queue a run in Terraform Cloud. The run will authenticate to Azure using the federated credential and apply the Helm release to your AKS cluster.

Notes and assumptions:
- The README assumes `actions-runner-controller`-style chart is used but the repository may also use other runner charts; consult the chart's values and CRDs for exact names.
- Keep private keys out of source control. Use Terraform Cloud sensitive variables or a secrets manager.

## References

- GitHub — About self-hosted runners: https://docs.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners
- GitHub — Creating a GitHub App: https://docs.github.com/en/developers/apps/building-github-apps/creating-a-github-app
- actions-runner-controller repo: https://github.com/actions-runner-controller/actions-runner-controller
- Microsoft — Workload identity federation (create federated credential): https://learn.microsoft.com/azure/active-directory/develop/workload-identity-federation-create-trust?tabs=azure-portal

## Disclaimer and Author

This README is provided as-is for guidance. Use at your own risk and review security implications (in particular, secrets and RBAC). This repository may evolve; always review the Helm chart values and CRDs before deploying in production.

Author: Cyrus Cheng (cyrus822) <br>
GitHub: https://github.com/t217145
