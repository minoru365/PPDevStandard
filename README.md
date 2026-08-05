# PPDevStandard

PPDevStandard は、Codex・Claude Code・GitHub Copilot CLI で共通して使う、Power Platform 開発用の小さな補助リポジトリです。

製品スキルやプラグインは fork／複製せず、公式の配布元をそのまま利用します。このリポジトリには、機能台帳、クライアント対応、ローカル診断、プロジェクト用テンプレートだけを置きます。

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

## 機能台帳

| 機能 | 上流の実装 | PPDevStandard で補強すること |
| --- | --- | --- |
| Canvas Apps | Canvas Authoring MCP と `.pa.yaml` 開発 | クライアント対応と前提確認 |
| Power Automate / FlowAgent | 公式 FlowAgent プラグインと MCP | 前提確認とプロジェクト用テンプレート |
| Dataverse | specialist skills、MCP、PAC CLI、SDK | クライアント対応と前提確認 |
| Copilot Studio | YAML 作成・検証・評価スキル | クライアント対応とテンプレート |
| Power CAT | Overflow、Code Apps／Pro-Code の評価 | 採用ツールの台帳化 |

機能ごとの配布元、パッケージ識別子、前提コマンド、クライアント対応、検証境界は [`profiles/capabilities.json`](./profiles/capabilities.json) を正本とします。

## 対応クライアント

| クライアント | 導入経路 | PPDevStandard の役割 |
| --- | --- | --- |
| Codex | 開発者プロファイルの skills と MCP | 機能台帳、安全なローカル診断、プロジェクト overlay |
| Claude Code | 公式 plugin marketplace と MCP | 同じ機能台帳・安全原則の利用 |
| GitHub Copilot CLI | 公式 plugin marketplace と MCP | 同じ機能台帳・安全原則の利用 |

プラグイン導入とテナント認証は、各利用者のローカル環境で行います。このリポジトリにはテナント URL、アカウント、トークン、認証キャッシュ、ユーザー固有の MCP 設定を書きません。

## 他のリポジトリへ適用する

### 1. まずプレビューする

対象リポジトリを明示して、配置予定の共通設定を確認します。この時点ではファイルを書き換えません。

```powershell
pwsh -NoProfile -File scripts/initialize-project.ps1 `
    -TargetPath C:\work\my-power-platform-project `
    -Client codex `
    -Capability canvas-apps
```

配置してよければ、同じコマンドに `-Apply` を付けます。既存の `.mcp.json`、`.codex/config.toml`、`AGENTS.md`、ツール文書は上書きせず、手動マージが必要なことを表示します。

```powershell
pwsh -NoProfile -File scripts/initialize-project.ps1 `
    -TargetPath C:\work\my-power-platform-project `
    -Client codex `
    -Capability canvas-apps `
    -Apply
```

### 2. ローカルの前提を確認する

`check-prerequisites` は、選択したクライアントと機能に必要なローカルコマンドと、台帳に定義した最低メジャーバージョンを確認します。プラグインの導入、MCP 接続、認証、ネットワーク、クラウド環境の変更は行いません。

```powershell
pwsh -NoProfile -File scripts/check-prerequisites.ps1 -Client codex -Capability all
```

### 3. 公式プラグインを導入し、接続する

生成された [`docs/AI_DEVELOPMENT_TOOLING.md`](./docs/AI_DEVELOPMENT_TOOLING.md) に従い、公式プラグインを開発者プロファイルへ導入します。Dataverse の接続先と認証は各開発者のローカル設定だけに置きます。

## 上流ツールの更新

上流のスキルやプラグインは、それぞれの公式配布元で更新します。更新後は、対象機能の台帳を更新し、`check-prerequisites` とプロジェクトでの手動確認を行います。

PPDevStandard は上流のソースコードをコピーしないため、上流更新のたびに fork の競合を解消する必要はありません。
