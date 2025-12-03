### Introduction
This is an Azure CLI script to setup a NextCloud application on Azure WebApps. With permanent storage mounted to Azure Storage Account Files Share.

### How to use
1. You can run in your local terminal or in Azure Cloud Shell. Beware that if you run on your local terminal, you need to have Azure CLI and Terraform CLI installed.

2. Run following command
   ```bash
   git clone https://github.com/t217145/azure-demo.git
   cd azure-demo/nextcloud
   ```

3. Change the value in variables.tf

4. ***Only for local termainal*** Run the command az login to login to your Azure account.\
   ***Only for Azure CLI*** Run the command az account list to get the default subscription id.

5. Set the environmental variable **ARM_SUBSCRIPTION_ID** with your subscription id.

6. Run following script 
    ```bash
    terraform init
    terraform plan -out main.tfplan
    terraform apply main.tfplan
    ```
