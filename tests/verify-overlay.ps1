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
foreach ($requiredText in @('Canvas Apps', 'FlowAgent', 'Dataverse', 'Copilot Studio', 'Power CAT')) {
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

$prerequisiteCheckPath = Join-Path $repositoryRoot 'scripts\check-prerequisites.ps1'
if (-not (Test-Path -LiteralPath $prerequisiteCheckPath)) {
    throw 'Expected scripts/check-prerequisites.ps1 to exist.'
}

$validator = Get-Content -LiteralPath $validatorPath -Raw
$prerequisiteCheck = Get-Content -LiteralPath $prerequisiteCheckPath -Raw
$forbiddenAutomation = 'Connect-|az login|Invoke-WebRequest|Invoke-RestMethod|npm install|plugin install|git push|\$env:'
foreach ($scriptArtifact in @($validator, $prerequisiteCheck)) {
    if ($scriptArtifact -match $forbiddenAutomation) {
        throw 'Catalogue validation and prerequisite checks must not authenticate, install, push, or read environment values.'
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
    $prerequisiteOutput = @(& $pwshExecutable -NoProfile -File $prerequisiteCheckPath -Client codex -Capability canvas-apps -CataloguePath $temporaryCataloguePath 2>&1 | ForEach-Object { $_.ToString() })
    if ($LASTEXITCODE -ne 1) {
        throw 'check-prerequisites must return 1 when a declared prerequisite is missing.'
    }

    if ($prerequisiteOutput -notcontains "prerequisite 'ppdevstandard-command-not-installed': missing") {
        throw 'check-prerequisites must report the missing declared prerequisite.'
    }

    if (($prerequisiteOutput -join "`n") -match $sensitivePattern) {
        throw 'check-prerequisites must not print sensitive or tenant-specific output.'
    }
}
finally {
    Remove-Item -LiteralPath $temporaryCataloguePath -Force -ErrorAction SilentlyContinue
}

foreach ($removedPath in @(
    (Join-Path $repositoryRoot 'scripts\doctor.ps1'),
    (Join-Path $repositoryRoot 'scripts\canary.ps1'),
    (Join-Path $repositoryRoot 'templates\AGENTS.power-platform.md')
)) {
    if (Test-Path -LiteralPath $removedPath) {
        throw "Obsolete artifact '$removedPath' must not remain."
    }
}

$projectTemplateRoot = Join-Path $repositoryRoot 'templates\project'
$mcpTemplatePath = Join-Path $projectTemplateRoot '.mcp.json'
$codexPacTemplatePath = Join-Path $projectTemplateRoot '.codex\config.pac.toml'
$codexPacCanvasTemplatePath = Join-Path $projectTemplateRoot '.codex\config.pac-canvas.toml'
$projectAgentTemplatePath = Join-Path $projectTemplateRoot 'AGENTS.md'
$toolingGuidePath = Join-Path $repositoryRoot 'docs\AI_DEVELOPMENT_TOOLING.md'
foreach ($templatePath in @($mcpTemplatePath, $codexPacTemplatePath, $codexPacCanvasTemplatePath, $projectAgentTemplatePath, $toolingGuidePath)) {
    if (-not (Test-Path -LiteralPath $templatePath)) {
        throw "Expected template or guide '$templatePath' to exist."
    }

    if ((Get-Content -LiteralPath $templatePath -Raw) -match $sensitivePattern) {
        throw "Sensitive or tenant-specific configuration is not allowed in '$templatePath'."
    }
}

$mcpTemplate = Get-Content -LiteralPath $mcpTemplatePath -Raw | ConvertFrom-Json -Depth 10
if (@($mcpTemplate.mcpServers.PSObject.Properties.Name) -ne @('pac-cli')) {
    throw 'The shared .mcp.json template must declare only pac-cli.'
}

if ((Get-Content -LiteralPath $codexPacTemplatePath -Raw) -notmatch [regex]::Escape('Microsoft.PowerApps.CLI.Tool')) {
    throw 'The Codex PAC template must declare Microsoft.PowerApps.CLI.Tool.'
}

if ((Get-Content -LiteralPath $codexPacCanvasTemplatePath -Raw) -notmatch [regex]::Escape('Microsoft.PowerApps.CanvasAuthoring.McpServer')) {
    throw 'The Codex Canvas template must declare Microsoft.PowerApps.CanvasAuthoring.McpServer.'
}

if ((Get-Content -LiteralPath $toolingGuidePath -Raw) -match [regex]::Escape('initialize-project.ps1')) {
    throw 'The project tooling guide must not refer to the PPDevStandard initializer path.'
}

$initializerPath = Join-Path $repositoryRoot 'scripts\initialize-project.ps1'
if (-not (Test-Path -LiteralPath $initializerPath)) {
    throw 'Expected scripts/initialize-project.ps1 to exist.'
}

$initializationRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ppdevstandard-initialize-" + [guid]::NewGuid().ToString('N'))
try {
    $null = New-Item -ItemType Directory -Path $initializationRoot -Force
    $pwshExecutable = Join-Path $PSHOME $(if ($IsWindows) { 'pwsh.exe' } else { 'pwsh' })

    $previewOutput = @(& $pwshExecutable -NoProfile -File $initializerPath -TargetPath $initializationRoot -Client codex -Capability canvas-apps 2>&1 | ForEach-Object { $_.ToString() })
    if ($LASTEXITCODE -ne 0) {
        throw 'initialize-project preview must succeed.'
    }
    if (($previewOutput -join "`n") -notmatch [regex]::Escape('would create')) {
        throw 'initialize-project preview must report planned files.'
    }
    foreach ($previewPath in @('.codex\config.toml', 'AGENTS.md', 'docs\AI_DEVELOPMENT_TOOLING.md')) {
        if (Test-Path -LiteralPath (Join-Path $initializationRoot $previewPath)) {
            throw "initialize-project preview must not create '$previewPath'."
        }
    }

    $applyOutput = @(& $pwshExecutable -NoProfile -File $initializerPath -TargetPath $initializationRoot -Client codex -Capability canvas-apps -Apply 2>&1 | ForEach-Object { $_.ToString() })
    if ($LASTEXITCODE -ne 0) {
        throw 'initialize-project apply must succeed.'
    }
    foreach ($expectedPath in @('.codex\config.toml', 'AGENTS.md', 'docs\AI_DEVELOPMENT_TOOLING.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $initializationRoot $expectedPath))) {
            throw "initialize-project apply must create '$expectedPath'."
        }
    }
    if (Test-Path -LiteralPath (Join-Path $initializationRoot '.mcp.json')) {
        throw 'Codex-only initialization must not create .mcp.json.'
    }
    if ((Get-Content -LiteralPath (Join-Path $initializationRoot '.codex\config.toml') -Raw) -notmatch [regex]::Escape('Microsoft.PowerApps.CanvasAuthoring.McpServer')) {
        throw 'Canvas initialization must create the Canvas Authoring MCP configuration.'
    }

    $noCanvasTarget = Join-Path $initializationRoot 'no-canvas'
    $null = New-Item -ItemType Directory -Path $noCanvasTarget -Force
    $noCanvasOutput = @(& $pwshExecutable -NoProfile -File $initializerPath -TargetPath $noCanvasTarget -Client codex -Capability dataverse -Apply 2>&1 | ForEach-Object { $_.ToString() })
    if ($LASTEXITCODE -ne 0) {
        throw 'Non-Canvas Codex initialization must succeed.'
    }
    if ((Get-Content -LiteralPath (Join-Path $noCanvasTarget '.codex\config.toml') -Raw) -match [regex]::Escape('Microsoft.PowerApps.CanvasAuthoring.McpServer')) {
        throw 'Non-Canvas Codex initialization must not create the Canvas Authoring MCP configuration.'
    }

    $existingTarget = Join-Path $initializationRoot 'existing'
    $null = New-Item -ItemType Directory -Path $existingTarget -Force
    $existingAgentPath = Join-Path $existingTarget 'AGENTS.md'
    Set-Content -LiteralPath $existingAgentPath -Value 'project-specific instructions' -NoNewline
    $existingOutput = @(& $pwshExecutable -NoProfile -File $initializerPath -TargetPath $existingTarget -Client claude-code -Capability dataverse -Apply 2>&1 | ForEach-Object { $_.ToString() })
    if ($LASTEXITCODE -ne 0) {
        throw 'initialize-project must succeed when an existing file requires manual merge.'
    }
    if ((Get-Content -LiteralPath $existingAgentPath -Raw) -ne 'project-specific instructions') {
        throw 'initialize-project must not overwrite an existing AGENTS.md.'
    }
    if (($existingOutput -join "`n") -notmatch [regex]::Escape('manual merge required')) {
        throw 'initialize-project must report a manual merge requirement for an existing file.'
    }
    if (-not (Test-Path -LiteralPath (Join-Path $existingTarget '.mcp.json'))) {
        throw 'Claude Code initialization must create .mcp.json.'
    }
    if (Test-Path -LiteralPath (Join-Path $existingTarget '.codex\config.toml')) {
        throw 'Claude Code initialization must not create a Codex configuration file.'
    }
}
finally {
    Remove-Item -LiteralPath $initializationRoot -Recurse -Force -ErrorAction SilentlyContinue
}

$agentOverlay = Get-Content -LiteralPath $projectAgentTemplatePath -Raw
foreach ($requiredRule in @('探索・試作', '採用・運用', 'FlowAgent', '明示承認', '認証情報')) {
    if ($agentOverlay -notmatch [regex]::Escape($requiredRule)) {
        throw "Project AGENTS template must include '$requiredRule'."
    }
}
