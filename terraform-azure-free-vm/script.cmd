az login --use-device-code & terraform init & terraform plan -out main.tfplan & terraform apply main.tfplan & set ip_address=terraform output --raw public_ip_address & echo %ip_address% > ip.txt
