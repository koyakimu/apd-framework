# Changelog

## [3.3.1] - 2026-07-05

### Fixed — リポジトリ監査で見つかった不整合の一括修正

- **同梱テンプレートを現行 frontmatter モデルへ更新**: `templates/spec.md` / `design.md` / `cross-context-scenarios.md` に残っていた v2 の `cycle_ref` / `created_at` を除去し、`issue_ref` モデルに統一。従来はテンプレートから作った Spec が `verify-migration.sh` に「未移行」と FAIL 判定される自己矛盾があった
- **`templates/todo.md` の旧フェーズ表記を修正**: `Phase 0/1/2` → 現行の `Intent / Spec / Build`
- **cross-context ファイルの命名を統一**: `/apd:spec` が作るファイルを `spec-cross-context.md` → `cross-context-scenarios.md` に変更（テンプレート名と一致させ、`spec-*.md` glob によるビルド対象 Spec との混同を解消）。`rules/apd/03-documents.md` に任意ファイルとして明記
- **decisions.md フォーマットを三者統一**: `rules/apd/03-documents.md` / `templates/decision.md` / `skills/spec/SKILL.md` で食い違っていたフォーマット（Options / AI Recommendation の有無）と追記順序（「新しい判断ほど上に積む」に確定）を `templates/decision.md` を正本として統一
- **`skills/spec/SKILL.md` の v2 残骸を除去**: 廃止済み「エスカレーションポリシー」を CLAUDE.md から読む指示を削除
- **`scripts/bump-version.sh` を堅牢化**: 実行権限を付与（`./` 起動が permission denied だった）、非 semver バージョンでのエラーメッセージ追加、marketplace.json に plugin が見つからない場合のサイレント no-op を修正
- **`scripts/verify-migration.sh` の grep バグ修正**: ブラケット式 `[^\n]`（POSIX では「n と \ 以外」の意味）を `.` に修正
- **`MIGRATION.md` の陳腐化を修正**: 期待ファイル一覧の `decision-*.md` → `decisions.md`、実在しないロールバック先 `--version 0.5.1` → `2.0.0`、backup 救出手順が verify に FAIL する per-file Decision を作らないよう decisions.md 追記方式に変更、例示ブランチ名を 3.x に
- **歴史的文書にアーカイブ注記を追加**: `docs/apd-v3-redesign.md` / `docs/apd-v3-implementation-plan.md` / `docs/research/harness-engineering-2026-04-29.md` に「実装完了済み・現行仕様の正本は rules/apd と skills」の注記を付与（存在しない hooks 等への dangling 参照の誤読防止）
- **`examples/templates/` を削除**: どこからも参照されない `templates/` の古い複製（NFR セクション欠落）だった
- **`README.md` の構成表に `migrate` skill を追加**（同 README 内のスキル表と不一致だった）
- **`.gitignore` に `.serena/` を追加**
- **CI を追加**: `.github/workflows/ci.yml` — JSON 妥当性、version 三点一致（plugin.json / marketplace.json / CHANGELOG）、SKILL.md frontmatter、テンプレートの旧 frontmatter 混入、shellcheck、スクリプト実行権限を PR ごとに検査

## [3.3.0] - 2026-06-29

### Changed — マイグレーションを完全化（CLAUDE.md 掃除・rules 最新化・3.x 刷新）

- **`/apd:migrate` が CLAUDE.md を掃除するようになった**: APD 由来の注入を first-class で除去。宣伝行（`APD … フレームワーク x.y.z … で開発`）、`.claude/rules/apd/` の丸写し節、陳腐化記述（廃止済みの Spec チェック Stop フック参照・旧エスカレーション二分リスト）、旧コマンド/エージェント名（`/apd:build|start|cycle|progress`、`apd:peer-review|checkpoint`）、旧用語（Acceptance/Human Checkpoint）を対象に、**プロジェクト固有は残して**整理する
- **`/apd:migrate` が `.claude/rules/apd/` を最新版に更新するようになった**: 差分確認の上でプラグイン同梱版へ更新（独自カスタムは手動レビューへ）。従来「`/apd:init` の責務」として委譲していたのを migrate に統合
- **2.x → 3.x 移行パターンを追加**: 用語・コマンド・フックの刷新（Stop フック/サジェストフック廃止、`/apd:go`、完成後の実機確認）を移行対象に明記。移行は冪等
- **`scripts/verify-migration.sh` を拡張**: CLAUDE.md の APD 汚れ（宣伝行・Stop フック参照・旧エスカレーション・旧コマンド）と `.claude/rules/apd/` の鮮度（陳腐化記述・プラグインとの差分）を検査
- **再注入の防止**: `/apd:init` と `rules/apd/00-principles.md` に「APD はユーザーの CLAUDE.md を書き換えない」ガードを追加
- `MIGRATION.md` を 3.x（CLAUDE.md 掃除・rules 最新化・新コマンド/用語）に更新

