# 再利用可能な AI 開発環境 — 設計

## 目的

Power Platform の新規リポジトリへ、Codex・Claude Code・GitHub Copilot CLI で共通に使う AI 開発環境の設定と指示を、資格情報を含めずに適用できるようにする。

## 対象としないもの

- 上流スキル、プラグイン、MCP 実装のコピーや更新
- DecisionSupport 固有のフロー、Solution、データモデル、Python、UI の再利用
- テナント URL、アカウント、トークン、認証キャッシュ、Dataverse 接続の生成
- プラグイン導入、認証、クラウド環境の変更

## 構成

| 要素 | 役割 |
| --- | --- |
| `scripts/initialize-project.ps1` | 明示した対象フォルダーへ、選択したクライアントと機能のテンプレートを配置する。既定はプレビューで、`-Apply` 指定時だけ書き込む。既存ファイルは上書きしない。 |
| `scripts/check-prerequisites.ps1` | クライアントと機能に必要なローカルコマンドを確認し、MCP 接続・プラグイン導入は手動確認事項として表示する。旧 `doctor.ps1` を置き換える。 |
| `templates/project/` | 秘密情報なしの PAC MCP、Codex MCP、Power Platform `AGENTS` overlay のテンプレートを保持する。 |
| `docs/AI_DEVELOPMENT_TOOLING.md` | クライアント別の公式導入経路、機能別のルーティング、Dataverse のローカル接続手順を示す。 |
| `profiles/capabilities.json` | クライアント・機能・前提コマンド・公式配布元の機械可読な台帳として残す。 |

## 適用動作

`initialize-project.ps1` は `-TargetPath` を必須とする。`-Client` と `-Capability` は選択でき、既定では全対応クライアントと全標準機能を対象にする。

- `-Apply` がない場合は、配置予定の相対パスを表示して終了する。
- `-Apply` がある場合のみ、テンプレートを対象フォルダーへコピーする。
- 対象に同名ファイルが存在する場合は、書き込まず「manual merge required」と報告する。
- Claude Code / GitHub Copilot CLI 向け `.mcp.json` には PAC MCP だけを置く。Canvas MCP は公式 Canvas Apps プラグインが登録するため重複登録しない。
- Codex 向け `.codex/config.toml` には PAC MCP を置き、Canvas Apps を選んだ場合だけ Canvas Authoring MCP を追加する。
- Dataverse MCP の実 URL はテンプレートに含めない。公式 Dataverse Skills の接続手順を案内する。

## 共通ルーティング

`docs/AI_DEVELOPMENT_TOOLING.md` と `AGENTS` overlay で次を共通化する。

| 作業 | 第一候補 | 採用後の正本 |
| --- | --- | --- |
| Power Automate の探索・新規試作・診断 | 公式 FlowAgent | プロジェクトのフロー定義または Solution |
| 既存フローの変更 | プロジェクト固有の正本 | プロジェクト固有の正本 |
| Dataverse の調査 | Dataverse Skills / MCP | プロジェクトのスキーマ・Solution・スクリプト |
| Canvas Apps の試作 | Canvas Authoring MCP | 版管理された Canvas 成果物 |
| Copilot Studio の作成・検証・評価 | 公式 YAML skills | Git 管理された YAML |
| フロー・Code Apps の品質確認 | Power CAT | レビュー結果とプロジェクトの正本 |

既存資産の変更、公開、削除、セキュリティ、環境、Solution import は、対象と影響を示した明示承認後だけにする。

## `canary` の扱い

現行 `canary.ps1` は台帳を表示するだけで、上流・プラグイン・MCP を検証しない。誤解を招くため削除する。台帳の構造検証は既存の `validate-catalogue.ps1` とテストに残す。

## 検証

- `initialize-project.ps1` のプレビューは対象フォルダーを書き換えない。
- `-Apply` は空の一時フォルダーへ選択したテンプレートだけを配置する。
- 既存設定ファイルは上書きせず、手動マージを報告する。
- Canvas 未選択時の Codex 設定には Canvas MCP を含めない。
- 資格情報・テナント URL・Dataverse URL を出力・生成物・台帳に含めない。
- `check-prerequisites.ps1` は不足コマンドで非ゼロ終了し、ネットワーク、認証、インストール、クラウド変更を行わない。

## 受入条件

別の空リポジトリに対し、資格情報なしで必要な共通設定・指示・手順を配置できる。設定済みの別リポジトリでは既存ファイルを変更せず、必要な手動マージを明示する。Codex、Claude Code、GitHub Copilot CLI の差分をドキュメントとテンプレートで追える。
