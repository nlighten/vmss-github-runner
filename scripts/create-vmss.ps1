[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VmssName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $StorageAccount,

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
    [string] $ResourceGroup,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ImageDisplayName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $DateQuery = "latest"
)



# Determine image to use
if ($DateQuery.Equals("latest")) {
    $Query = "[?contains(name,'$ImageDisplayName')].{name:name, id:id}"
} else {
    $Query = "[?contains(name,'$ImageDisplayName')&&contains(name,'$DateQuery')].{name:name, id:id}"
}
$Image = (az image list --resource-group $ResourceGroup --query "$Query" | ConvertFrom-JSON | Sort-Object -Property name | Select-Object -Last 1)
$SubnetId = az network vnet subnet show --name $VirtualNetworkSubnet --resource-group $NetworkResourceGroup --vnet-name $VirtualNetworkName --query id -o tsv 


# Create the scale set
az vmss create `
        --resource-group $ResourceGroup `
        --name $VmssName `
        --image $Image.id `
        --admin-username $User `
        --admin-password $Password `
        --authentication-type password `
        --priority Spot `
        --eviction-policy Delete `
        --max-price -1 `
        --instance-count 1 `
        --custom-data ./config/cloud-config.yaml `
        --subnet $SubnetId `
        --load-balancer '""' `
        --disable-overprovision `
        --location westeurope
