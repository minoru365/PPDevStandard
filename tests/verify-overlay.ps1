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

$validatorPath = Join-Path $repositoryRoot 'scripts\validate-catalogue.ps1'
if (-not (Test-Path -LiteralPath $validatorPath)) {
    throw 'Expected scripts/validate-catalogue.ps1 to exist.'
}

$doctorPath = Join-Path $repositoryRoot 'scripts\doctor.ps1'
if (-not (Test-Path -LiteralPath $doctorPath)) {
    throw 'Expected scripts/doctor.ps1 to exist.'
}

$validator = Get-Content -LiteralPath $validatorPath -Raw
$doctor = Get-Content -LiteralPath $doctorPath -Raw
$forbiddenAutomation = 'Connect-|az login|Invoke-WebRequest|Invoke-RestMethod|npm install|plugin install|git push|\$env:'
foreach ($scriptArtifact in @($validator, $doctor)) {
    if ($scriptArtifact -match $forbiddenAutomation) {
        throw 'Catalogue validation and doctor must not authenticate, install, push, or read environment values.'
    }
}

$null = . $validatorPath
$validatedCatalogue = Get-PPDevCatalogue -Path $cataloguePath
if (@($validatedCatalogue.capabilities).Count -ne $requiredCapabilities.Count) {
    throw 'Get-PPDevCatalogue must return every declared capability.'
}

$temporaryCataloguePath = Join-Path ([System.IO.Path]::GetTempPath()) ("ppdevstandard-" + [guid]::NewGuid().ToString('N') + '.json')
try {
    $missingPrerequisiteCatalogue = Get-Content -LiteralPath $cataloguePath -Raw | ConvertFrom-Json -Depth 20
    $missingPrerequisiteCatalogue.capabilities[0].prerequisiteCommands = @('ppdevstandard-command-not-installed')
    $missingPrerequisiteCatalogue | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $temporaryCataloguePath -NoNewline

    $pwshExecutable = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
    $doctorOutput = @(& $pwshExecutable -NoProfile -File $doctorPath -Client codex -Capability canvas-apps -SkipMcpConfigCheck -CataloguePath $temporaryCataloguePath 2>&1 | ForEach-Object { $_.ToString() })
    if ($LASTEXITCODE -ne 1) {
        throw 'doctor must return 1 when a declared prerequisite is missing.'
    }

    if ($doctorOutput -notcontains "prerequisite 'ppdevstandard-command-not-installed': missing") {
        throw 'doctor must report the missing declared prerequisite.'
    }

    if (($doctorOutput -join "`n") -match $sensitivePattern) {
        throw 'doctor must not print sensitive or tenant-specific output.'
    }
}
finally {
    Remove-Item -LiteralPath $temporaryCataloguePath -Force -ErrorAction SilentlyContinue
}

$canaryPath = Join-Path $repositoryRoot 'scripts\canary.ps1'
if (-not (Test-Path -LiteralPath $canaryPath)) {
    throw 'Expected scripts/canary.ps1 to exist.'
}

$agentOverlayPath = Join-Path $repositoryRoot 'templates\AGENTS.power-platform.md'
if (-not (Test-Path -LiteralPath $agentOverlayPath)) {
    throw 'Expected templates/AGENTS.power-platform.md to exist.'
}

$canary = Get-Content -LiteralPath $canaryPath -Raw
if ($canary -match 'Connect-|az login|Invoke-WebRequest|Invoke-RestMethod|npm install|plugin install|git push|git fetch|\$env:') {
    throw 'canary must remain local and read-only.'
}

$pwshExecutable = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })
$canaryOutput = @(& $pwshExecutable -NoProfile -File $canaryPath 2>&1 | ForEach-Object { $_.ToString() })
if ($LASTEXITCODE -ne 0) {
    throw 'canary must succeed for the repository catalogue.'
}

foreach ($capabilityId in $requiredCapabilities) {
    if (($canaryOutput -join "`n") -notmatch [regex]::Escape($capabilityId)) {
        throw "canary must report capability '$capabilityId'."
    }
}

$agentOverlay = Get-Content -LiteralPath $agentOverlayPath -Raw
foreach ($requiredRule in @('探索・試作', '採用・運用', 'existing managed assets', 'stopped state', 'explicit approval')) {
    if ($agentOverlay -notmatch [regex]::Escape($requiredRule)) {
        throw "AGENTS overlay must include '$requiredRule'."
    }
}