## [3.2.0] - 2026-06-28

### Changed — Spec チェックを Stop フックから Build のステップへ移管

- **Spec チェックの `type:agent` Stop フックを廃止**: Stop のたびにフルの AI エージェントを起動するため、通常のターン終わりでも毎回数十秒〜（ブロック&リトライで）最悪10分級の待ちが発生していた。`hooks/hooks.json` を削除し、apd プラグインは Stop / SessionStart フックを一切持たなくなった
- **Spec チェックを Build の達成条件に統合**: `/apd:go` が組み立てる `/goal` の condition に「ビルド AI 自身が各 AC を Spec・Design と照合し、OK/ずれ/未実装を根拠付きで surface し、ずれは自律修正してから完了」を組み込み。チェックは Build 中＝必要な場面でのみ走り、毎 Stop の起動コストはゼロ
- `rules/apd/01-phases.md` / `02-cycle-flow.md` / `skills/go/SKILL.md` を「Stop フックの番人」から「Build のステップ」に書き換え
- `docs/apd-v3-redesign.md` に §6/§8 の方針変更を注記
- トレードオフ: 「別プロセスで自己申告に頼らない」純度は下がるが、毎 Stop の遅さを解消

## [3.1.0] - 2026-06-28

### Changed — 次の一手の案内を「毎 Stop の機械的サジェスト」から「文脈を踏まえた案内」へ

- **毎 Stop の状態サジェストフックを廃止**: `suggest-next.sh` を Stop / SessionStart の両方から外し、スクリプトを削除。ファイル有無しか見ない bash フックが毎ターン案内を出すため、ノイズが多く会話の文脈を理解できなかった
- **案内役をメイン AI に移管（B）**: `rules/apd/07-next-step.md` を新設。フロー地図と「節目だけ・文脈優先・押し付けない」案内原則を `.claude/rules/apd/` 経由で常駐させ、会話全体を見られるメイン AI が的確に次の一手を案内する
- **`/apd:status` を追加（C）**: ファイル状態＋会話文脈から「現在地＋次の一手＋根拠」を返すオンデマンドのスキル。push に頼らず、迷ったときに引ける
- Spec チェック（type:agent Stop フック）は従来どおり維持

## [3.0.3] - 2026-06-28

### Fixed

- **SessionStart フックの実行エラーを修正**: `suggest-next.sh` が `hookEventName` を `"Stop"` 固定で出力していたため、SessionStart として実行されると `Hook returned incorrect event name: expected 'SessionStart' but got 'Stop'` で失敗していた。stdin の `hook_event_name` を読み取り、実際のイベント名を返すように変更

## [3.0.2] - 2026-06-28

### Fixed

- **Spec チェック Stop フックが非 APD プロジェクトで停止をブロックする問題を修正**: `docs/apd/spec-*.md` が存在しない（APD 未導入/未初期化）リポジトリでも `type:agent` Stop フックが「前提条件未達」で `ok:false` を返し、毎 Stop をブロックしていた。プロンプト冒頭に「`spec-*.md` が1つも無ければ検証対象が無いため `ok:true` で即終了（止めない）」のパススルー条件を追加

## [3.0.1] - 2026-06-28

### Fixed

- **プラグインマニフェストの検証エラーを修正**: `plugin.json` の `"hooks": "hooks/hooks.json"` フィールドがスキーマに弾かれ（`hooks: Invalid input`）プラグイン全体がロード失敗していた。フィールドを削除し、`hooks/hooks.json` の自動検出に任せる方式（公式プラグインと同じ）に変更

## [3.0.0] - 2026-06-28

### Changed (Breaking) — APD v3: 実装中ゼロ介入の自動完走モデル

