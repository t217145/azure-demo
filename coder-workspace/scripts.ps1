# Login in and get the subscription Id for later user
az login --use-device-code
Set-Variable -Name "subId" $(az account list --query "[?isDefault].id" -otsv)
az account set -s $subId

# Provision AKS and Files Share
terraform -chdir=tf init
terraform -chdir=tf plan -out main.tfplan
terraform -chdir=tf apply main.tfplan

#Get variable from Terraform output
Set-Variable -Name "aks_name" $(terraform -chdir=tf output --raw aks_name)
Set-Variable -Name "rg_name" $(terraform -chdir=tf output --raw rg_name)

# Get access to AKS created so that we can deploy service and SA by kubectl later
az aks get-credentials -n "${aks_name}" -g "${rg_name}"

# Get value from config.json
$configPath = "coder-helm\config.json"
$config = Get-Content $configPath | ConvertFrom-Json

$k8sNS = $config.k8sNS
$dbName = $config.dbName
$dbUsr = $config.dbUsr
$dbPwd = $config.dbPwd

#Create the namespace
kubectl create namespace $k8sNS

# Install PostgreSQL
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install coder-db bitnami/postgresql `
    --namespace $k8sNS `
    --set auth.username=$dbUsr `
    --set auth.password=$dbPwd `
    --set auth.database=$dbName `
    --set persistence.size=10Gi

# Create a secret for the database URL
Set-Variable -Name "dbUrl" -Value "postgres://${dbUsr}:${dbPwd}@coder-db-postgresql.${k8sNS}.svc.cluster.local:5432/${dbName}?sslmode=disable"
#Write-Output $dbUrl
kubectl create secret generic coder-db-url -n ${k8sNS} --from-literal=url=$dbUrl

# Install Coder
helm repo add coder-v2 https://helm.coder.com/v2

helm install coder coder-v2/coder `
    --namespace ${k8sNS} `
    --values coder-helm\values.yaml `
    --version 2.22.1

# Wait for Coder to be ready and get the external IP
kubectl get svc -n ${k8sNS} --watch

### For demo use
<#
  helm uninstall coder-db --namespace $k8sNS
  helm uninstall coder --namespace $k8sNS
  terraform -chdir=tf apply -destroy -auto-approve
#>
