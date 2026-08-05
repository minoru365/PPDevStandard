[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('codex', 'claude-code', 'github-copilot-cli')]
    [string]$Client,

    [string]$Capability = 'all',

    [switch]$SkipMcpConfigCheck,

    [string]$CataloguePath = (Join-Path $PSScriptRoot '..\profiles\capabilities.json')
)

$ErrorActionPreference = 'Stop'

function Test-PPDevCommand {
    param([Parameter(Mandatory)][string]$Name)

    $command = Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return [pscustomobject]@{ Present = $false; VersionStatus = 'not-checkable' }
    }

    $versionStatus = 'not-checkable'
    try {
        & $command.Source '--version' *> $null
        if ($LASTEXITCODE -eq 0) {
            $versionStatus = 'present'
        }
    }
    catch {
        $versionStatus = 'not-checkable'
    }

    [pscustomobject]@{ Present = $true; VersionStatus = $versionStatus }
}

$validatorPath = Join-Path $PSScriptRoot 'validate-catalogue.ps1'
. $validatorPath
$catalogue = Get-PPDevCatalogue -Path $CataloguePath

if ($Client -notin @($catalogue.clients.id)) {
    throw "Client '$Client' is not in the capability catalogue."
}

$selectedCapabilities = if ($Capability -eq 'all') {
    @($catalogue.capabilities)
}
else {
    @($catalogue.capabilities | Where-Object { $_.id -eq $Capability })
}

if ($selectedCapabilities.Count -eq 0) {
    throw "Capability '$Capability' is not in the capability catalogue."
}

$hasMissingPrerequisite = $false
Write-Output "client: $Client"
foreach ($selectedCapability in $selectedCapabilities) {
    $clientSupport = @($selectedCapability.clientSupport | Where-Object { $_.clientId -eq $Client })[0]
    Write-Output "capability: $($selectedCapability.id) ($($clientSupport.status))"
    foreach ($prerequisite in @($selectedCapability.prerequisiteCommands | Select-Object -Unique)) {
        $status = Test-PPDevCommand -Name $prerequisite
        if ($status.Present) {
            Write-Output "prerequisite '$prerequisite': present ($($status.VersionStatus))"
        }
        else {
            Write-Output "prerequisite '$prerequisite': missing"
            $hasMissingPrerequisite = $true
        }
    }

    if ($SkipMcpConfigCheck) {
        Write-Output 'MCP readiness: skipped'
    }
    else {
        Write-Output 'MCP readiness: manual-verification-required'
    }
}

if ($hasMissingPrerequisite) {
    exit 1
}
