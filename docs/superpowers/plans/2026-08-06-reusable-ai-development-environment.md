# 再利用可能な AI 開発環境 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新規の Power Platform リポジトリに、資格情報を含まない共通 AI 開発環境を安全に適用できるようにする。

**Architecture:** `profiles/capabilities.json` を機械可読な選択元とし、初期化スクリプトがクライアント・機能に応じてテンプレートを対象リポジトリへコピーする。ローカルの前提確認と、クライアント別の公式導入・機能ルーティングは独立したスクリプトと文書に分ける。上流実装・テナント・認証情報・業務成果物は扱わない。

**Tech Stack:** PowerShell 7、JSON、Markdown、既存 `tests/verify-overlay.ps1`

## Global Constraints

- 上流のスキル、プラグイン、MCP 実装はコピーしない。
- テナント URL、トークン、アカウント、認証キャッシュ、Dataverse 接続 URL を生成・保存・出力しない。
- 初期化は既定でプレビューとし、`-Apply` 指定時だけ明示した既存ディレクトリへ書き込む。
- 同名の既存ファイルは上書きせず、手動マージを報告する。
- プラグイン導入、認証、ネットワーク、クラウド変更をスクリプトで実行しない。
- `canary.ps1` は削除し、`doctor.ps1` は分かりやすい `check-prerequisites.ps1` に置き換える。

---

### Task 1: 台帳と共通テンプレートを再現可能にする

**Files:**
- Modify: `profiles/capabilities.json`
- Create: `templates/project/.mcp.json`
- Create: `templates/project/.codex/config.pac.toml`
- Create: `templates/project/.codex/config.pac-canvas.toml`
- Create: `templates/project/AGENTS.md`
- Create: `docs/AI_DEVELOPMENT_TOOLING.md`
- Delete: `templates/AGENTS.power-platform.md`

**Interfaces:**
- Consumes: capability IDs `canvas-apps`, `power-automate-flowagent`, `dataverse`, `copilot-studio`, `power-cat`
- Produces: credentials-free source templates and client routing documentation for Task 2

- [ ] **Step 1: Define the expected static artifacts in `tests/verify-overlay.ps1`**

Add checks for all five template/document paths. Assert that `.mcp.json` declares only `pac-cli`, the PAC template contains `Microsoft.PowerApps.CLI.Tool`, the PAC-and-Canvas template contains `Microsoft.PowerApps.CanvasAuthoring.McpServer`, and all artifacts reject the existing sensitive-value regex.

- [ ] **Step 2: Run the test to verify it fails**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: failure because the new templates and routing document do not exist.

- [ ] **Step 3: Add the minimal templates and routing documentation**

Use this PAC MCP JSON template:

```json
{
  "mcpServers": {
    "pac-cli": {
      "type": "stdio",
      "command": "dnx",
      "args": ["Microsoft.PowerApps.CLI.Tool", "--yes", "copilot", "mcp", "--run"]
    }
  }
}
```

Document official installation/verification links and the five capability routing rules. State that Claude Code and GitHub Copilot CLI obtain Canvas MCP from the official Canvas Apps plugin, while Codex receives the Canvas template only when Canvas Apps is selected. Keep Dataverse URL and authentication only in user-local setup instructions.

- [ ] **Step 4: Run the test to verify it passes**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: pass.

### Task 2: 安全なプロジェクト初期化を実装する

**Files:**
- Create: `scripts/initialize-project.ps1`
- Modify: `tests/verify-overlay.ps1`

**Interfaces:**
- Consumes: `-TargetPath <existing directory>`, optional `-Client <codex|claude-code|github-copilot-cli>`, optional `-Capability <capability ID>`, optional `-Apply`
- Produces: planned action output, or selected templates at `<target>/.mcp.json`, `<target>/.codex/config.toml`, `<target>/AGENTS.md`, and `<target>/docs/AI_DEVELOPMENT_TOOLING.md`

- [ ] **Step 1: Add failing initialization tests**