- **実装中ゼロ介入の自動完走**: Build フェーズで Claude が中断なく自律的に実装を完走する設計に変更。エスカレーションポリシー（実装中の進捗確認・中断判断フロー）を廃止
- **Spec チェック導入（`type:agent` Stop フック）**: `hooks/hooks.json` に agent Stop フックを追加し、Build 完了時に自動で Acceptance Criteria 充足を検証する
- **`/apd:start` → `/apd:go` 改名（breaking）**: スタートコマンドを `/apd:go` に統一。既存ワークフローの `/apd:start` 呼び出しはすべて更新が必要
- **状態サジェストフック**: 現在のサイクル状態（Design / Spec / Build / Done）を自動推定し、次のアクションをサジェストするフックを追加
- **Acceptance を「完成後の実機確認」に再定義**: Acceptance Criteria は実装完了後の手動・自動確認手順として記述するように変更。事前仕様の羅列ではなく完成物の検証観点を書く
- **汎用 peer-review エージェント廃止**: `apd:peer-review` エージェントを削除。レビューは `/code-review` スキルで代替

## [2.0.0] - 2026-05-22

### Changed (Breaking) — 生きたドキュメントモデルへ移行
- **Patch / Amendment 概念を廃止**。Spec 修正は別ファイルの差分を積まず、**既存 Spec を直接編集して `version` を上げる**。履歴は git が正史
- **Decision を単一 `docs/apd/decisions.md` に集約**。per-file の `decision-{NNN}.md` を廃止
- **Preview を任意化**。「原則必須」をやめ、必要なときだけ `docs/apd/preview-{feature}/` を作る
- **ドキュメント種別を 3 つに**: `design.md` / `decisions.md` / `spec-{feature}.md`
- **人間の確認面を GitHub (PR + issue) と明記**。`docs/apd/` は AI の作業材料で、人間が日常的にスキャンする場所ではないと位置づけ
- `rules/apd/00-principles.md`: 「上書きしない」→「git が正史、編集し続ける」に転換
- `rules/apd/03-documents.md`: 3 種別・decisions.md 集約・GitHub 確認面に全面改訂
- `rules/apd/05-deliverable-preview.md`: Preview を任意に降格
- `rules/apd/02-cycle-flow.md`: バグ修正フローを「既存 Spec を編集」に変更
- `skills/spec`: bugfix モードを「既存 Spec を編集して version 上げ」に変更、decisions.md 追記方式、Patch ファイル生成を削除
- `skills/migrate`: Patch のSpec畳み込み・Decision の decisions.md 集約に対応（0.x / 1.0.x 両方から移行可能に）
- `scripts/verify-migration.sh`: Patch ファイル・per-file Decision・`patch_id:` frontmatter の残存チェックを追加
- `templates/decision.md`: 単一ファイル形式から decisions.md の 1 セクション形式に変更

### Removed (Breaking)
- `templates/spec-patch.md` / `examples/templates/spec-patch.md` — Patch ファイルが不要になったため削除

### Why
pup での実投入で `docs/apd/` にファイルが増えすぎて見通しが悪化。「ファイル移動を前提にすると移動漏れが出る」「Claude が書くので人間は repo をほぼ見ない」という実感を踏まえ、**移動を前提にしない・git を正史とする・人間は GitHub を見る**モデルへ転換した。

## [1.0.2] - 2026-05-19

### Added
- `skills/migrate/` — `/apd:migrate` スキル。AI 主導で 0.x → 1.x マイグレーションを行う。frontmatter 解釈・本文参照置換・手動レビュー仕分けを AI 判断で実施。`--dry-run` 引数対応
- `scripts/verify-migration.sh` — マイグレーション結果の検証スクリプト。旧サブディレクトリ・旧命名・旧 frontmatter・旧パス参照の残存を機械的にチェック。書き換えは一切行わない (チェックのみ)
- `MIGRATION.md` — 旧→新マイグレーションガイド。AI 主導の `/apd:migrate` を主、`verify-migration.sh` を検証手段として位置づけ。手順・ロールバック・トラブルシューティングを記載

### Notes
- 一括 shell スクリプトでの自動移行ではなく **AI に判断させる** 方針を採用 (frontmatter の値・本文中の参照・命名規約に合わないファイルの扱いは文脈判断が要るため)
- スクリプトは検証専門に責務分離

## [1.0.1] - 2026-05-19

### Changed
- **Skill frontmatter を Anthropic 公式規約に整合**:
  - `tools:` フィールドを全 4 skill から削除（skills には `allowed-tools` が正規。`tools:` は subagent 用フィールドで no-op だった）
  - `description` を「[What it does]. Use when ...」順に書き換え（公式ベストプラクティス: 主要ユースケースを先頭に）
  - `skills/init` に `disable-model-invocation: true` を追加（FS 書き込みの副作用があるため自動起動を抑制）
  - `skills/spec` に `argument-hint: "[full|add|bugfix] [issue#?]"` を追加
  - `skills/start` に `argument-hint: "<spec-file or issue#>"` を追加
