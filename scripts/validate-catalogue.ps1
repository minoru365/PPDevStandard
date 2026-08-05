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
    $capabilities = @($catalogue.capabilities)
    $requiredClients = @('codex', 'claude-code', 'github-copilot-cli')
    $requiredCapabilities = @('canvas-apps', 'power-automate-flowagent', 'dataverse', 'copilot-studio', 'power-cat')

    if (@($clients.id | Select-Object -Unique).Count -ne $clients.Count) {
        throw 'Client IDs must be unique.'
    }

    if (@($profiles.id | Select-Object -Unique).Count -ne $profiles.Count) {
        throw 'Profile IDs must be unique.'
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

    foreach ($capability in $capabilities) {
        if ([string]::IsNullOrWhiteSpace($capability.source.url) -or $capability.source.url -notmatch '^https://') {
            throw "Capability '$($capability.id)' must declare an HTTPS source URL."
        }

        if (@($capability.prerequisiteCommands).Count -eq 0) {
            throw "Capability '$($capability.id)' must declare at least one local prerequisite command."
        }

        foreach ($requiredClient in $requiredClients) {
            if ($requiredClient -notin @($capability.clientSupport.clientId)) {
                throw "Capability '$($capability.id)' must declare '$requiredClient' support status."
            }
        }
    }

    $catalogue
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-PPDevCatalogue -Path $Path
}
