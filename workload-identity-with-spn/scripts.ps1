Set-Variable -Name "k8sNS" -Value "wi-demo"
Set-Variable -Name "k8sSA" -Value "wi-demo-sa"
Set-Variable -Name "k8sSvc" -Value "wi-demo"
Set-Variable -Name "dir" -Value "k8s-yaml"
Set-Variable -Name "spnDir" -Value "spn"

az login --use-device-code
az account set -s $(az account list --query "[?isDefault].id" -otsv)

<#
  az extension add --name aks-preview
  az extension update --name aks-preview
  az feature register --namespace "Microsoft.ContainerService" --name "EnablePodIdentityPreview"
  az feature list --query "[?properties.state == 'Registering'].name"
  az feature list --query "[?properties.state == 'Registered'].name"
  az feature show --namespace "Microsoft.ContainerService" --name "EnablePodIdentityPreview"
  az provider register --namespace Microsoft.ContainerService
#>

terraform -chdir=tf init
terraform -chdir=tf plan -out main.tfplan
terraform -chdir=tf apply main.tfplan

$tenant_id = terraform -chdir=tf output --raw tenant_id
$spn_asb_client_id = terraform -chdir=tf output --raw spn_asb_client_id
$spn_db_client_id = terraform -chdir=tf output --raw spn_db_client_id
$acr_admin_username = terraform -chdir=tf output --raw acr_admin_username
$acr_admin_password = terraform -chdir=tf output --raw acr_admin_password
$aks_name = terraform -chdir=tf output --raw aks_name
$acr_name = terraform -chdir=tf output --raw acr_name
$asb_name = terraform -chdir=tf output --raw asb_name
$spn_asb_name = terraform -chdir=tf output --raw spn_asb_name
$spn_db_name = terraform -chdir=tf output --raw spn_db_name
$rg_name = terraform -chdir=tf output --raw rg_name
$db_svr_name = terraform -chdir=tf output --raw db_svr_name
$db_name = terraform -chdir=tf output --raw db_name
$asb_queue_name = terraform -chdir=tf output --raw asb_queue_name

az aks get-credentials -n "${aks_name}" -g "${rg_name}"
Set-Variable -Name "oidcUrl" $(az aks show -n "${aks_name}" -g "${rg_name}" --query "oidcIssuerProfile.issuerUrl" -otsv)

Write-Host `
    "TenantId: " $tenant_id "`n" `
    "SPN-ASB Client Id: " $spn_asb_client_id "`n" `
    "SPN-DB Client Id:" $spn_db_client_id "`n" `
    "OIDC Issuer URL: " $oidcUrl "`n" `
    "ACR Username: " $acr_admin_username "`n" `
    "ACR Password: "  $acr_admin_password

<#
CREATE USER "wi-demo-spn-db" FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER "wi-demo-spn-db";
ALTER ROLE db_datawriter ADD MEMBER "wi-demo-spn-db";
ALTER ROLE db_ddladmin ADD MEMBER "wi-demo-spn-db";
GO
#>

mvn -f code/pom.xml clean package -D maven.test.skip=true

docker login "${acr_admin_username}.azurecr.io" -u "${acr_admin_username}" -p "${acr_admin_password}"

docker image build -t "${acr_admin_username}.azurecr.io/wi-demo-spn" code/.
docker push "${acr_admin_username}.azurecr.io/wi-demo-spn"

if (-not (Test-Path -Path $spnDir -PathType Container)) {
  New-Item -ItemType Directory -Path $spnDir
}

Set-Variable "spn_asb_id" "$(az ad app list --display-name "${spn_asb_name}" --query '[0].id' -otsv)"
Set-Variable "spn_db_id" "$(az ad app list --display-name "${spn_db_name}" --query '[0].id' -otsv)"

echo @"
{
"name": "${spn_db_name}-fed",
"issuer": "${oidcUrl}",
"subject": "system:serviceaccount:${k8sNS}:${k8sSA}",
"description": "Kubernetes service account federated identity",
"audiences": [
  "api://AzureADTokenExchange"
]
}
"@ > ${spnDir}/${spn_db_name}-fed.json

echo @"
{
"name": "${spn_asb_name}-fed",
"issuer": "${oidcUrl}",
"subject": "system:serviceaccount:${k8sNS}:${k8sSA}",
"description": "Kubernetes service account federated identity",
"audiences": [
  "api://AzureADTokenExchange"
]
}
"@ > ${spnDir}/${spn_asb_name}-fed.json

az ad app federated-credential create --id $spn_db_id --parameters ${spnDir}/${spn_db_name}-fed.json
az ad app federated-credential create --id $spn_asb_id --parameters ${spnDir}/${spn_asb_name}-fed.json

if (-not (Test-Path -Path $dir -PathType Container)) {
    New-Item -ItemType Directory -Path $dir
}

echo @"
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/${spn_asb_name}-fed: ${spn_asb_client_id}
    azure.workload.identity/${spn_db_name}-fed: ${spn_db_client_id}
  name: ${k8sSA}
  namespace: ${k8sNS}
  labels:
    azure.workload.identity/use: "true"
"@ > ${dir}/ServiceAccount.yaml

echo @"
apiVersion: v1
kind: Namespace
metadata:
  name: wi-demo
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wi-demo
  labels:
    app: wi-demo
  namespace: ${k8sNS}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: wi-demo
  template:
    metadata:
      labels:
        app: wi-demo
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: ${k8sSA}
      containers:
        - name: wi-demo
          image: ${acr_admin_username}.azurecr.io/wi-demo-spn:latest
          ports:
            - containerPort: 8080
          env:
            - name: asbns
              value: ${asb_name}
            - name: asbspn
              value: ${spn_asb_client_id}
            - name: tenantId
              value: ${tenant_id}
            - name: dbsvr
              value: ${db_svr_name}
            - name: db
              value: ${db_name}
            - name: dbspn
              value: ${spn_db_client_id}
            - name: asbQ
              value: ${asb_queue_name}
"@ > ${dir}/Deployment.yaml

echo @"
apiVersion: v1
kind: Service
metadata:
  name: ${k8sSvc}
  namespace: ${k8sNS}
  labels:
    app: wi-demo
    azure.workload.identity/use: "true"    
spec:
  selector:
    app: wi-demo
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer
"@ > ${dir}\Service.yaml

kubectl apply -f ${dir}\.

Set-Variable -Name "SvcUrl" $(kubectl get service ${k8sSvc} -n ${k8sNS} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "http://${SvcUrl}/sendAsb/This is a test msg from AKS by SPN`nhttp://${SvcUrl}/saveToDB/This is a test record from AKS by SPN"

<#
  select * from wi_demo;
  delete from wi_demo;
  DBCC CHECKIDENT ('[wi_demo]', RESEED, 0);
  GO

  kubectl delete -f ${dir}\.
  terraform -chdir=tf apply -destroy -auto-approve

  Remove-Item -Path ${dir} -Recurse -Force
  Remove-Item -Path ${spnDir} -Recurse -Force
  Get-ChildItem -Path tf -Recurse | Where-Object { $_.Extension -ne '.tf' } | Remove-Item -Force -Recurse
#>