- **GitHub Actions の必須印象を軽減**:
  - `APD-FRAMEWORK.md` / `QUICKREF.md` で「ローカルの `gh` CLI で十分。Actions/routines は任意」と明記
  - 個人開発・少人数チームでは GitHub Actions を立てる必要がない旨を追加

## [1.0.0] - 2026-05-18

### Removed (Breaking)
- `skills/build/` — `/apd:build` スキルを廃止（Build フェーズは `/apd:start` + Claude Code `/goal` に移行）
- `skills/cycle/` — `/apd:cycle` スキルを廃止（サイクル開始は会話 + `gh issue create` で十分）
- `skills/progress/` — `/apd:progress` スキルを廃止（`gh issue list` + `ls docs/apd/` + `/memory` で代替）
- `agents/checkpoint.md` — `apd:checkpoint` agent を廃止（Build の収束判定は `/goal` 評価器が担当）
- `templates/cycle.md` `examples/templates/cycle.md` — サイクル定義ファイルが廃止のためテンプレも削除

### Changed
- **README.md** を新方針で書き直し（4 スキル構成、Acceptance 用語、Claude Code 機能との分担を明記）
- **QUICKREF.md** を新方針で書き直し（Intent / Spec / Build / Acceptance の 4 フェーズ早見表、フラットファイル命名）
- **APD-FRAMEWORK.md** を全面改訂（薄い規約レイヤとして Claude Code 機能に委譲する設計原則を明記）
- **agents/peer-review.md** のパス参照を新フラット構造に更新

### Migration Notes
旧 APD を使っているプロジェクト:

1. `/apd:build` → `/apd:start <spec ファイル>` に置き換え + `/goal` で実行
2. `/apd:cycle` → 会話で「新機能追加します」等で十分、issue があれば `gh issue create`
3. `/apd:progress` → `gh issue list` + `ls docs/apd/` + `/memory`
4. `apd:checkpoint` agent → 不要（`/goal` 評価器が担う）
5. ドキュメントツリーは PR-1 で flat 化済み（`docs/apd/{sub}/` → `docs/apd/*.md`）

## [0.7.0] - 2026-05-18

