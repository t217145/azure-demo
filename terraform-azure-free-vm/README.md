### Before start
1. You can check the available zone in your subscription that support Standard_B1s
```console
az vm list-skus --size Standard_B1s --all --output table

```

### Setup the VPN server
1. Go to Azure Console or local terminal with Azure CLI / PowerShell installed
2. Clone this repo
```console
git clone https://github.com/t217145/azure-demo.git
cd azure-demo/terraform-azure-free-vm

```
3. Change the value in variables.tf and save it (press Ctrl and X in edit mode)
```console
nano variables.tf

```
4. Type following command in sequence
```console
terraform init
terraform plan -out main.tfplan
terraform apply main.tfplan
$ip_address = terraform output --raw public_ip_address
$sh_pwd = terraform output shadowsocks_pwd
echo $ip_address
echo $sh_pwd

```
5. Open a browser and visit the http://{$ip_address}
e.g. if the ip address it show is 10.1.2.3 then enter http://10.1.2.3 in your browser
Beware that you can down the openvpn file just once!!
6. Open the file you downloaded, change the port number to that of you defined in variables.tf

### Setup in your mobile / desktop
1. Install / Download the openvpn apps
2. Download the above openvpn file to your mobile
3. Open the openvpn apps and import the profile by selecting openvpn file you downloaded

### Adding new ShadowSocks and open NSG port
1. Change the value of PortNbr, Pwd and SdsName
```console
$PortNbr=10000
$Pwd="123456789"
$SdsName="mySds"

Set-Variable -Name "Cmd" -Value "docker run -itd -e PASSWORD=${Pwd} -e METHOD=aes-256-gcm -p ${PortNbr}:8388 --name ${SdsName} shadowsocks/shadowsocks-libev"
Set-Variable -Name "VmName" $(az vm list --query "[0].name" --output tsv)
Set-Variable -Name "RGName" $(az network nsg list --query "[0].{ResourceGroup:resourceGroup}" --output tsv)
Set-Variable -Name "NSGName" $(az network nsg list --query "[0].{NSGName:name}" --output tsv)
Set-Variable -Name "MaxPriority" ([int]$(az network nsg rule list --nsg-name ${NSGName} --resource-group ${RGName}  --query "[*].priority" --output tsv | sort -nr | head -n 1) + 1) 
az network nsg rule create --resource-group ${RGName} --nsg-name ${NSGName} --name ${SdsName} --direction Inbound --priority ${MaxPriority} --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range ${PortNbr} --access Allow --protocol "*"
az vm run-command invoke --resource-group ${RGName} --name ${VmName} --command-id RunShellScript --scripts "${Cmd}"

```

### Adding new openVpn and open NSG port
1. Change the value of oPortNbr and openVpnName
```console
$oPortNbr=10001
$webPortNbr=10002
$openVpnName="myVpn"

Set-Variable -Name "oCmd" -Value "docker run -itd --cap-add=NET_ADMIN -p ${oPortNbr}:1194/udp -p ${webPortNbr}:8080/tcp -e HOST_ADDR=$(curl -s https://api.ipify.org) --name ${openVpnName}vpn alekslitvinenk/openvpn"
Set-Variable -Name "VmName" $(az vm list --query "[0].name" --output tsv)
Set-Variable -Name "RGName" $(az network nsg list --query "[0].{ResourceGroup:resourceGroup}" --output tsv)
Set-Variable -Name "NSGName" $(az network nsg list --query "[0].{NSGName:name}" --output tsv)
Set-Variable -Name "Url" $(az vm show --resource-group ${RGName} --name ${VmName} -d --query publicIps -o tsv)
Set-Variable -Name "MaxPriority" ([int]$(az network nsg rule list --nsg-name ${NSGName} --resource-group ${RGName}  --query "[*].priority" --output tsv | sort -nr | head -n 1) + 1) 
az network nsg rule create --resource-group ${RGName} --nsg-name ${NSGName} --name ${openVpnName}Vpn --direction Inbound --priority ${MaxPriority} --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range ${oPortNbr} --access Allow --protocol "*"
az network nsg rule create --resource-group ${RGName} --nsg-name ${NSGName} --name ${openVpnName}Web --direction Inbound --priority (${MaxPriority}+1) --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range ${webPortNbr} --access Allow --protocol "*"
az vm run-command invoke --resource-group ${RGName} --name ${VmName} --command-id RunShellScript --scripts "${oCmd}"
echo "http://${Url}:${webPortNbr}"

```
