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
    [string] $ImageDisplayName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string] $ImageQuery = "latest"
)



# Determin image name and blob uri
if ($ImageQuery.Equals("latest")) {
    $ImageBlob = (az storage blob list --account-name $StorageAccount -c $ContainerName --query "[?contains(name,'$ImageDisplayName')].{name:name, time:properties.creationTime}" | ConvertFrom-JSON | Sort-Object -Property time | Select-Object -Last 1)
} else {
    $ImageBlob = (az storage blob list --account-name $StorageAccount -c $ContainerName --query "[?contains(name,'$ImageDisplayName')&&contains(properties.creationTime,'$ImageQuery')].{name:name, time:properties.creationTime}" | ConvertFrom-JSON | Sort-Object -Property time | Select-Object -Last 1)
}
az storage blob list --account-name h04p1winstonpbasa01ado -c system --query "[?contains(properties.creationTime,'2022-02-01')].{name:name, time:properties.creationTime}"

$ImageBlobUri='https://{0}.blob.core.windows.net/{1}/{2}' -f $StorageAccount, $ContainerName, $ImageBlob.name
$ImageName = 'DevOpsImage-{0}-{1}' -f $ImageDisplayName, $ImageBlob.time.toString("yyyy-mm-dd")

Write-Output "##vso[task.setvariable variable=ImageBlobUri;isOutput=true]$ImageBlobUri"
Write-Output "Stored value: $ImageBlobUri as ImageBlobUri"
write-Output "##vso[task.setvariable variable=ImageName;isOutput=true]$ImageName"
Write-Output "Stored value: $ImageName as ImageName"