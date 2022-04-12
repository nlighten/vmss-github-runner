[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VmName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VmssName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $QueueStorageAccount,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroup,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $NetworkResourceGroup

)



$IdentityPrincipalId = az identity create --resource-group $ResourceGroup --name "id-$VmName" --query principalId -o tsv
$VmssId = az vmss show --resource-group $ResourceGroup --name $VmssName --query id -o tsv
$QueueStorageAccountId = az storage account show --name $QueueStorageAccount --query id -o tsv

az vm identity assign --resource-group $ResourceGroup  --name $VmName --identities id-$VmName 

az role assignment create --role 'Reader' --resource-group $ResourceGroup --assignee-object-id $IdentityPrincipalId
az role assignment create --role 'Network Contributor' --resource-group $ResourceGroup --assignee-object-id $IdentityPrincipalId
az role assignment create --role 'Virtual Machine Contributor' --scope $VmssId --assignee-object-id $IdentityPrincipalId
az role assignment create --role 'Contributor' --scope $QueueStorageAccountId --assignee-object-id $IdentityPrincipalId
