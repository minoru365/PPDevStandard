# AI 開発環境の適用方法

この文書は、PPDevStandard の初期化で個別プロジェクトへ配置する。Codex、Claude Code、GitHub Copilot CLI で共通の Power Platform 開発環境を使うために、公式のスキル・プラグインの導入経路とルーティングを示す。上流の実装はこのリポジトリに複製しない。

対象側の `.mcp.json` は PAC MCP 用である。Claude Code と GitHub Copilot CLI の Canvas MCP は、公式 Canvas Apps プラグインが登録するため追加しない。Codex では Canvas Apps を選択した場合だけ `.codex/config.toml` に Canvas Authoring MCP を配置する。

## 1. 公式のスキル・プラグインを導入する

| 機能 | 公式配布元 | 対象 |
| --- | --- | --- |
| Canvas Apps / Power Automate | [Power Platform Skills](https://github.com/microsoft/power-platform-skills) | Canvas Authoring MCP、FlowAgent |
| Dataverse | [Dataverse Skills](https://github.com/microsoft/Dataverse-skills) | Dataverse specialist skills と MCP |
| Copilot Studio | [Copilot Studio Skills](https://github.com/microsoft/skills-for-copilot-studio) | YAML 作成、検証、評価 |
| Power CAT | [Power CAT Skills](https://github.com/microsoft/power-cat-skills) | Flow / Code Apps のレビューと評価 |

Claude Code と GitHub Copilot CLI では、公式セッション内で次の形式で marketplace を登録し、必要なプラグインだけを導入する。実際のプラグイン名と最新版は各公式配布元で確認する。

```text
/plugin marketplace add microsoft/power-platform-skills
/plugin install canvas-apps@power-platform-skills
/plugin install power-automate@power-platform-skills
```

Codex では開発者プロファイルの Plugins から、台帳 `profiles/capabilities.json` に記載したパッケージを導入する。導入後は新しい会話でスキルと MCP の一覧を確認する。

### クライアントごとの導入境界

- **Codex**: 開発者プロファイルに採用済みの公式スキルと MCP を導入する。PAC MCP は `.codex/config.toml`、Canvas Apps は選択時の Canvas Authoring MCP を使う。Power CAT は公式 marketplace の対象外のため、採用済みユーザースキルを補助的な設計・評価にだけ使う。
- **Claude Code**: Power Platform Skills、Dataverse、Copilot Studio の公式プラグインを開発者プロファイルへ導入し、プロジェクトの `.mcp.json` を承認して使う。
- **GitHub Copilot CLI**: Power Platform Skills、Dataverse、Copilot Studio、Power CAT の公式 marketplace を使う。プロジェクトの `.mcp.json` を承認して使う。

Canvas Apps と PAC MCP には **.NET 10** 以上が必要である。FlowAgent と Copilot Studio YAML skills には **Node.js 18** 以上、GitHub Copilot CLI には **Node.js 22** 以上が必要である。`check-prerequisites.ps1` はこれらのローカルバージョンだけを確認する。

`mcs-assistant@copilot-studio-plugin` は実験的であり、標準構成には含めない。評価する場合も開発環境に限定し、別途明示承認を得る。

## 2. Dataverse を開発者ローカルで接続する

Dataverse MCP の接続先は開発者と環境ごとに異なる。公式 Dataverse Skills の `dv-connect` を使い、許可された開発環境にユーザー設定として接続する。接続先や認証情報を `.mcp.json`、`.codex/config.toml`、Git、共有ドキュメントへ保存しない。

接続を有効化するのは各開発者である。対象の開発環境で Dataverse MCP と使用するクライアントを許可し、ローカル認証後に `dv-connect` で接続を登録する。最初は `dv-query`、Dataverse MCP のメタデータ取得、PAC MCP の一覧・検証だけを行い、接続先と要求権限を確認する。本番環境への認証、接続、書込みはこの共通構成の適用対象外である。

## 機能別ルーティング

| 作業 | 第一候補 | 境界 |
| --- | --- | --- |
| フローの探索・新規試作・接続調査・失敗診断 | FlowAgent | 新規フローは開発環境で停止状態にする。採用前に定義と接続参照を正本へ反映する。 |
| 既存フローの変更 | プロジェクト固有のフロー定義・Solution・スクリプト | FlowAgent の結果を確認材料にし、正本を迂回して変更しない。 |
| Dataverse のメタデータ・レコード調査 | Dataverse Skills / MCP | 読取りを既定にする。既存資産、削除、ロール、環境変更は明示承認後。 |
| Canvas Apps の試作 | Canvas Authoring MCP | 新規の開発環境 coauthoring セッションだけで行う。採用時は版管理成果物をレビューする。 |
| Copilot Studio の作成・検証・評価 | 公式 YAML skills | 既存エージェントの push / publish / チャネル変更は明示承認後。 |
| Solution 内フロー・Code Apps の品質確認 | Power CAT | 指摘はレビュー材料とし、修正はプロジェクトの正本へ行う。 |

FlowAgent の新規フローは、開発環境で停止状態に作成し、`validate_flow`、`preflight_flow`、接続参照のレビューを通す。既存 Solution の接続参照を優先し、接続を自動作成しない。有効化、公開、Solution import は、対象と影響を示した明示承認後だけにする。

## 前提確認

初期化後、PPDevStandard のリポジトリ ルートで、選択した機能に必要なローカルコマンドだけを確認する。`check-prerequisites.ps1` は個別プロジェクトへはコピーされないため、PPDevStandard を保持してこの確認に使う。

```powershell
pwsh -NoProfile -File scripts/check-prerequisites.ps1 -Client codex -Capability all
```

この確認はプラグイン導入、MCP 接続、認証、ネットワーク、クラウド環境の状態を変更しない。公式プラグインと MCP 接続は、各開発者が開発環境で手動確認する。

各クライアントでは、新しい会話を開始してから、導入済みのプラグインと MCP 一覧を確認し、読取りまたは検証だけの操作で接続を確かめる。利用するクライアントの承認モデルに従い、プロジェクト MCP を明示承認してから使用する。
