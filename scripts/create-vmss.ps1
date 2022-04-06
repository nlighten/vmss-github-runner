[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VmssName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VirtualNetworkName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VirtualNetworkSubnet,

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

# Create the scale set
$Vmss = az vmss create `
            --resource-group $ResourceGroup `
            --name $VmssName `
            --image $Image.id `
            --admin-username ghrunner `
            --admin-password PswPsw123 `
            --authentication-type password `
            --priority Spot `
            --eviction-policy Delete `
            --max-price -1 `
            --instance-count 1 `
            --custom-data ./config/cloud-config.yaml `
            --vnet-name $VirtualNetworkName `
            --subnet $VirtualNetworkSubnet `
            --load-balancer "" `
            --disable-overprovision `
            --location westeurope




