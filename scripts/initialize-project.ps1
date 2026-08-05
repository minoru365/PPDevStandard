[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
    [string]$TargetPath,

    [ValidateSet('all', 'codex', 'claude-code', 'github-copilot-cli')]
    [string[]]$Client = @('all'),

    [ValidateSet('all', 'canvas-apps', 'power-automate-flowagent', 'dataverse', 'copilot-studio', 'power-cat')]
    [string[]]$Capability = @('all'),

    [switch]$Apply
)

$ErrorActionPreference = 'Stop'

function Resolve-PPDevSelection {
    param(
        [Parameter(Mandatory)][string[]]$Requested,
        [Parameter(Mandatory)][string[]]$Available,
        [Parameter(Mandatory)][string]$Kind
    )

    if ($Requested -contains 'all') {
        if ($Requested.Count -ne 1) {
            throw "'$Kind' cannot combine 'all' with explicit values."
        }

        return @($Available)
    }

    $unknown = @($Requested | Where-Object { $_ -notin $Available })
    if ($unknown.Count -gt 0) {
        throw "Unknown $Kind value: $($unknown -join ', ')"
    }

    return @($Requested | Select-Object -Unique)
}

function New-PPDevTemplateAction {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$DestinationPath,
        [Parameter(Mandatory)][string]$TargetRoot
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "PPDevStandard template is missing: $SourcePath"
    }

    [pscustomobject]@{
        Source = $SourcePath
        Destination = $DestinationPath
        RelativeDestination = [System.IO.Path]::GetRelativePath($TargetRoot, $DestinationPath)
    }
}

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$targetRoot = (Resolve-Path -LiteralPath $TargetPath).Path
$cataloguePath = Join-Path $repositoryRoot 'profiles\capabilities.json'
$validatorPath = Join-Path $PSScriptRoot 'validate-catalogue.ps1'

. $validatorPath
$catalogue = Get-PPDevCatalogue -Path $cataloguePath
$selectedClients = Resolve-PPDevSelection -Requested $Client -Available @($catalogue.clients.id) -Kind 'Client'
$selectedCapabilities = Resolve-PPDevSelection -Requested $Capability -Available @($catalogue.capabilities.id) -Kind 'Capability'

$templateRoot = Join-Path $repositoryRoot 'templates\project'
$actions = [System.Collections.Generic.List[object]]::new()

if (@($selectedClients | Where-Object { $_ -in @('claude-code', 'github-copilot-cli') }).Count -gt 0) {
    $actions.Add((New-PPDevTemplateAction -SourcePath (Join-Path $templateRoot '.mcp.json') -DestinationPath (Join-Path $targetRoot '.mcp.json') -TargetRoot $targetRoot))
}

if ($selectedClients -contains 'codex') {
    $codexTemplateName = if ($selectedCapabilities -contains 'canvas-apps') { 'config.pac-canvas.toml' } else { 'config.pac.toml' }
    $actions.Add((New-PPDevTemplateAction -SourcePath (Join-Path $templateRoot ".codex\$codexTemplateName") -DestinationPath (Join-Path $targetRoot '.codex\config.toml') -TargetRoot $targetRoot))
}

$actions.Add((New-PPDevTemplateAction -SourcePath (Join-Path $templateRoot 'AGENTS.md') -DestinationPath (Join-Path $targetRoot 'AGENTS.md') -TargetRoot $targetRoot))
$actions.Add((New-PPDevTemplateAction -SourcePath (Join-Path $repositoryRoot 'docs\AI_DEVELOPMENT_TOOLING.md') -DestinationPath (Join-Path $targetRoot 'docs\AI_DEVELOPMENT_TOOLING.md') -TargetRoot $targetRoot))

Write-Output "対象: $targetRoot"
Write-Output "クライアント: $($selectedClients -join ', ')"
Write-Output "機能: $($selectedCapabilities -join ', ')"
if (-not $Apply) {
    Write-Output 'モード: プレビュー（ファイルは作成しません）'
}

foreach ($action in $actions) {
    if (Test-Path -LiteralPath $action.Destination) {
        Write-Output "manual merge required: $($action.RelativeDestination)"
        continue
    }

    if (-not $Apply) {
        Write-Output "would create: $($action.RelativeDestination)"
        continue
    }

    $parentDirectory = Split-Path -Parent $action.Destination
    $null = New-Item -ItemType Directory -Path $parentDirectory -Force
    Copy-Item -LiteralPath $action.Source -Destination $action.Destination
    Write-Output "created: $($action.RelativeDestination)"
}
