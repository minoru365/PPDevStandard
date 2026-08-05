# クロスクライアント開発ツール規約の抽出 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** DecisionSupport で確立した資格情報を含まないツール導入・安全運用の知識を、PPDevStandard の全クライアント向け成果物へ反映する。

**Architecture:** `profiles/capabilities.json` をクライアントと capability の最低バージョンを持つ唯一の台帳にする。`check-prerequisites.ps1` はその台帳を読んで、ローカルのコマンド有無と判定可能な最低メジャーバージョンだけを検査する。文書と overlay は、台帳にない認証情報を持たず、開発環境の手動有効化と安全な採用境界を伝える。

**Tech Stack:** JSON、PowerShell 7、Markdown、既存 `tests/verify-overlay.ps1`

## Global Constraints

- Canvas/PAC は .NET 10 以上、FlowAgent/Copilot Studio は Node.js 18 以上、GitHub Copilot CLI は Node.js 22 以上とする。
- ローカル検査は `Get-Command` と `--version` だけを使い、認証、ネットワーク、インストール、クラウド変更をしない。
- CLI のバージョン文字列を解析できないときは `not-checkable` と表示し、存在するコマンドを不足扱いにしない。
- FlowStudio と `mcs-assistant@copilot-studio-plugin` は標準構成に含めない。
- テナント URL、アカウント、トークン、認証キャッシュ、Dataverse 接続先、DecisionSupport 固有の資産を追加しない。
- `.mcp.json` と Codex MCP テンプレートは変更しない。
- コミット、プッシュ、導入、認証はユーザーから明示依頼がないため行わない。

---

### Task 1: 台帳のバージョン契約と診断の回帰テスト

**Files:**
- Modify: `tests/verify-overlay.ps1`
- Modify: `profiles/capabilities.json`
- Modify: `scripts/validate-catalogue.ps1`
- Modify: `scripts/check-prerequisites.ps1`

**Interfaces:**
- Consumes: `clients[*].prerequisiteCommands` と `capabilities[*].prerequisiteCommands` の `{ name, minimumMajor? }` 定義。
- Produces: `Test-PPDevCommand -Name <string> [-MinimumMajor <int>]` が `Present`、`VersionStatus`、`MajorVersion` を持つ結果を返し、不足／最低バージョン不足で `missing` を出力する。

- [ ] **Step 1: 台帳の最低バージョンを要求する失敗テストを書く**

`tests/verify-overlay.ps1` に、Canvas の `dotnet` minimumMajor 10、FlowAgent/Copilot Studio の `node` minimumMajor 18、GitHub Copilot CLI の `node` minimumMajor 22 を要求する検査を追加する。文字列の prerequisite を許容しない検査も追加する。

- [ ] **Step 2: 低いバージョンを不足として扱う失敗テストを書く**

既存の一時台帳テストへ、Canvas の prerequisite を `{ name = 'pwsh'; minimumMajor = 999 }` に置換して `check-prerequisites.ps1` を実行するケースを追加する。終了コード 1 と `prerequisite 'pwsh': missing (requires major version 999` を要求する。

- [ ] **Step 3: テストを実行して失敗を確認する**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: FAIL because the catalogue still contains string prerequisites and the prerequisite checker does not enforce a minimum version.

- [ ] **Step 4: 台帳と検証関数を最小変更する**

`clients` に `prerequisiteCommands` を追加し、GitHub Copilot CLI に `{ "name": "node", "minimumMajor": 22 }` を宣言する。各 capability の prerequisite を同じオブジェクト形式にし、Canvas/Dataverse は `dotnet` 10、FlowAgent/Copilot Studio は `node` 18、Power CAT は `node` を宣言する。

`Get-PPDevCatalogue` は object 型の `name`、正の整数 `minimumMajor`、重複しない prerequisite 名を検証する。

`Test-PPDevCommand` は `--version` の標準出力を取得して最初の数値メジャーを抽出する。最低メジャーを下回る場合は `Present = $false` とし、出力には必要バージョンを含める。抽出できない場合は `Present = $true`、`VersionStatus = 'not-checkable'` とする。

- [ ] **Step 5: テストを実行して成功を確認する**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: PASS; 一時台帳の未インストール・バージョン不足の両方が終了コード 1 で検証される。

