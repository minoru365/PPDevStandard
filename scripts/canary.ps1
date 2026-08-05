[CmdletBinding()]
param(
    [string]$CataloguePath = (Join-Path $PSScriptRoot '..\profiles\capabilities.json')
)

$ErrorActionPreference = 'Stop'

$validatorPath = Join-Path $PSScriptRoot 'validate-catalogue.ps1'
. $validatorPath
$catalogue = Get-PPDevCatalogue -Path $CataloguePath

Write-Output 'PPDevStandard capability canary'
Write-Output "catalogue updated: $($catalogue.updated)"
foreach ($capability in $catalogue.capabilities) {
    $clientCoverage = @($capability.clientSupport | ForEach-Object { "$($_.clientId)=$($_.status)" }) -join ', '
    Write-Output "capability: $($capability.id)"
    Write-Output "source: $($capability.source.repository)"
    Write-Output "clients: $clientCoverage"
    Write-Output 'verification: manual development-environment confirmation required for plugin and MCP readiness'
}

Write-Output 'result: catalogue is valid; no network, authentication, installation, tenant, or project operation was attempted.'
