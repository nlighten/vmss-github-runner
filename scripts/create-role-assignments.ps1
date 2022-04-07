[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $VmssName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $QueueStorageAccount,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroup

)



$VmssId = az vmss show --resource-group $ResourceGroup --name $VmssName --query id -o tsv
$IdentityPrincipalId = az identity create --resource-group $ResourceGroup --name "id-$VmssName" --query principalId -o tsv
$QueueStorageAccountId = az storage account show --name $QueueStorageAccount --query id -o tsv

az vmss identity assign --resource-group $ResourceGroup  --name $VmssName --identities id-$VmssName 

az role assignment create --role 'Virtual Machine Contributor' --scope $VmssId --assignee-object-id $IdentityPrincipalId
az role assignment create --role 'Storage Queue Data Contributor' --scope $QueueStorageAccountId --assignee-object-id $IdentityPrincipalId