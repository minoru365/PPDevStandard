# Power Platform AI 開発 overlay

このファイルはプロジェクト固有の `AGENTS.md` へ統合する共通ルールです。プロジェクトの正本、デプロイ手順、CI/CD、承認ルールを置き換えません。

FlowStudio は外部有償 MCP のため、この共通構成の設定・依存関係には含めない。

## ツールの使い分け

| 作業 | 第一候補 | 採用後の正本 |
| --- | --- | --- |
| Power Automate の探索・新規試作・失敗診断 | 公式 FlowAgent | プロジェクトのフロー定義または Solution |
| 既存フローの変更 | プロジェクト固有の正本 | プロジェクト固有の正本 |
| Dataverse の調査 | Dataverse Skills / MCP | プロジェクトのスキーマ・Solution・スクリプト |
| Canvas Apps の試作 | Canvas Authoring MCP | 版管理された Canvas 成果物 |
| Copilot Studio の作成・検証・評価 | 公式 YAML skills | Git 管理された YAML |
| フロー・Code Apps の品質確認 | Power CAT | レビュー結果とプロジェクトの正本 |

## 探索・試作

開発環境でのみ、新規かつ一時的な資産を MCP / AI スキルで作成・検証できる。FlowAgent で作る新規フローは停止状態にする。Dataverse はメタデータ確認と読取りを既定にする。データまたはスキーマを書き込む試作では、対象と戻し方を先に示す。

FlowAgent の新規フローは、開発環境で停止状態に作成し、`validate_flow` と `preflight_flow`、接続参照のレビューを通す。既存 Solution の接続参照を優先し、接続を自動作成しない。有効化、公開、Solution import は対象と影響を示した明示承認後に行う。

既存の管理対象を置換、削除、公開、import、変更しない。

## 採用・運用

共有、継続保守、複数環境展開、業務影響、データまたはセキュリティに関わる変更は、Git 管理されたプロジェクトの Python、Solution、YAML、フロー定義、版管理 Canvas 成果物、CI/CD へ反映する。適用前に差分、接続参照、依存関係、検証結果をレビューする。

既存資産の変更、公開、削除、セキュリティロール、環境設定、Solution import、本番操作は、対象と影響を示した明示承認後だけに行う。

## 秘密情報

テナント URL、アカウント、認証情報、認証キャッシュ、ユーザー固有の Dataverse MCP 接続設定は、リポジトリや共有レポートに書かない。
