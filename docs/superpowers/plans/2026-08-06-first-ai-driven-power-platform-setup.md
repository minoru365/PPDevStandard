# 初めての AI 駆動 Power Platform 開発の導線 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 初めて AI 駆動開発を行う Power Platform 開発者が、共通環境の準備とリポジトリ固有の設定を区別して安全に始められるようにする。

**Architecture:** README は短い導入とコマンド選択の案内に集中させる。初期化時に個別リポジトリへコピーされる `AI_DEVELOPMENT_TOOLING.md` は、クライアント別の指示ファイルと作業フローを含む実践ガイドにする。プロジェクトで共通する規則は `AGENTS.md` を正本にし、クライアント固有のファイルへ重複させない。

**Tech Stack:** Markdown、PowerShell、既存の `tests/verify-overlay.ps1`

## Global Constraints

- Power Platform の環境、認証、MCP 接続、スクリプトの動作、依存関係を変更しない。
- テナント URL、アカウント、トークン、認証キャッシュを文書やテンプレートに書かない。
- スクリプトの引数は実装済みの値だけを案内する: `Client` は `codex`、`claude-code`、`github-copilot-cli`、初期化時のみ `all`。`Capability` は `all`、`canvas-apps`、`power-automate-flowagent`、`dataverse`、`copilot-studio`、`power-cat`。
- `-Apply` を付けない実行はプレビューであり、ファイルを作成しない。`-Apply` を付けた場合も既存ファイルは上書きしない。
- コミット、プッシュ、デプロイはユーザーから明示依頼があるまで行わない。

---

### Task 1: README を初回セットアップの入口に整理する

**Files:**
- Modify: `README.md`
- Test: `git diff --check`

**Interfaces:**
- Consumes: `scripts/initialize-project.ps1` の `TargetPath`、`Client`、`Capability`、`Apply` パラメータ
- Produces: 初回利用者が「一度だけ」と「リポジトリごと」に行う作業を選べる入口

- [ ] **Step 1: README 冒頭に対象読者と到達点を加える**

「Canvas アプリを手作業で扱った経験はあるが AI 駆動開発は初めて」の読者に向け、PPDevStandard が PC ごとの準備とプロジェクトごとの設定を分けて再利用するリポジトリであることを説明する。

- [ ] **Step 2: 作業の頻度を二分するチェックリストを置く**

「一度だけ行うこと」にはクライアント導入、公式プラグイン、前提コマンド、開発環境の Dataverse 接続を置く。「リポジトリごとに行うこと」には正本と検証方法の確認、初期化プレビュー、`-Apply`、生成文書の確認を置く。

- [ ] **Step 3: 初期化コマンドの利用者入力を変数として示す**

次の形に統一し、各変数の意味と選択値をコードブロックの直前で説明する。

```powershell
$targetPath = 'C:\work\my-power-platform-project' # 対象リポジトリのフォルダー
$clients = 'all' # codex / claude-code / github-copilot-cli / all
$capabilities = 'canvas-apps' # all / canvas-apps / power-automate-flowagent / dataverse / copilot-studio / power-cat

pwsh -NoProfile -File scripts/initialize-project.ps1 `
    -TargetPath $targetPath `
    -Client $clients `
    -Capability $capabilities
```

`-Apply` は「プレビューを確認してから、存在しない共通ファイルを作成する」ためのスイッチとして説明し、別のコードブロックで同じ変数に `-Apply` を足す。

- [ ] **Step 4: 前提確認の選択値を説明する**

`check-prerequisites.ps1` は一度に一つのクライアントを確認することを明記し、次の例を置く。

```powershell
$client = 'codex' # codex / claude-code / github-copilot-cli
$capability = 'all' # all / canvas-apps / power-automate-flowagent / dataverse / copilot-studio / power-cat