### Changed
- **用語**: `Amendment` → `Spec Patch` に変更（差分ドキュメントの呼称）
- **ディレクトリ構造**: `docs/apd/` をフラット化。`design/` `specs/` `decisions/` `cycles/` `previews/` サブディレクトリを廃止し、prefix 命名で分類する方針へ（`design.md`, `spec-{slug}.md`, `decision-{NNN}.md`, `preview-{slug}/`）
- **rules/apd/*.md** を新方針に全面改訂:
  - `Human Checkpoint 2` → `Acceptance` に用語変更
  - `AI Checkpoint` 機構を廃止し、Build の収束判定を Claude Code の `/goal` 評価器に委譲
  - handoff document（コンテキストリセット引き継ぎ用ファイル）の規定を削除
  - 3 点突合（評価軸 × evidence × toolcall）の規定を削除
  - サイクル別ディレクトリ構造（`cycles/C-{NNN}/{handoffs,evidence}/`）を廃止
  - サイクル ID（C-{NNN}）採番規定を削除、issue 番号や slug を推奨
  - ブランチ命名規約を `apd/C-{NNN}/*` から Conventional Commits 系（`feat/{issue#}-{slug}` 等）へ
  - 並列実行は Claude Code の subagent / agent teams / `/batch` を使う旨を明記
- **Handoff の場所**: ファイル化せず PR 本文の「## 試し方」セクションに記載する方針に変更
- **skills/init**: フラット構造で `docs/apd/` のみ作成。`gh` 検出時は `todo.md` をスキップして GitHub issue を一次 backlog として案内
- **skills/design**: 出力先を `docs/apd/design/product-design.md` → `docs/apd/design.md` に変更、`Human Checkpoint 0` 用語を削除
- **skills/spec**: パスを新フラット構造に対応、`Amendment` → `Spec Patch` に変更、最終案内を `/apd:build` → `/apd:start` に変更、issue 番号からの Spec 生成サポート追加（`gh issue view`）

### Removed
- `templates/amendment.md` → `templates/spec-patch.md` にリネーム

### Notes
- 旧スキル `/apd:build` `/apd:cycle` `/apd:progress` および `apd:checkpoint` agent は本 PR では削除せず、PR-3 でまとめて整理する
- `README.md` `QUICKREF.md` `APD-FRAMEWORK.md` の改訂も PR-3 で実施（旧スキル削除と同時の方が記述に一貫性が出るため）

## [0.6.0] - 2026-05-18

### Added
- `skills/start/` — `/apd:start` スキルを追加。Spec の Acceptance Criteria から Claude Code の `/goal` コマンド向け condition を組み立て、自律 build ループを `/goal` に委譲する薄いラッパー。既存の `/apd:build` と並存させた状態で新方針 (`/goal` 中心化) の動作を実環境で検証するプロトタイプ

## [0.4.0] - 2026-03-14

### Changed
- **Contract廃止・Phase統合** — Phase 2 (Contract) と Phase 3 (Execute) を Phase 2 (Build) に統合。Contractドキュメントを廃止し、SpecにTest StrategyとDeliverable Previewsセクションを吸収
- **フェーズ構成を3フェーズに簡素化** — Design → Spec → Build（旧: Design → Spec → Contract → Execute）
- **成果物プレビューの配置を変更** — `docs/apd/contract/previews/` → `docs/apd/previews/`
- **tech_changeフローの簡素化** — Contract Amendment → Execute から Decision Record → Build に変更
- **Checkpointエージェントを簡素化** — Phase 2 (Contract) レビューチェックリストを廃止し、Build用の統合チェックリストに変更
- **Peer ReviewからContract/Interface Compliance観点を除去** — Spec Complianceに集約

### Removed
- `skills/contract/` — Contractスキルを廃止
- `skills/execute/` — Executeスキルを廃止（`skills/build/` に統合）
- `templates/contract.md` — Contractテンプレートを廃止
- `docs/apd/contract/` — Contractディレクトリをドキュメントツリーから廃止

### Added
- `skills/build/` — Build スキル（旧Contract + Execute の統合）
- Specテンプレートに `Test Strategy` セクション（AC Coverageテーブル）を追加
- Specテンプレートに `Deliverable Previews` セクションを追加

## [0.3.1] - 2026-03-08

### Removed
- **SessionStartフック (`check-init.sh`) を削除** — 未初期化プロジェクト検知フックを廃止し、`hooks/hooks.json` を空に変更

## [0.3.0] - 2026-03-08

### Changed
- **Human Checkpoint 2 (Contract) を廃止** — AI Checkpoint通過後に自動承認する方式に変更。エスカレーション項目がある場合のみ人間に確認
- **Human Checkpoint 3 を「完成品確認」に変更** — 動く成果物が意図通りか確認する。コードレビューはフレームワークとして求めない
- **Peer Reviewに対立的検証（Adversarial Testing）を追加** — 積極的に壊しにいく視点で障害ケースを探索する観点を追加
- **ExecuteスキルにBDDテスト自動生成の指示を追加** — SpecのGiven/When/Then ACから直接テストコードを生成

### Updated
- `rules/apd/01-phases.md` — フェーズ定義とCheckpoint原則を新方針に更新
- `agents/checkpoint.md` — サマリー出力形式を新方針に合わせて更新
- `agents/peer-review.md` — 対立的検証の観点を追加
- `APD-FRAMEWORK.md` — 全面改訂（Mermaid図追加、新方針反映）
- `QUICKREF.md` — 新フロー・ToDo管理を反映

## [0.2.0] - 2026-03-08

### Added
- **ToDo管理の仕組み** — `docs/apd/todo.md` でサイクル横断のバックログをappend-onlyで管理
- **スコーピング** — Spec (full mode) でDesignの全機能を今回のスコープ/スコープ外に分類し、スコープ外の機能はToDoに記録
- **ToDoテンプレート** — `templates/todo.md` を追加

### Changed
- Design/Executeスキルに対話・実装中のToDo記録指示を追加
- Cycleスキルにtodo.md参照を追加（未着手ToDoを提示して次の作業を提案）
- Initスキルにtodo.md初期化を追加

## [0.1.0] - 2026-03-08

### Added
- **バージョンバンプスクリプト** — `scripts/bump-version.sh` で `plugin.json` と `marketplace.json` を一括更新
- **CLAUDE.md** — バージョン管理ルールを記載

### Changed
- 初期バージョンを `0.1.0` に設定（`1.0.0` から変更）

### Fixed
- **Phase 0 Designスキルに技術選定の混入防止ガードレールを追加** — ユーザーから技術スタック情報が提供された場合にDesign文書に含めず、Phase 1に移管する仕組みを導入