### Task 2: 汎用安全 overlay とクライアント導入文書の回帰テスト

**Files:**
- Modify: `tests/verify-overlay.ps1`
- Modify: `templates/project/AGENTS.md`
- Modify: `docs/AI_DEVELOPMENT_TOOLING.md`

**Interfaces:**
- Consumes: Task 1 の versioned prerequisite catalogue と既存の資格情報拒否規則。
- Produces: 3クライアントの手動確認、開発環境有効化、FlowAgent 採用ゲート、対象外機能を説明する資格情報なしの導入文書と overlay。

- [ ] **Step 1: 追加する運用境界を要求する失敗テストを書く**

`tests/verify-overlay.ps1` の overlay 検査に `FlowStudio`、`validate_flow`、`preflight_flow`、`接続参照` を追加する。導入文書の検査には `.NET 10`、`Node.js 18`、`Node.js 22`、`dv-connect`、`mcs-assistant`、`Power CAT`、`Codex`、`Claude Code`、`GitHub Copilot CLI` を追加する。

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: FAIL because the current overlay and guide omit at least the FlowStudio exclusion, FlowAgent validation gates, and version floors.

- [ ] **Step 3: overlay を最小の共有境界で更新する**

`templates/project/AGENTS.md` に、FlowStudio を設定・依存関係へ含めないことを追加する。FlowAgent の新規フローには開発環境、停止状態、`validate_flow`、`preflight_flow`、接続参照レビュー、既存 Solution 接続参照優先を要求し、接続の自動作成・有効化・公開・import は明示承認後だけにする。

- [ ] **Step 4: 導入文書を更新する**

`docs/AI_DEVELOPMENT_TOOLING.md` に、クライアント別の公式プラグイン／ユーザースキル／MCP の違い、各最低バージョン、Dataverse MCP の手動有効化と `dv-connect`、新しい会話での一覧と読取り確認を追記する。Power CAT は Copilot CLI の公式 marketplace、Codex は開発者プロファイルの採用済みユーザースキルという区別を明記する。`mcs-assistant@copilot-studio-plugin` は開発環境だけで評価する実験対象とする。

- [ ] **Step 5: テストを実行して成功を確認する**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: PASS; 追加した安全境界と導入要件を含み、秘密情報検査も継続して通る。

### Task 3: 全体検証

**Files:**
- Verify: `profiles/capabilities.json`, `scripts/check-prerequisites.ps1`, `scripts/validate-catalogue.ps1`, `templates/project/AGENTS.md`, `docs/AI_DEVELOPMENT_TOOLING.md`, `tests/verify-overlay.ps1`

**Interfaces:**
- Consumes: Tasks 1–2 の変更。
- Produces: ローカルのみで再実行できる検証結果。

- [ ] **Step 1: 台帳と回帰テストを実行する**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: PASS.

- [ ] **Step 2: 現在の端末で前提確認を実行する**

Run: `pwsh -NoProfile -File scripts/check-prerequisites.ps1 -Client codex -Capability all`

Expected: ローカルの command/version 状態だけを表示する。存在しない command または最低バージョン不足があれば終了コード 1 で報告する。

- [ ] **Step 3: 差分の機械検査を実行する**

Run: `git diff --check` and `git status --short`

Expected: whitespace error がなく、設計・計画・本タスクの成果物だけが変更されている。

- [ ] **Step 4: DecisionSupport 実績との最終照合をする**

`C:\Users\rnmgy\.codex\worktrees\20a2\DecisionSupport` の `.mcp.json` と `.codex/config.toml` をテンプレートと比較し、どちらも未変更で内容一致することを確認する。DecisionSupport 固有の `.env`、認証ファイル、アプリ実装は読み込まない。

## Self-Review

- Spec coverage: Task 1 がバージョン契約と安全なローカル診断、Task 2 がクライアント導入・FlowAgent・対象外機能・手動有効化、Task 3 が全受入条件をカバーする。
- No placeholders: 未決事項の印や曖昧な実装指示を含まない。
- Interface consistency: Task 1 の object prerequisite schema を Task 2 の文書と Task 3 の検証が同じ version floor として参照する。
