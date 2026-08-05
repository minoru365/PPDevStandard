[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$cataloguePath = Join-Path $repositoryRoot 'profiles\capabilities.json'
$readmePath = Join-Path $repositoryRoot 'README.md'

if (-not (Test-Path -LiteralPath $cataloguePath)) {
    throw 'Expected profiles/capabilities.json to exist.'
}

if (-not (Test-Path -LiteralPath $readmePath)) {
    throw 'Expected README.md to exist.'
}

$catalogue = Get-Content -LiteralPath $cataloguePath -Raw | ConvertFrom-Json -Depth 20
if ($catalogue.schemaVersion -ne 1) {
    throw 'Catalogue schemaVersion must be 1.'
}

$requiredClients = @('codex', 'claude-code', 'github-copilot-cli')
$clientIds = @($catalogue.clients | ForEach-Object { $_.id })
foreach ($clientId in $requiredClients) {
    if ($clientId -notin $clientIds) {
        throw "Catalogue is missing client '$clientId'."
    }
}

$requiredCapabilities = @(
    'canvas-apps',
    'power-automate-flowagent',
    'dataverse',
    'copilot-studio',
    'power-cat'
)
$capabilityIds = @($catalogue.capabilities | ForEach-Object { $_.id })
foreach ($capabilityId in $requiredCapabilities) {
    if ($capabilityId -notin $capabilityIds) {
        throw "Catalogue is missing capability '$capabilityId'."
    }
}

$agent365 = @($catalogue.profiles | Where-Object { $_.id -eq 'agent365' })
if ($agent365.Count -ne 1 -or $agent365[0].maturity -ne 'experimental' -or $agent365[0].default) {
    throw 'Agent 365 must remain experimental and disabled by default.'
}

foreach ($capability in $catalogue.capabilities) {
    if ([string]::IsNullOrWhiteSpace($capability.source.url) -or $capability.source.url -notmatch '^https://') {
        throw "Capability '$($capability.id)' must have an HTTPS source URL."
    }

    $coveredClients = @($capability.clientSupport | ForEach-Object { $_.clientId })
    foreach ($clientId in $requiredClients) {
        if ($clientId -notin $coveredClients) {
            throw "Capability '$($capability.id)' must declare support status for '$clientId'."
        }
    }
}

$readme = Get-Content -LiteralPath $readmePath -Raw
foreach ($requiredText in @('Canvas Apps', 'FlowAgent', 'Dataverse', 'Copilot Studio', 'Power CAT', '探索・試作', '採用・運用')) {
    if ($readme -notmatch [regex]::Escape($requiredText)) {
        throw "README.md must include '$requiredText'."
    }
}

$sensitivePattern = '(?i)(access[_-]?token|client[_-]?secret|password\s*[:=]|\.crm\.dynamics\.com|make\.powerapps\.com/)'
foreach ($artifact in @($cataloguePath, $readmePath)) {
    if ((Get-Content -LiteralPath $artifact -Raw) -match $sensitivePattern) {
        throw "Sensitive or tenant-specific configuration is not allowed in '$artifact'."
    }
}
