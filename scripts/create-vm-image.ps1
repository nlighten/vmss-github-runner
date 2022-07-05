[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $StorageAccount,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ContainerName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroup,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ImageDisplayName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $Sku = "Premium_LRS",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $DateQuery = "latest"
)



# Determine image name and blob uri
if ($DateQuery.Equals("latest")) {
    $ImageBlob = (az storage blob list --account-name $StorageAccount -c $ContainerName --query "[?contains(name,'$ImageDisplayName')].{name:name, time:properties.creationTime}" | ConvertFrom-JSON | Sort-Object -Property time | Select-Object -Last 1)
} else {
    $ImageBlob = (az storage blob list --account-name $StorageAccount -c $ContainerName --query "[?contains(name,'$ImageDisplayName')&&contains(properties.creationTime,'$DateQuery')].{name:name, time:properties.creationTime}" | ConvertFrom-JSON | Sort-Object -Property time | Select-Object -Last 1)
}

$ImageBlobUri='https://{0}.blob.core.windows.net/{1}/{2}' -f $StorageAccount, $ContainerName, $ImageBlob.name
$ImageName = 'DevOpsImage-{0}-{1}' -f $ImageDisplayName, $ImageBlob.time.toString("yyyy-MM-dd")

if (-not ($imageId = az image list --query "[?name=='$ImageName'].id" -o tsv)) {
    Write-Output "Creating new image with name $ImageName."
    # Create the vm image
    az image create --name $ImageName `
                    --resource-group $ResourceGroup `
                    --source $ImageBlobUri `
                    --os-type Linux `
                    --os-disk-caching ReadWrite `
                    --storage-sku $Sku `
                    --location westeurope
} else {
    Write-Output "Image with name $ImageName already exists. No need to create it."
}
Write-Output "::set-output name=image-name::$ImageName"
# TODO: cleanup old images



