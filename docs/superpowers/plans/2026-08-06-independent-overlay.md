# Independent PPDevStandard Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans for this compact plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standalone PPDevStandard repository that references upstream tools and owns only client compatibility, safety policy, and feature-level verification.

**Architecture:** `profiles/capabilities.json` is the single machine-readable catalogue for Canvas Apps, FlowAgent, Dataverse, Copilot Studio, and Power CAT. README and the PowerShell validator/doctor/canary consume that catalogue; no upstream skill, plugin, or MCP implementation is copied into this repository.

**Tech Stack:** Markdown, JSON, PowerShell 7, GitHub repository links.

## Global Constraints

- Do not vendor or fork upstream product-skill source files.
- Record source repository URLs and package identifiers, never tenant URLs, accounts, tokens, authentication caches, or user-specific MCP settings.
- `doctor` and default `canary` are read-only and make no network, authentication, installation, or cloud calls.
- `-Apply`, tenant writes, publish, Solution import, and production actions are outside this repository's automation.
- Agent 365 stays experimental and default-off.
- Existing upstream sources are linked, not copied: Geek standard, Microsoft Power Platform Skills, Dataverse Skills, Copilot Studio Skills, and Power CAT.

---

### Task 1: Create the overlay catalogue and README

**Files:**
- Create: `profiles/capabilities.json`
- Create: `README.md`
- Create: `tests/verify-overlay.ps1`

**Interfaces:**
- Produces a schema-versioned catalogue with five capability IDs: `canvas-apps`, `power-automate-flowagent`, `dataverse`, `copilot-studio`, and `power-cat`.
- Each capability declares an upstream source URL, client coverage, prerequisites, exploration rule, and promotion rule.

- [ ] Write `tests/verify-overlay.ps1` first. It must require all five capability IDs, client IDs `codex`, `claude-code`, and `github-copilot-cli`, Agent 365 experimental/default false, and README terms `Canvas Apps`, `FlowAgent`, `Dataverse`, `Copilot Studio`, and `Power CAT`.
- [ ] Run `pwsh -NoProfile -File tests/verify-overlay.ps1`; it must fail because the catalogue and README do not exist.
- [ ] Create `profiles/capabilities.json` with schema version 1, update date, the three clients, `power-platform-core` supported/default true, `agent365` experimental/default false, and the five capability records. Use only source URLs, package identifiers, generic prerequisites, and the approved two-lane rules.
- [ ] Create a new PPDevStandard-first README: purpose, upstream/overlay responsibility table, capability matrix, client coverage, safe `doctor`/`canary` usage, two-lane boundary, upstream update process, and links. Do not copy upstream manuals.
- [ ] Extend the test to assert source URLs are `https`, required rules are present, and no sensitive configuration patterns are in the catalogue or README.
- [ ] Run `pwsh -NoProfile -File tests/verify-overlay.ps1`; expected pass.
- [ ] Commit with `feat: add PPDevStandard capability catalogue`.

### Task 2: Implement feature-aware local diagnosis

**Files:**
- Create: `scripts/validate-catalogue.ps1`
- Create: `scripts/doctor.ps1`
- Modify: `tests/verify-overlay.ps1`

**Interfaces:**
- `Get-PPDevCatalogue [-Path <path>]` validates and returns the catalogue.
- `doctor.ps1 -Client <client> [-Capability <id|all>] [-SkipMcpConfigCheck]` returns 0 when local prerequisites are present, 1 when a declared prerequisite is absent, and reports MCP readiness only as `manual-verification-required` unless a safe local command can establish it.

- [ ] Add tests that first require both scripts, then reject `Connect-`, `az login`, `Invoke-WebRequest`, `Invoke-RestMethod`, `npm install`, `plugin install`, `git push`, and `$env:` from the scripts.
- [ ] Run the test; expected failure because scripts do not exist.
- [ ] Implement `validate-catalogue.ps1` to validate schema version, unique client/capability/profile IDs, all required capabilities, one supported default profile, and Agent 365 experimental/default false.
- [ ] Implement `doctor.ps1` using only `Get-Command` and suppressed `--version` invocations for each capability's declared prerequisites. It must output client/capability/status labels, no endpoints or environment values, and never execute a plugin/MCP command.
- [ ] Extend tests with a temporary catalogue whose prerequisite command is deliberately unavailable; assert doctor returns 1 and does not produce sensitive output.
- [ ] Run `pwsh -NoProfile -File tests/verify-overlay.ps1` and `pwsh -NoProfile -File scripts/doctor.ps1 -Client codex -Capability all -SkipMcpConfigCheck`; record expected local missing prerequisites without installing anything.
- [ ] Commit with `feat: add capability-aware doctor`.

### Task 3: Add read-only canary and project safety overlay

**Files:**
- Create: `scripts/canary.ps1`
- Create: `templates/AGENTS.power-platform.md`
- Modify: `tests/verify-overlay.ps1`

**Interfaces:**
- `canary.ps1 [-CataloguePath <path>]` validates the catalogue and reports every capability's upstream source, client coverage, and manual/automated verification boundary without network access.
- `templates/AGENTS.power-platform.md` is a copyable project overlay, not a replacement for a project’s existing instructions.

- [ ] Add tests that require canary default output to include all five capabilities, reject network/auth/install/push patterns, and require the template’s `探索・試作` / `採用・運用`, existing-asset, and approval rules.
- [ ] Run the test; expected failure because canary/template do not exist.
- [ ] Implement `canary.ps1` by calling `Get-PPDevCatalogue` and writing a concise read-only capability report. It must not fetch source repositories or inspect tenant configuration.
- [ ] Write the AGENTS overlay with development-environment exploration permission, Git-managed promotion rule, read-by-default Dataverse rule, stopped FlowAgent flow rule, and explicit approval requirements for existing assets, publish, deletion, roles, environments, imports, and production.
- [ ] Run the full test, `pwsh -NoProfile -File scripts/canary.ps1`, and `git diff --check`; expected pass and no status change from canary.
- [ ] Commit with `feat: add overlay canary and safety template`.

### Task 4: Publish the independent overlay

**Files:**
- Verify: all repository files

- [ ] Run `pwsh -NoProfile -File tests/verify-overlay.ps1`, doctor in read-only mode, canary, `git diff --check`, and `git status --short`.
- [ ] Push only `main` of `minoru365/PPDevStandard` after all checks pass.
- [ ] Verify the repository is independent (no fork parent), public, and contains no upstream source copies or sensitive values.
- [ ] Record the independent-overlay decision in the Vault note and same-day daily note.
