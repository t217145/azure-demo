Set-Variable -Name "k8sNS" -Value "wi-demo"
Set-Variable -Name "k8sSA" -Value "wi-demo-sa"
Set-Variable -Name "k8sSvc" -Value "wi-demo"
Set-Variable -Name "dir" -Value "k8s-yaml"
Set-Variable -Name "spnDir" -Value "spn"

az login --use-device-code
Set-Variable -Name "subId" $(az account list --query "[?isDefault].id" -otsv)
az account set -s $subId

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

Set-Variable -Name "usrname" $(az account show --query user.name --output tsv)
Set-Variable -Name "CurrentUsrId" $(az ad signed-in-user show --query id -o tsv)
Set-Variable -Name "asbScopeId" $(az servicebus namespace show --name wi-demo-asb1 --resource-group wi-demo-rg --query id --output tsv)
Set-Variable -Name "tenant_id" $(terraform -chdir=tf output --raw tenant_id)
Set-Variable -Name "spn_asb_client_id" $(terraform -chdir=tf output --raw spn_asb_client_id)
Set-Variable -Name "spn_db_client_id" $(terraform -chdir=tf output --raw spn_db_client_id)
Set-Variable -Name "acr_admin_username" $(terraform -chdir=tf output --raw acr_admin_username)
Set-Variable -Name "acr_admin_password" $(terraform -chdir=tf output --raw acr_admin_password)
Set-Variable -Name "aks_name" $(terraform -chdir=tf output --raw aks_name)
Set-Variable -Name "acr_name" $(terraform -chdir=tf output --raw acr_name)
Set-Variable -Name "asb_name" $(terraform -chdir=tf output --raw asb_name)
Set-Variable -Name "spn_asb_name" $(terraform -chdir=tf output --raw spn_asb_name)
Set-Variable -Name "spn_db_name" $(terraform -chdir=tf output --raw spn_db_name)
Set-Variable -Name "rg_name" $(terraform -chdir=tf output --raw rg_name)
Set-Variable -Name "db_svr_name" $(terraform -chdir=tf output --raw db_svr_name)
Set-Variable -Name "db_name" $(terraform -chdir=tf output --raw db_name)
Set-Variable -Name "asb_queue_name" $(terraform -chdir=tf output --raw asb_queue_name)
Set-Variable -Name "db_username" $(terraform -chdir=tf output --raw db_username)
Set-Variable -Name "db_password" $(terraform -chdir=tf output --raw db_password)

az aks get-credentials -n "${aks_name}" -g "${rg_name}"
Set-Variable -Name "oidcUrl" $(az aks show -n "${aks_name}" -g "${rg_name}" --query "oidcIssuerProfile.issuerUrl" -otsv)

az role assignment create --role "Azure Service Bus Data Owner" --assignee $CurrentUsrId --scope $asbScopeId
az sql server ad-admin create --resource-group $rg_name --server-name $db_svr_name --display-name ADMIN --object-id $CurrentUsrId

echo @"
CREATE USER [$spn_db_name] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [$spn_db_name];
ALTER ROLE db_datawriter ADD MEMBER [$spn_db_name];
ALTER ROLE db_ddladmin ADD MEMBER [$spn_db_name];
GO
"@ > tf/script.sql

sqlcmd -S tcp:$db_svr_name.database.windows.net -d $db_name -U $usrname -G -i tf/script.sql

mvn -f code/pom.xml clean package -D maven.test.skip=true

docker login "${acr_admin_username}.azurecr.io" -u "${acr_admin_username}" -p "${acr_admin_password}"
docker image build -t "${acr_admin_username}.azurecr.io/wi-demo-spn" code/.
docker push "${acr_admin_username}.azurecr.io/wi-demo-spn"

<<<<<<< HEAD
mvn -f code/pom.xml clean
docker rmi "${acr_admin_username}.azurecr.io/wi-demo-spn"
=======
mvn -f tf/pom.xml clean
docker rmi ${acr_admin_username}.azurecr.io/wi-demo-spn"
>>>>>>> b49693fed13b2372c0f906eb60563a7b6ea3770e

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

  # annotations:
  #   azure.workload.identity/${spn_asb_name}-fed: ${spn_asb_client_id}
  #   azure.workload.identity/${spn_db_name}-fed: ${spn_db_client_id}

echo @"
apiVersion: v1
kind: ServiceAccount
metadata:

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
kubectl get serviceaccount ${k8sSA} -n ${k8sNS} -o yaml

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