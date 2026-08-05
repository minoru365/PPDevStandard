# PPDevStandard

PPDevStandard は、Codex・Claude Code・GitHub Copilot CLI で Power Platform 開発を行うための、**独立した共通 overlay** です。

製品スキルやプラグインの実装を fork／複製せず、上流・公式の配布元をそのまま使います。PPDevStandard は、各クライアントでの採用状況、安全な運用ルール、機能ごとの診断、プロジェクトに適用するテンプレートを管理します。

## PPDevStandard が担うこと

| 層 | 所有者 | 担うこと |
| --- | --- | --- |
| 製品スキル・プラグイン | 上流・公式配布元 | 製品機能の実装と更新 |
| PPDevStandard | minoru365 | 機能台帳、クライアント互換性、安全ルール、テンプレート、doctor、canary |
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
| Canvas Apps | Canvas Authoring MCP と `.pa.yaml` 開発 | クライアント別の対応、前提確認、Git による昇格ルール |
| Power Automate / FlowAgent | 公式 FlowAgent プラグインと MCP | 停止状態で作る原則、preflight 境界、採用時の昇格ルール |
| Dataverse | specialist skills、MCP、PAC CLI、SDK | 読取り既定の境界と承認ゲート |
| Copilot Studio | YAML 作成・検証・評価スキル | クライアント互換性とクラウド変更の承認ゲート |
| Power CAT | Overflow、Code Apps／Pro-Code の評価 | 採用済みツールの台帳化とレビュー証跡のルール |

機能ごとの配布元、パッケージ識別子、前提コマンド、クライアント対応、検証境界は [`profiles/capabilities.json`](./profiles/capabilities.json) を正本とします。

## 対応クライアント

| クライアント | 導入経路 | PPDevStandard の役割 |
| --- | --- | --- |
| Codex | 開発者プロファイルの skills と MCP | 機能台帳、安全なローカル診断、プロジェクト overlay |
| Claude Code | 公式 plugin marketplace と MCP | 同じ機能台帳・安全原則の利用 |
| GitHub Copilot CLI | 公式 plugin marketplace と MCP | 同じ機能台帳・安全原則の利用 |

プラグイン導入とテナント認証は、各利用者のローカル環境で行います。このリポジトリにはテナント URL、アカウント、トークン、認証キャッシュ、ユーザー固有の MCP 設定を書きません。

## 安全に始める

変更前に `doctor` を実行し、選択した機能に必要なローカル前提を確認します。接続先の詳細は表示しません。

```powershell
pwsh -NoProfile -File scripts/doctor.ps1 -Client codex -Capability all
```

`canary` は、全機能の採用状況と、開発環境で手動確認が必要な事項を報告します。ネットワーク、認証、インストール、クラウド環境の変更は行いません。

```powershell
pwsh -NoProfile -File scripts/canary.ps1
```

## 二レーン運用

### 探索・試作

MCP と AI スキルを使い、開発環境の新規・一時的な Canvas Apps、フロー、Copilot Studio エージェント、Dataverse の試験資産を作成・検証します。このレーンで、管理済み資産の置換、削除、公開、変更は行いません。

### 採用・運用

共有、長期保守、複数環境展開、業務影響、データ・セキュリティ影響を伴う変更は、Python、Solution、YAML、版管理された Canvas 成果物、CI/CD など Git 管理された正本へ昇格します。適用前に差分をレビューします。

既存資産の操作、公開、削除、セキュリティロール、環境設定、Solution import、本番変更は、常に明示承認が必要です。

## Agent 365

Agent 365 は実験扱いで、既定では有効にしません。有効化には、Frontier／ライセンス、Azure、ID、権限、データ分類、監査、コスト、開始、廃止について個別の人によるレビューが必要です。

## 上流ツールの更新

上流のスキルやプラグインは、それぞれの公式配布元で更新します。更新後は、対象機能の台帳を更新し、開発環境で doctor／canary を確認してから、個別プロジェクトへ採用します。

PPDevStandard は上流のソースコードをコピーしないため、上流更新のたびに fork の競合を解消する必要はありません。
