# PPDevStandard

PPDevStandard は、Canvas アプリを手作業で少し扱った経験はあるものの、AI 駆動開発は初めてという人が、Power Platform 開発の準備を繰り返さずに始めるための補助リポジトリです。

Codex、Claude Code、GitHub Copilot CLI で共通して使う「機能の台帳」「安全な前提確認」「プロジェクト向け設定テンプレート」をまとめています。アプリ、Solution、フロー、テナント設定そのものをここで管理するものではありません。

## 先に知っておくこと

AI は、どのファイルが正本か、どの環境なら操作してよいか、何を確認してから公開するかを自動では知りません。このリポジトリで共通の準備を行い、**リポジトリごと**にその情報を AI へ渡します。

| いつ行うか | やること | どこで行うか |
| --- | --- | --- |
| PC ごとに一度だけ | AI クライアント、公式プラグイン、.NET / Node.js を準備する。Dataverse を使う場合は開発環境へローカル接続する。 | 自分の開発 PC |
| 新しいリポジトリごと | 共通設定をプレビューして適用し、正本・開発環境・検証方法・承認条件を記入する。 | 対象リポジトリ |
| AI に作業を頼むたび | 対象、影響、検証方法を確認してから調査・変更・検証する。 | 対象リポジトリと開発環境 |

初めてなら、次の順で進めてください。

1. [個別リポジトリ向けの実践ガイド](./docs/AI_DEVELOPMENT_TOOLING.md)で、使う AI クライアントの一度だけの準備を行う。
2. この README の「他のリポジトリへ適用する」で、対象リポジトリをまずプレビューする。
3. プレビュー結果を確認してから `-Apply` を付け、作成された `AGENTS.md` と `docs/AI_DEVELOPMENT_TOOLING.md` をそのプロジェクト用に完成させる。

## PPDevStandard が担うこと

| 層 | 所有者 | 担うこと |
| --- | --- | --- |
| 製品スキル・プラグイン | 上流・公式配布元 | 製品機能の実装と更新 |
| PPDevStandard | minoru365 | 機能台帳、クライアント対応、設定テンプレート、初期化、前提確認 |
| 個別プロジェクト | プロジェクトチーム | 正本、Solution、YAML、フロー定義、CI/CD、本番承認 |

製品機能は、次の上流・公式リポジトリを直接利用します。

- [Geek 氏の CodeAppsDevelopmentStandard](https://github.com/geekfujiwara/CodeAppsDevelopmentStandard)
- [Microsoft Power Platform Skills](https://github.com/microsoft/power-platform-skills)
- [Microsoft Dataverse Skills](https://github.com/microsoft/Dataverse-skills)
- [Microsoft Copilot Studio Skills](https://github.com/microsoft/skills-for-copilot-studio)
- [Microsoft Power CAT Skills](https://github.com/microsoft/power-cat-skills)

機能ごとの配布元、パッケージ識別子、前提コマンド、クライアント対応、検証境界は [`profiles/capabilities.json`](./profiles/capabilities.json) を正本とします。

## 扱う Power Platform 機能

| 機能 | AI で始める作業 | プロジェクトで管理する正本 |
| --- | --- | --- |
| Canvas Apps | Canvas Authoring MCP を使った開発環境での試作 | 版管理された Canvas 成果物 |
| Power Automate / FlowAgent | フローの探索、新規試作、接続調査、失敗診断 | フロー定義、Solution、接続参照 |
| Dataverse | メタデータとレコードの読取り調査 | スキーマ、Solution、スクリプト |
| Copilot Studio | YAML の作成、検証、評価 | Git 管理された YAML |
| Power CAT | Solution 内フローや Code Apps の品質確認 | レビュー結果とプロジェクトの正本 |

## 対応クライアント

| クライアント | 導入経路 | PPDevStandard の役割 |
| --- | --- | --- |
| Codex | 開発者プロファイルの skills と MCP | 機能台帳、安全なローカル診断、プロジェクト overlay |
| Claude Code | 公式 plugin marketplace と MCP | 同じ機能台帳・安全原則の利用 |
| GitHub Copilot CLI | 公式 plugin marketplace と MCP | 同じ機能台帳・安全原則の利用 |

プラグイン導入とテナント認証は、各利用者のローカル環境で行います。このリポジトリにはテナント URL、アカウント、トークン、認証キャッシュ、ユーザー固有の MCP 設定を書きません。

## 他のリポジトリへ適用する

### 1. まずプレビューする

次の3つは**自分のプロジェクトに合わせて変更する値**です。

| 変数 | 何を入れるか | 例 |
| --- | --- | --- |
| `$targetPath` | 設定を適用する対象リポジトリのフォルダー | `C:\work\my-power-platform-project` |
| `$clients` | 使う AI クライアント。複数使うなら `all` | `codex` / `claude-code` / `github-copilot-cli` / `all` |
| `$capabilities` | そのリポジトリで扱う Power Platform の機能 | `canvas-apps` / `dataverse` / `all` など |

まずは、次のコマンドを PowerShell で実行します。これは**プレビュー**であり、まだファイルを作成・変更しません。

```powershell
$targetPath = 'C:\work\my-power-platform-project' # 自分の対象リポジトリに変更する
$clients = 'all' # codex / claude-code / github-copilot-cli / all
$capabilities = 'canvas-apps' # all / canvas-apps / power-automate-flowagent / dataverse / copilot-studio / power-cat

pwsh -NoProfile -File scripts/initialize-project.ps1 `
    -TargetPath $targetPath `
    -Client $clients `
    -Capability $capabilities
```

出力の `would create` は「このファイルを新しく作る予定」、`manual merge required` は「同名ファイルがあるため、上書きせず自分で統合する必要がある」という意味です。既存のファイルがある場合は、内容を確認してから進めてください。

### 2. 確認できたら適用する

プレビュー結果に問題がなければ、同じコマンドの最後に `-Apply` を付けます。`-Apply` は唯一の書込み用スイッチです。既存の `.mcp.json`、`.codex/config.toml`、`AGENTS.md`、ツール文書は上書きしません。

```powershell
pwsh -NoProfile -File scripts/initialize-project.ps1 `
    -TargetPath $targetPath `
    -Client $clients `
    -Capability $capabilities `
    -Apply
```

適用後は、対象リポジトリに作成された `AGENTS.md` と `docs/AI_DEVELOPMENT_TOOLING.md` を読み、`<...>` で示された項目をそのプロジェクトの情報に置き換えます。

### 3. ローカルの前提を確認する

`check-prerequisites` は、選択したクライアントと機能に必要なローカルコマンドと、台帳に定義した最低メジャーバージョンを確認します。プラグインの導入、MCP 接続、認証、ネットワーク、クラウド環境の変更は行いません。

この確認では、1 回に 1 つのクライアントを指定します。次の2つを自分の環境に合わせて変更してください。

```powershell
$client = 'codex' # codex / claude-code / github-copilot-cli
$capability = 'all' # all / canvas-apps / power-automate-flowagent / dataverse / copilot-studio / power-cat

pwsh -NoProfile -File scripts/check-prerequisites.ps1 -Client $client -Capability $capability
```

`missing` と表示された場合は、実践ガイドの「一度だけ行うこと」を確認し、必要なツールをローカルに導入してからもう一度実行します。

## 上流ツールの更新

上流のスキルやプラグインは、それぞれの公式配布元で更新します。更新後は、対象機能の台帳を更新し、`check-prerequisites` とプロジェクトでの手動確認を行います。

PPDevStandard は上流のソースコードをコピーしないため、上流更新のたびに fork の競合を解消する必要はありません。
