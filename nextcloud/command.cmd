az login
ARM_SUBSCRIPTION_ID=
terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan
REM terraform destroy -auto-approve