Create a temporary directory in `tests/verify-overlay.ps1`. Invoke the script without `-Apply` and assert no target files exist. Invoke with `-Apply -Client codex -Capability canvas-apps` and assert the four target files exist and `config.toml` contains the Canvas MCP. Create a pre-existing target `AGENTS.md`, invoke with `-Apply`, and assert its contents are unchanged and output contains `manual merge required`.

- [ ] **Step 2: Run the test to verify it fails**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: failure because `initialize-project.ps1` does not exist.

- [ ] **Step 3: Implement `initialize-project.ps1`**

Require `-TargetPath` and reject non-directories. Resolve `all` client/capability selections from the catalogue. Build a list of source/destination pairs. Include `.mcp.json` when Claude Code or GitHub Copilot CLI is selected. Include Codex `config.toml`, choosing the Canvas variant only for `canvas-apps`. Always include `AGENTS.md` and `docs/AI_DEVELOPMENT_TOOLING.md` for a valid initialization.

For each pair, output `would create`, `created`, or `manual merge required`. Without `-Apply`, do not create directories or files. With `-Apply`, create only required parent directories and copy only destinations that do not exist. Do not invoke networking, authentication, package installation, Git, or cloud commands.

- [ ] **Step 4: Run the test to verify it passes**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: pass, including preview, apply, selection, and no-overwrite assertions.

### Task 3: 前提確認を分かりやすくし、誤解を招く canary を除去する

**Files:**
- Create: `scripts/check-prerequisites.ps1`
- Delete: `scripts/doctor.ps1`
- Delete: `scripts/canary.ps1`
- Modify: `tests/verify-overlay.ps1`
- Modify: `README.md`

**Interfaces:**
- Consumes: `-Client <codex|claude-code|github-copilot-cli>`, optional `-Capability <capability ID>`, optional `-CataloguePath`
- Produces: client CLI and selected local prerequisites status; exits 1 only when a required local command is missing

- [ ] **Step 1: Change the test to expect `check-prerequisites.ps1` and no canary**

Replace every `doctor.ps1` and `canary.ps1` expectation with `check-prerequisites.ps1`. Reuse the temporary-catalogue test to assert a missing prerequisite returns 1 and reports `missing`. Assert the script contains none of `Connect-`, `az login`, `Invoke-WebRequest`, `Invoke-RestMethod`, `npm install`, `plugin install`, `git push`, `git fetch`, or `$env:`. Assert the removed scripts do not exist.

- [ ] **Step 2: Run the test to verify it fails**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: failure because the renamed script is absent and old scripts remain.

- [ ] **Step 3: Implement the renamed check and simplify README usage**

Preserve the existing local command check, but print a human-readable title: `開発環境の前提確認`. For each selected capability, print the selected client, required local commands, and `手動確認: 公式プラグインと MCP 接続`. Do not call it a connection or plugin verification. Remove canary instructions from README and replace the old doctor example with:

```powershell
pwsh -NoProfile -File scripts/check-prerequisites.ps1 -Client codex -Capability all
```

State that this check only verifies local command availability; plugin installation and MCP connection follow the routing document.

- [ ] **Step 4: Run the test to verify it passes**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: pass.

### Task 4: 全体検証と利用者向け仕上げ

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-08-06-reusable-ai-development-environment-design.md`

**Interfaces:**
- Consumes: Tasks 1–3 artifacts
- Produces: short onboarding flow and the final design record

- [ ] **Step 1: Update README to show the three-step onboarding flow**

Show only: clone/open PPDevStandard, preview or apply initialization, run `check-prerequisites`, then follow the generated routing document for official plugin installation and local Dataverse connection. Link to the routing document rather than copying lengthy policy text into README.

- [ ] **Step 2: Align the design record with implemented paths**

Replace any design wording that differs from actual parameter names, output strings, or template paths.

- [ ] **Step 3: Run all mechanical gates**

Run:

```powershell
pwsh -NoProfile -File tests/verify-overlay.ps1
git diff --check
git status --short
```

Expected: overlay test passes, no whitespace errors, and only intended PPDevStandard files are modified.

- [ ] **Step 4: Review the final diff against the global constraints**

Confirm no credentials, tenant URL, upstream implementation, DecisionSupport-specific source, network command, authentication command, installation command, or overwrite path was added.