pwsh -NoProfile -File scripts/check-prerequisites.ps1 -Client $client -Capability $capability
```

- [ ] **Step 5: 書式を確認する**

Run: `git diff --check`

Expected: exit code 0。空白エラーなし。

### Task 2: 個別リポジトリ向け実践ガイドを書き直す

**Files:**
- Modify: `docs/AI_DEVELOPMENT_TOOLING.md`
- Test: `tests/verify-overlay.ps1`

**Interfaces:**
- Consumes: `initialize-project.ps1` がこのファイルを `<TargetPath>/docs/AI_DEVELOPMENT_TOOLING.md` にコピーする既存動作
- Produces: リポジトリに残り、チームが導入後も参照できる日常運用ガイド

- [ ] **Step 1: 文書冒頭に AI 駆動開発の境界を置く**

AI は正本・対象環境・承認条件を自動的には理解しないため、プロジェクトに書く必要があると説明する。開発環境での読取り・検証を既定とし、既存資産の変更、公開、削除、Solution import、本番操作には明示承認が必要であることを最初に示す。

- [ ] **Step 2: 「一度だけ」「リポジトリごと」「作業のたび」の3節を作る**

それぞれに次を置く。

| 頻度 | 内容 |
| --- | --- |
| 一度だけ | Codex / Claude Code / Copilot CLI の導入、公式プラグイン、Node.js と .NET の前提確認、各開発者の Dataverse 接続 |
| リポジトリごと | 正本・開発環境・検証方法・承認条件を確認し、初期化をプレビューしてから適用、生成ファイルを手動マージ |
| 作業のたび | `AGENTS.md` を読み、対象と影響を確認し、調査・変更・検証・レビューの順で進める |

- [ ] **Step 3: 指示ファイルの使い分けをクライアント別に説明する**

共通規則の正本はリポジトリの `AGENTS.md` とする。次の表を作り、配置場所・用途・確認方法を示す。

| クライアント | 個人の全リポジトリ規則 | リポジトリ規則 | 確認方法 |
| --- | --- | --- | --- |
| Codex | `~/.codex/AGENTS.md` | `AGENTS.md` | 新しいセッションで指示の要約を依頼する |
| Claude Code | `~/.claude/CLAUDE.md` | `CLAUDE.md` または共通 `AGENTS.md`。領域限定は `.claude/rules/` | `/memory` で読み込まれた記憶を確認する |
| GitHub Copilot CLI | `~/.copilot/copilot-instructions.md` | `.github/copilot-instructions.md` と共通 `AGENTS.md` | `/instructions` で読み込まれた指示を確認する |

`AGENTS.md` に正本・環境・検証・承認条件を一度だけ書き、各専用ファイルではクライアント固有の追加事項だけにする理由を説明する。

- [ ] **Step 4: コピーして編集できる最小サンプルを掲載する**

グローバル指示には個人の原則だけを書く例を示す。

```md
# 個人の AI 開発ルール

- 秘密情報をチャット、Git、共有文書に書かない。
- 外部サービスへの変更、依存関係の追加、公開・削除の前に確認を求める。
- 変更後はリポジトリに定義された検証を実行し、結果を短く報告する。
```

リポジトリの `AGENTS.md` には、次のプレースホルダーを明確に置換対象として示す。

```md
# このリポジトリの AI 開発ルール

## 正本

- Canvas アプリ: `<版管理されている成果物の場所>`
- Solution / フロー: `<管理対象の場所>`
- 検証: `<実行するコマンド>`

## Power Platform の操作境界

