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
    param(
        [Parameter(Mandatory)][string]$Name,
        [Nullable[int]]$MinimumMajor
    )

    $command = Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $command) {
        return [pscustomobject]@{ Present = $false; VersionStatus = 'not-checkable'; MajorVersion = $null; MinimumMajor = $MinimumMajor }
    }

    $versionStatus = 'not-checkable'
    $majorVersion = $null
    try {
        $versionOutput = @(& $command.Source '--version' 2>$null | ForEach-Object { $_.ToString() }) -join "`n"
        if ($LASTEXITCODE -eq 0) {
            $versionStatus = 'present'
            $versionMatch = [regex]::Match($versionOutput, '(?<!\d)(?<major>\d+)(?:\.\d+){0,3}')
            if ($versionMatch.Success) {
                $majorVersion = [int]$versionMatch.Groups['major'].Value
            }
        }
    }
    catch {
        $versionStatus = 'not-checkable'
    }

    $isTooLow = $null -ne $MinimumMajor -and $null -ne $majorVersion -and $majorVersion -lt $MinimumMajor
    [pscustomobject]@{
        Present = -not $isTooLow
        VersionStatus = if ($isTooLow) { 'too-low' } else { $versionStatus }
        MajorVersion = $majorVersion
        MinimumMajor = $MinimumMajor
    }
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

$selectedClient = @($catalogue.clients | Where-Object { $_.id -eq $Client })[0]
foreach ($clientPrerequisite in @($selectedClient.prerequisiteCommands)) {
    $status = Test-PPDevCommand -Name $clientPrerequisite.name -MinimumMajor $clientPrerequisite.minimumMajor
    if ($status.Present) {
        $versionLabel = if ($null -ne $status.MajorVersion) { "major version $($status.MajorVersion)" } else { $status.VersionStatus }
        Write-Output "client prerequisite '$($clientPrerequisite.name)': present ($versionLabel)"
    }
    elseif ($status.VersionStatus -eq 'too-low') {
        Write-Output "client prerequisite '$($clientPrerequisite.name)': missing (requires major version $($status.MinimumMajor); found $($status.MajorVersion))"
        $hasMissingPrerequisite = $true
    }
    else {
        Write-Output "client prerequisite '$($clientPrerequisite.name)': missing"
        $hasMissingPrerequisite = $true
    }
}

foreach ($selectedCapability in $selectedCapabilities) {
    $clientSupport = @($selectedCapability.clientSupport | Where-Object { $_.clientId -eq $Client })[0]
    Write-Output "機能: $($selectedCapability.name) [$($clientSupport.status)]"
    foreach ($prerequisite in @($selectedCapability.prerequisiteCommands)) {
        $status = Test-PPDevCommand -Name $prerequisite.name -MinimumMajor $prerequisite.minimumMajor
        if ($status.Present) {
            $versionLabel = if ($null -ne $status.MajorVersion) { "major version $($status.MajorVersion)" } else { $status.VersionStatus }
            Write-Output "prerequisite '$($prerequisite.name)': present ($versionLabel)"
        }
        elseif ($status.VersionStatus -eq 'too-low') {
            Write-Output "prerequisite '$($prerequisite.name)': missing (requires major version $($status.MinimumMajor); found $($status.MajorVersion))"
            $hasMissingPrerequisite = $true
        }
        else {
            Write-Output "prerequisite '$($prerequisite.name)': missing"
            $hasMissingPrerequisite = $true
        }
    }

    Write-Output '手動確認: 公式プラグインの導入と MCP 接続を開発環境で確認してください。'
}

if ($hasMissingPrerequisite) {
    exit 1
}
