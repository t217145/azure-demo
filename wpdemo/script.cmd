cd wpdemo
terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan
$default_site_hostname = terraform output --raw default_site_hostname
echo $default_site_hostname