# Microsoft Learn MCP Knowledge Layer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make current Microsoft Learn documentation a standard, read-only knowledge source in every initialized Power Platform project.

**Architecture:** Add the public Microsoft Learn MCP endpoint to the existing client configuration templates, without credentials or tenant-specific values. Record its distinct role in the capability catalogue and project guide: Learn MCP grounds product knowledge; PAC and product MCPs operate on local or tenant context. Extend the PowerShell regression test to enforce the endpoint and prevent a future template change from silently removing it.

**Tech Stack:** JSON capability catalogue, TOML and JSON MCP configuration templates, Markdown guides, PowerShell regression tests.

## Global Constraints

- Use only `https://learn.microsoft.com/api/mcp` for the Microsoft Learn MCP endpoint.
- Treat Microsoft Learn MCP as read-only, public, and free of credentials or tenant URLs.
- Keep Dataverse MCP environment-specific and user-local; do not add a Dataverse endpoint to shared templates.
- Preserve PAC MCP and Canvas Authoring MCP configuration and existing initialization behavior.
- Do not install plugins, authenticate, or connect to a tenant during verification.

---

### Task 1: Lock the knowledge-source contract with regression tests

**Files:**
- Modify: `tests/verify-overlay.ps1`

**Interfaces:**
- Consumes: `templates/project/.mcp.json`, `templates/project/.codex/config.pac.toml`, `templates/project/.codex/config.pac-canvas.toml`, `profiles/capabilities.json`, and `docs/AI_DEVELOPMENT_TOOLING.md`.
- Produces: failing assertions that require the Learn endpoint, a knowledge-source catalogue entry, and the guide's routing rule.

- [x] **Step 1: Write the failing test**

Add assertions that the shared JSON template has `pac-cli` and `microsoft-learn`, that both Codex templates contain the Learn URL, that the catalogue declares `microsoft-learn-mcp`, and that the guide states `Microsoft Learn MCP` and `公式知識`.

- [x] **Step 2: Run the test to verify it fails**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: FAIL because the Learn endpoint and catalogue entry do not exist yet.

- [x] **Step 3: Add the minimal configuration and documentation**

Update the templates, catalogue, README, and project guide only as required by the failing assertions. Do not add authentication, install, or tenant configuration.

- [x] **Step 4: Run the test to verify it passes**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: PASS with no tenant access.

### Task 2: Describe routing and optionality for users

**Files:**
- Modify: `README.md`
- Modify: `docs/AI_DEVELOPMENT_TOOLING.md`
- Modify: `templates/project/AGENTS.md`
- Modify: `profiles/capabilities.json`

**Interfaces:**
- Consumes: the Learn MCP entry and templates created in Task 1.
- Produces: a consistent statement that Learn MCP is the standard source for current public Microsoft documentation and that tenant-specific MCPs remain optional local connections.

- [x] **Step 1: Write the failing test**

Use the Task 1 guide and catalogue assertions; they must fail until all routing text and catalogue data are present.

- [x] **Step 2: Run the test to verify it fails**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: FAIL until the source role and routing rule are documented.

- [x] **Step 3: Write the minimal documentation**

Describe when to use Learn MCP, when it is insufficient, and the required restart/new-session check. Add no unrelated release-note or Azure MCP server.

- [x] **Step 4: Run full verification**

Run: `pwsh -NoProfile -File scripts/validate-catalogue.ps1; pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: both commands PASS; no network, authentication, tenant access, or installation occurs.
