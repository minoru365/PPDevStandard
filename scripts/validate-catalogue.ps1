[CmdletBinding()]
param(
    [string]$Path = (Join-Path $PSScriptRoot '..\profiles\capabilities.json')
)

$ErrorActionPreference = 'Stop'

function Get-PPDevCatalogue {
    [CmdletBinding()]
    param(
        [string]$Path = (Join-Path $PSScriptRoot '..\profiles\capabilities.json')
    )

    try {
        $catalogue = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 20
    }
    catch {
        throw "Unable to load the PPDevStandard catalogue from '$Path'."
    }

    if ($catalogue.schemaVersion -ne 1) {
        throw 'Catalogue schemaVersion must be 1.'
    }

    $clients = @($catalogue.clients)
    $profiles = @($catalogue.profiles)
    $knowledgeSources = @($catalogue.knowledgeSources)
    $capabilities = @($catalogue.capabilities)
    $requiredClients = @('codex', 'claude-code', 'github-copilot-cli')
    $requiredCapabilities = @('canvas-apps', 'code-apps', 'power-automate-flowagent', 'dataverse', 'copilot-studio', 'power-cat')

    if (@($clients.id | Select-Object -Unique).Count -ne $clients.Count) {
        throw 'Client IDs must be unique.'
    }

    if (@($profiles.id | Select-Object -Unique).Count -ne $profiles.Count) {
        throw 'Profile IDs must be unique.'
    }

    if (@($knowledgeSources.id | Select-Object -Unique).Count -ne $knowledgeSources.Count) {
        throw 'Knowledge source IDs must be unique.'
    }

    if (@($capabilities.id | Select-Object -Unique).Count -ne $capabilities.Count) {
        throw 'Capability IDs must be unique.'
    }

    foreach ($requiredClient in $requiredClients) {
        if ($requiredClient -notin @($clients.id)) {
            throw "Required client '$requiredClient' is missing."
        }
    }

    foreach ($requiredCapability in $requiredCapabilities) {
        if ($requiredCapability -notin @($capabilities.id)) {
            throw "Required capability '$requiredCapability' is missing."
        }
    }

    $defaultSupportedProfiles = @($profiles | Where-Object { $_.maturity -eq 'supported' -and $_.default })
    if ($defaultSupportedProfiles.Count -ne 1) {
        throw 'Exactly one supported profile must be the default.'
    }

    $agent365 = @($profiles | Where-Object { $_.id -eq 'agent365' })
    if ($agent365.Count -ne 1 -or $agent365[0].maturity -ne 'experimental' -or $agent365[0].default) {
        throw 'Agent 365 must remain experimental and disabled by default.'
    }

    $microsoftLearnMcp = @($knowledgeSources | Where-Object { $_.id -eq 'microsoft-learn-mcp' })
    if ($microsoftLearnMcp.Count -ne 1) {
        throw 'Exactly one Microsoft Learn MCP knowledge source must be declared.'
    }

    foreach ($knowledgeSource in $knowledgeSources) {
        foreach ($field in @('id', 'name', 'endpoint', 'role', 'routingRule', 'adoptionRule')) {
            if ([string]::IsNullOrWhiteSpace($knowledgeSource.$field)) {
                throw "Knowledge source '$($knowledgeSource.id)' must declare a non-empty '$field'."
            }
        }

        if ($knowledgeSource.endpoint -notmatch '^https://') {
            throw "Knowledge source '$($knowledgeSource.id)' must declare an HTTPS endpoint."
        }
    }

    if ($microsoftLearnMcp[0].endpoint -ne 'https://learn.microsoft.com/api/mcp' -or $microsoftLearnMcp[0].role -ne 'standard-read-only') {
        throw 'Microsoft Learn MCP must use its official read-only endpoint.'
    }

    foreach ($client in $clients) {
        $clientPrerequisites = @($client.prerequisiteCommands)
        if (@($clientPrerequisites.name | Select-Object -Unique).Count -ne $clientPrerequisites.Count) {
            throw "Client '$($client.id)' prerequisite command names must be unique."
        }

        foreach ($prerequisite in $clientPrerequisites) {
            if ([string]::IsNullOrWhiteSpace($prerequisite.name)) {
                throw "Client '$($client.id)' prerequisites must declare a command name."
            }

            if ($null -ne $prerequisite.minimumMajor -and ($prerequisite.minimumMajor -isnot [long] -or $prerequisite.minimumMajor -lt 1)) {
                throw "Client '$($client.id)' prerequisite '$($prerequisite.name)' must declare a positive integer minimumMajor."
            }
        }
    }

    foreach ($capability in $capabilities) {
        if ([string]::IsNullOrWhiteSpace($capability.source.url) -or $capability.source.url -notmatch '^https://') {
            throw "Capability '$($capability.id)' must declare an HTTPS source URL."
        }

        $capabilityPrerequisites = @($capability.prerequisiteCommands)
        if ($capabilityPrerequisites.Count -eq 0) {
            throw "Capability '$($capability.id)' must declare at least one local prerequisite command."
        }

        if (@($capabilityPrerequisites.name | Select-Object -Unique).Count -ne $capabilityPrerequisites.Count) {
            throw "Capability '$($capability.id)' prerequisite command names must be unique."
        }

        foreach ($prerequisite in $capabilityPrerequisites) {
            if ([string]::IsNullOrWhiteSpace($prerequisite.name)) {
                throw "Capability '$($capability.id)' prerequisites must declare a command name."
            }

            if ($null -ne $prerequisite.minimumMajor -and ($prerequisite.minimumMajor -isnot [long] -or $prerequisite.minimumMajor -lt 1)) {
                throw "Capability '$($capability.id)' prerequisite '$($prerequisite.name)' must declare a positive integer minimumMajor."
            }
        }

        foreach ($requiredClient in $requiredClients) {
            if ($requiredClient -notin @($capability.clientSupport.clientId)) {
                throw "Capability '$($capability.id)' must declare '$requiredClient' support status."
            }
        }

        # 既知の落とし穴は台帳の一級市民として扱う。未記録なら [] を明示させ、
        # 「書き忘れ」と「まだ無い」を区別できるようにする。
        if ($capability.PSObject.Properties.Name -notcontains 'knownPitfalls') {
            throw "Capability '$($capability.id)' must declare a knownPitfalls array (use [] when none are recorded yet)."
        }

        foreach ($pitfall in @($capability.knownPitfalls)) {
            foreach ($pitfallField in @('trigger', 'symptom', 'resolution')) {
                if ([string]::IsNullOrWhiteSpace($pitfall.$pitfallField)) {
                    throw "Capability '$($capability.id)' knownPitfalls entries must declare a non-empty '$pitfallField'."
                }
            }
        }
    }

    $catalogue
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-PPDevCatalogue -Path $Path
}
