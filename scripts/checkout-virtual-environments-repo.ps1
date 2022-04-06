# This script does a checkout of the github actions virtual environments repository at the latest release tag.
[CmdletBinding()]
param (    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [String] $ImageDisplayName = "ubuntu20"
)


$stopWatch = [System.Diagnostics.Stopwatch]::StartNew()

# In case of an error, display the error message and stop executing
$ErrorActionPreference = 'Stop'
$tag = ((Invoke-RestMethod -Uri https://actionvirtualenvironmentsstatus.azurewebsites.net/api/status).data | Where-Object {$_.DisplayName -eq $ImageDisplayName -and $_.ImageVersion -ne "" }).ImageVersion | Sort-Object | Select-Object -Last 1
git clone https://github.com/actions/virtual-environments.git
Set-Location -Path "virtual-environments"
git checkout tags/$ImageDisplayName/$tag

$stopWatch.Stop()
return $stopWatch.Elapsed