# クロスクライアント開発ツール規約の抽出 — 設計

## 目的

DecisionSupport の `codex/standard-modernization` ワークツリーで確立した、資格情報を含まない
Power Platform 開発ツールの運用知識を、Codex、Claude Code、GitHub Copilot CLI で再利用できる
PPDevStandard の台帳、導入文書、プロジェクト overlay、ローカル前提確認へ抽出する。

## 対象範囲

- `profiles/capabilities.json` のクライアント別導入経路、必要バージョン、成熟度を明確化する。
- `docs/AI_DEVELOPMENT_TOOLING.md` に、開発環境の有効化、クライアント別確認、FlowAgent の採用ゲートを記録する。
- `templates/project/AGENTS.md` に、FlowStudio 除外とフローの接続参照・検証境界を追加する。
- `scripts/check-prerequisites.ps1` で、宣言したローカル前提コマンドの最低バージョンを判定する。
- `tests/verify-overlay.ps1` で、上記の静的契約と前提確認の成功・失敗を検証する。

## 対象外

- テナント URL、環境 ID、アカウント、トークン、認証キャッシュ、Dataverse 接続先の保存・出力。
- DecisionSupport 固有のアプリ、Python スクリプト、Solution、フロー、接続参照、業務ルールの再利用。
- プラグイン導入、認証、ネットワーク接続、クラウド変更を行う自動化。
- 既存の `.mcp.json` と Codex MCP テンプレートの変更。これらは DecisionSupport と内容一致している。

## 設計

台帳を唯一の機械可読な前提定義とする。各 capability の前提コマンドには、コマンド名と必要な
最低バージョンを宣言する。`check-prerequisites.ps1` は `Get-Command` と `<command> --version`
だけを用い、コマンド不足または最低バージョン不足を `missing` として非ゼロ終了する。

導入文書は、クライアントごとの公式導入先と、プラグイン、ユーザースキル、MCP の差を明示する。
開発環境の有効化は手順として記録するだけで、スクリプトは認証・接続・書込みを実行しない。

プロジェクト overlay は、共有できる安全境界だけを短く保持する。新規 FlowAgent フローは開発環境
かつ停止状態で作成し、`validate_flow`、`preflight_flow`、接続参照レビューを通し、既存 Solution
接続参照を優先する。接続の自動作成、有効化、公開、import は明示承認が必要である。FlowStudio と
実験的な `mcs-assistant` は標準構成に含めない。

## 受入条件

- Canvas/PAC は .NET 10 以上、FlowAgent/Copilot Studio は Node.js 18 以上、GitHub Copilot CLI は
  Node.js 22 以上という要件が台帳と文書で一致する。
- 3クライアントの公式導入・確認手順と、機能ごとの提供形態の違いを文書から追える。
- `check-prerequisites.ps1` は、現在の有効な台帳で従来どおりローカル確認だけを行い、テスト用の
  バージョン不足台帳で終了コード 1 と `missing` を返す。
- overlay と文書に、FlowStudio 除外、FlowAgent の停止・検証・接続参照境界、開発環境での手動接続確認がある。
- 既存の秘密情報パターン拒否、プレビュー、既存ファイル非上書きの回帰テストが成功する。

## リスクと確認

- CLI の `--version` 出力は製品ごとに異なるため、数値抽出に失敗した場合は `not-checkable` として
  表示し、存在確認だけで失敗にはしない。最低バージョンを明確に下回る場合だけ `missing` とする。
- クライアントやプラグインの実機導入はローカル認証と承認を伴うため、自動テストの対象外とする。
  各開発者が新しい会話でプラグイン／MCP一覧と読取り操作を確認する。
