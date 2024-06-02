az login --use-device-code & terraform plan -destroy -out main.destroy.tfplan & terraform apply "main.destroy.tfplan" & del *.tfplan & del *.tfstate* & del *.lock*
