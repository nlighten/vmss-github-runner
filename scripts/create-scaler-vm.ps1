[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VmName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $Password,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $User,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VirtualNetworkName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VirtualNetworkSubnet,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $NetworkResourceGroup,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroup
)



$SubnetId = az network vnet subnet show --name $VirtualNetworkSubnet --resource-group $NetworkResourceGroup --vnet-name $VirtualNetworkName --query id -o tsv 


# Create the vm
az vm create `
        --resource-group $ResourceGroup `
        --name $VmName `
        --image 'Canonical:0001-com-ubuntu-server-focal:20_04-lts:latest' `
        --admin-username $User `
        --admin-password $Password `
        --authentication-type password `
        --custom-data ./config/cloud-config-scaler.yaml `
        --subnet $SubnetId `
        --size Standard_B1s `
        --location westeurope

#        --public-ip-address '""' `
