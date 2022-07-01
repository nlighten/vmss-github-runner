[CmdletBinding()]
param(
    [String] [Parameter (Mandatory = $true)]  $TemplatePath,
    [String] [Parameter (Mandatory = $true)]  $ResourcesNamePrefix,
    [String] [Parameter (Mandatory = $true)]  $Location,
    [String] [Parameter (Mandatory = $true)]  $ResourceGroup,
    [String] [Parameter (Mandatory = $true)]  $StorageAccount,
    [String] [Parameter (Mandatory = $true)]  $VirtualNetworkName,
    [String] [Parameter (Mandatory = $true)]  $VirtualNetworkRG,
    [String] [Parameter (Mandatory = $true)]  $VirtualNetworkSubnet,
    [String] [Parameter (Mandatory = $false)] $UsePublicIp = "false",
    [Bool]   [Parameter (Mandatory = $false)] $UseAzureCliLogin = $true,
    [Int]    [Parameter(Mandatory = $false)]  $MaxRetries = 1
)

pwd
ls
ls  $TemplatePath

if (-not (Test-Path $TemplatePath)) {
    Write-Error "'-TemplatePath' parameter is not valid. You have to specify correct Template Path"
    exit 1
}

$Image = [io.path]::GetFileNameWithoutExtension($TemplatePath)
$TempResourceGroupName = "${ResourcesNamePrefix}_${Image}"
$InstallPassword = [System.GUID]::NewGuid().ToString().ToUpper()

packer validate -syntax-only $TemplatePath

$SensitiveData = @(
    'OSType',
    'StorageAccountLocation',
    'OSDiskUri',
    'OSDiskUriReadOnlySas',
    'TemplateUri',
    'TemplateUriReadOnlySas',
    ':  ->'
)

Write-Host "Show Packer Version"
packer --version


if ($UseAzureCliLogin) {
    Write-Host "Using Azure CLI loging"
    # We replace the client_id builder parameters and force to use azure cli instead.
    ((Get-Content -path $TemplatePath -Raw) -replace '"client_id": "{{user `client_id`}}",', '"use_azure_cli_auth": true,') | Set-Content -Path $TemplatePath
}
Get-Content -path $TemplatePath -Raw


# Build image with packer
Write-Host "Build $Image VM"
$exitCode = 888
$retries = 0
while ($exitCode -ne 0 -and $retries -lt $MaxRetries) {
    $(& packer build `
        -var "capture_name_prefix=$ResourcesNamePrefix" `
        -var "install_password=$InstallPassword" `
        -var "location=$Location" `
        -var "resource_group=$ResourceGroup" `
        -var "storage_account=$StorageAccount" `
        -var "temp_resource_group_name=$TempResourceGroupName" `
        -var "virtual_network_name=$VirtualNetworkName" `
        -var "virtual_network_resource_group_name=$VirtualNetworkRG" `
        -var "virtual_network_subnet_name=$VirtualNetworkSubnet" `
        -var "private_virtual_network_with_public_ip=$UsePublicIp" `
        -var "run_validation_diskspace=false" `
        $TemplatePath ; $exitCode=$LASTEXITCODE `
    | Where-Object {
        #Filter sensitive data from Packer logs
        $currentString = $_
        $sensitiveString = $SensitiveData | Where-Object { $currentString -match $_ }
        $sensitiveString -eq $null
    })
    $retries++
}