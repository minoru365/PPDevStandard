# PPDevStandard

PPDevStandard is a **standalone Power Platform AI development overlay** for
Codex, Claude Code, and GitHub Copilot CLI. It does not fork or duplicate
product skills. Instead, it records which upstream tools to use, how each
client connects to them, and the safety and verification rules that make the
same development approach repeatable across projects.

## What PPDevStandard owns

| Layer | Owner | Responsibility |
| --- | --- | --- |
| Product skills and plugins | Upstream / official publishers | Product implementation and release updates |
| PPDevStandard | minoru365 | Capability catalogue, client compatibility, safe operating rules, templates, doctor, and canary |
| Project repository | Project team | Source of truth, Solution, YAML, flow definitions, CI/CD, and production approvals |

Use upstream sources directly:

- [GeekPower CodeAppsDevelopmentStandard](https://github.com/geekfujiwara/CodeAppsDevelopmentStandard)
- [Microsoft Power Platform Skills](https://github.com/microsoft/power-platform-skills)
- [Microsoft Dataverse Skills](https://github.com/microsoft/Dataverse-skills)
- [Microsoft Copilot Studio Skills](https://github.com/microsoft/skills-for-copilot-studio)
- [Microsoft Power CAT Skills](https://github.com/microsoft/power-cat-skills)

## Capability catalogue

| Capability | Upstream implementation | PPDevStandard adds |
| --- | --- | --- |
| Canvas Apps | Canvas Authoring MCP and `.pa.yaml` tooling | Client coverage, prerequisite checks, and Git-based promotion rule |
| Power Automate / FlowAgent | Official FlowAgent plugin and MCP | Stopped-flow default, preflight boundary, and promotion rule |
| Dataverse | Specialist skills, MCP, PAC CLI, and SDKs | Read-by-default boundary and approval gates |
| Copilot Studio | YAML authoring, validation, and evaluation skills | Client compatibility and cloud-change approval gate |
| Power CAT | Overflow and Code Apps / Pro-Code evaluation | Adopted-tool inventory and review evidence rule |

The complete, machine-readable catalogue is
[`profiles/capabilities.json`](./profiles/capabilities.json). It lists the
source, package identifier, prerequisites, client coverage, and verification
boundary for every capability.

## Supported clients

| Client | Delivery model | Use PPDevStandard for |
| --- | --- | --- |
| Codex | Developer-profile skills and MCP | Capability inventory, safe local checks, and project overlay |
| Claude Code | Official plugin marketplaces and MCP | Same capability and safety policy |
| GitHub Copilot CLI | Official plugin marketplaces and MCP | Same capability and safety policy |

Client installation and tenant authentication are intentionally local. This
repository never stores tenant URLs, accounts, tokens, authentication caches,
or user-specific MCP settings.

## Start safely

Run the doctor before changing a development environment. It checks declared
local prerequisites and reports MCP readiness without printing connection
details.

```powershell
pwsh -NoProfile -File scripts/doctor.ps1 -Client codex -Capability all
```

Run the canary to review catalogue coverage and the manual verification needed
for each capability. It does not fetch, install, authenticate, or change a
cloud environment.

```powershell
pwsh -NoProfile -File scripts/canary.ps1
```

## Two-lane operating model

### 探索・試作

Use MCP and AI skills to create and validate new, temporary development assets:
Canvas Apps, flows, Copilot Studio agents, or Dataverse test assets. Do not
replace, delete, publish, or alter managed assets in this lane.

### 採用・運用

When work is shared, long-lived, multi-environment, business-affecting, or
changes data/security, promote it to Git-managed source: Python, Solution,
YAML, version-controlled Canvas artifacts, and project CI/CD. Review the
diff before applying it.

Existing assets, publish, deletion, security roles, environment settings,
Solution import, and production changes always require explicit approval.

## Agent 365

Agent 365 is experimental and disabled by default. Any activation requires a
separate human review of Frontier/licensing, Azure, identity, permissions, data
classification, audit, cost, activation, and retirement.

## Updating upstream tools

Update upstream skills and plugins through their original publishers. Then
update the relevant catalogue record and run doctor/canary in a development
environment before adopting the change in a project. PPDevStandard does not
copy upstream source code, so upstream updates do not create fork-merge work.