- 使用するのは `<開発環境の識別方法>` のみ。URL、アカウント、トークンは記録しない。
- 既存資産の変更、公開、削除、Solution import、本番操作は、対象と影響を示して明示承認を得てから行う。
```

Copilot 専用ファイルには、共通 `AGENTS.md` を使うことと、Copilot の追加事項だけを置く例を示す。Claude Code の `CLAUDE.md` についても同じ原則を示す。

- [ ] **Step 5: クライアント別の公式導入と接続の説明を初心者向けに再配置する**

公式プラグインの導入と Dataverse 接続は「一度だけ」の手順に置く。プロジェクトの `.mcp.json` と Codex の `.codex/config.toml` は初期化で扱われる設定であり、ユーザー固有の認証情報を書き込む場所ではないことを明記する。

- [ ] **Step 6: コピー動作を回帰確認する**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: exit code 0。初期化のプレビュー、`-Apply`、既存ファイルの手動マージ通知、前提確認のテストが通る。

### Task 3: 共通 AGENTS.md テンプレートを初回利用者向けに整える

**Files:**
- Modify: `templates/project/AGENTS.md`
- Test: `tests/verify-overlay.ps1`

**Interfaces:**
- Consumes: `initialize-project.ps1` がテンプレートを `<TargetPath>/AGENTS.md` にコピーする既存動作
- Produces: 個別リポジトリへ置いたあと、利用者がプロジェクト固有の値を埋められる共通ルールの土台

- [ ] **Step 1: テンプレート冒頭に編集方法を加える**

テンプレートはそのまま完成したルールではないことを示し、`<...>` の箇所をプロジェクトの正本、開発環境の識別方法、検証コマンドに置き換えるよう案内する。既存のプロジェクト `AGENTS.md` がある場合は、初期化ツールが上書きしないため、見出し単位で手動マージすることも明記する。

- [ ] **Step 2: プロジェクト固有の記入欄を追加する**

次の最小セクションを既存の安全ルールより前に置く。

```md
## このプロジェクトで最初に確認すること

- **正本**: `<Canvas / Solution / YAML / フロー定義の場所>`
- **開発環境**: `<開発環境の識別方法。URL・資格情報は書かない>`
- **検証**: `<変更後に実行するコマンド>`
- **承認が必要な操作**: `<公開・import・削除など、チーム固有の条件>`
```

- [ ] **Step 3: 既存の安全境界と矛盾しないことを確認する**

テンプレートの探索・試作、採用・運用、秘密情報の節を保持する。新しい記入欄が「既存資産の変更、公開、削除、セキュリティ、環境設定、Solution import、本番操作は明示承認後」という既存規則を緩めないことを目視確認する。

- [ ] **Step 4: コピー動作を回帰確認する**

Run: `pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: exit code 0。適用時に `AGENTS.md` が作成され、既存 `AGENTS.md` は変更されない。

### Task 4: 最終確認と利用者向け要約

**Files:**
- Modify: `README.md`, `docs/AI_DEVELOPMENT_TOOLING.md`, `templates/project/AGENTS.md`
- Test: `git diff --check`, `pwsh -NoProfile -File tests/verify-overlay.ps1`

**Interfaces:**
- Consumes: Tasks 1–3 の文書・テンプレート更新
- Produces: 初回利用者に渡せる、用語と境界がそろった案内

- [ ] **Step 1: 読者の経路を通読する**

README の「一度だけ」から初期化プレビュー、`-Apply`、生成された実践ガイド、`AGENTS.md` の記入欄へ順に通読する。各段階で「何を置き換えるか」「何が書き込まれるか」「次に読む文書」が示されていることを確認する。

- [ ] **Step 2: 文書の機密情報と表記を検査する**

Run: `rg -n -i "token|password|secret|https://.*powerplatform|@.*\.com" README.md docs/AI_DEVELOPMENT_TOOLING.md templates/project/AGENTS.md`

Expected: 実在の資格情報、テナント URL、アカウントが出力されない。一般的な注意書きに含まれる単語は文脈を確認する。

- [ ] **Step 3: 機械的確認を実行する**

Run: `git diff --check; pwsh -NoProfile -File tests/verify-overlay.ps1`

Expected: 両方とも exit code 0。

- [ ] **Step 4: 変更範囲を報告する**

README、生成対象ガイド、共通 `AGENTS.md` テンプレートを更新したこと、スクリプト・認証・Power Platform 環境は変更していないこと、機械的確認の結果を簡潔に報告する。コミットはユーザーが明示的に依頼した場合のみ行う。
