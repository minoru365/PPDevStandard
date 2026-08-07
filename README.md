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

機能ごとの配布元、パッケージ識別子、前提コマンド、クライアント対応、検証境界は [`profiles/capabilities.json`](./profiles/capabilities.json) を正本とします。スクリプトと README の記述は、この台帳に従います。

台帳の `profiles` は、標準構成として採用する範囲を示します。`power-platform-core` が既定の標準構成です。`agent365` は実験段階のため既定では無効で、評価する場合も開発環境に限定し、別途明示承認を得てください。

## 扱う Power Platform 機能

| 機能 | AI で始める作業 | プロジェクトで管理する正本 |
| --- | --- | --- |
| Canvas Apps | Canvas Authoring MCP を使った開発環境での試作 | 版管理された Canvas 成果物 |
| Code Apps | ローカルビルドと開発環境での実行、データソース・コネクタの追加 | アプリのソース、`power.config.json`、デプロイ手順 |
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

まずは、次のコマンドを **PPDevStandard のリポジトリ ルート**で実行します。これは**プレビュー**であり、まだファイルを作成・変更しません。`-Client` と `-Capability` に `all` を指定する場合は、他の値と組み合わせられません。

```powershell
$targetPath = 'C:\work\my-power-platform-project' # 自分の対象リポジトリに変更する
$clients = 'all' # codex / claude-code / github-copilot-cli / all
$capabilities = 'canvas-apps' # all / canvas-apps / code-apps / power-automate-flowagent / dataverse / copilot-studio / power-cat

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

作成される MCP 設定は、クライアントごとに内容が異なります。Codex には `pac-cli` を、Canvas Apps を選んだ場合は `canvas-authoring` も `.codex/config.toml` へ書き出します。Claude Code と GitHub Copilot CLI 向けの `.mcp.json` は `pac-cli` だけです。これらのクライアントでは Canvas Authoring MCP が公式プラグイン側から提供されるため、プロジェクト設定に重複して書きません。新しい会話で MCP が想定どおり有効になっているかを確認してください。

### 3. ローカルの前提を確認する

`check-prerequisites` は、選択したクライアントと機能に必要なローカルコマンドと、台帳に定義した最低メジャーバージョンを確認します。プラグインの導入、MCP 接続、認証、ネットワーク、クラウド環境の変更は行いません。

この確認では、1 回に 1 つのクライアントを指定します。次の2つを自分の環境に合わせて変更し、**PPDevStandard のリポジトリ ルート**で実行してください。

```powershell
$client = 'codex' # codex / claude-code / github-copilot-cli
$capability = 'all' # all / canvas-apps / code-apps / power-automate-flowagent / dataverse / copilot-studio / power-cat

pwsh -NoProfile -File scripts/check-prerequisites.ps1 -Client $client -Capability $capability
```

`missing` と表示された場合は、実践ガイドの「一度だけ行うこと」を確認し、必要なツールをローカルに導入してからもう一度実行します。

## 上流ツールの更新

上流のスキルやプラグインは、それぞれの公式配布元で更新します。更新後は、対象機能の台帳を更新し、`check-prerequisites` とプロジェクトでの手動確認を行います。

PPDevStandard は上流のソースコードをコピーしないため、上流更新のたびに fork の競合を解消する必要はありません。

## このリポジトリを保守する

### 構成

| パス | 役割 |
| --- | --- |
| `profiles/capabilities.json` | 機能・クライアント・前提コマンドの正本 |
| `scripts/validate-catalogue.ps1` | 台帳の整合性検証と読み込み関数 |
| `scripts/check-prerequisites.ps1` | ローカルコマンドとバージョンの確認（読取りのみ） |
| `scripts/initialize-project.ps1` | 対象リポジトリへのテンプレート適用（`-Apply` 時のみ書込み） |
| `templates/project/` | 対象リポジトリへ配置する設定テンプレート |
| `docs/AI_DEVELOPMENT_TOOLING.md` | 対象リポジトリへ配置する実践ガイド |
| `docs/superpowers/` | 設計・計画の記録 |
| `tests/verify-overlay.ps1` | 台帳・テンプレート・スクリプト挙動の回帰テスト |

### 変更時に実行する検証

台帳、テンプレート、スクリプト、README のいずれかを変更したら、リポジトリ ルートで次を実行します。同じ内容を GitHub Actions の `verify` ワークフローでも実行します。

```powershell
pwsh -NoProfile -File scripts/validate-catalogue.ps1
pwsh -NoProfile -File tests/verify-overlay.ps1
```

`verify-overlay.ps1` は一時ディレクトリで `initialize-project.ps1` を実行します。テナントへの接続、認証、インストールは行いません。

### 台帳を更新するとき

1. `profiles/capabilities.json` を変更し、`updated` を変更日に合わせる。
2. 対応クライアントや前提バージョンを変えた場合は、README、`docs/AI_DEVELOPMENT_TOOLING.md`、`tests/verify-overlay.ps1` の期待値も同じ変更でそろえる。
3. 上の検証コマンドを実行する。

各機能には `knownPitfalls` を必ず置きます。実際に踏んだ落とし穴を `trigger`（どういうときに読むか）、`symptom`（何が起きるか）、`resolution`（どうするか）で記録します。まだ記録が無い場合も `[]` を明示し、「書き忘れ」と「まだ無い」を区別できるようにします。散文で README に書き足すと機械的に検証できなくなるため、落とし穴は台帳側に置いてください。

### 書かないもの

テナント URL、アカウント、トークン、認証キャッシュ、ユーザー固有の MCP 接続設定は、このリポジトリと共有レポートに書きません。`verify-overlay.ps1` はこれらの混入を機械的に検査します。

## ライセンス

MIT License。詳細は [LICENSE](./LICENSE) を参照してください。上流のスキル・プラグインはそれぞれの配布元のライセンスに従います。
