[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('codex', 'claude-code', 'github-copilot-cli')]
    [string]$Client,

    [ValidateSet('all', 'canvas-apps', 'power-automate-flowagent', 'dataverse', 'copilot-studio', 'power-cat')]
    [string]$Capability = 'all',

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

$clientCommands = @{
    'codex' = 'codex'
    'claude-code' = 'claude'
    'github-copilot-cli' = 'copilot'
}

$hasMissingPrerequisite = $false
Write-Output '開発環境の前提確認'
Write-Output "クライアント: $Client"

$clientCommand = $clientCommands[$Client]
$clientStatus = Test-PPDevCommand -Name $clientCommand
if ($clientStatus.Present) {
    Write-Output "client command '$clientCommand': present ($($clientStatus.VersionStatus))"
}
else {
    Write-Output "client command '$clientCommand': missing"
    $hasMissingPrerequisite = $true
}

foreach ($selectedCapability in $selectedCapabilities) {
    $clientSupport = @($selectedCapability.clientSupport | Where-Object { $_.clientId -eq $Client })[0]
    Write-Output "機能: $($selectedCapability.name) [$($clientSupport.status)]"
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

    Write-Output '手動確認: 公式プラグインの導入と MCP 接続を開発環境で確認してください。'
}

if ($hasMissingPrerequisite) {
    exit 1
}
