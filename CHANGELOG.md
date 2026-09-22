# Changelog

## [3.5.1] - 2026-09-22

### Changed — 常時ロードされる `rules/apd/` を 329 行から 199 行へ

- **重複と説明文を削り、規則は 1 つも落としていない**: `rules/apd/*.md` は `paths` frontmatter を持たないため、導入先の全セッションで起動時にまるごと読み込まれる（Claude Code の memory ドキュメント: rules without `paths` are loaded at launch）。公式の目安「1 ファイル 200 行未満」に対し 8 本合計で 329 行あり、CLAUDE.md の数倍を占めていた。「Build 中は人間に介入・問い合わせしない」は `00-principles.md` / `01-phases.md` / `02-cycle-flow.md` の 3 か所に書かれていたので `01-phases.md` に 1 回だけ残し、他は参照にした。`03-documents.md` の decisions.md 書式ブロックは `templates/decision.md` への参照に、Spec 書式は骨格だけ残して `templates/spec.md` を定義元にした。`07-next-step.md` のフロー図と現在地判定は `/apd:status` が持つ判定表と同じ内容だったので削り、案内の原則だけ残した。`01-phases.md` の並列実行の節は auto mode の規約（3.5.0）を保ったまま 1 段落に圧縮した
- 導入先は `/apd:migrate` で取り込む。`scripts/verify-migration.sh` Check 6 の文言検査（`毎ターン後` / `TaskCreate）` / `Stop フック`）は新しい 8 本で通ることを確認した

## [3.5.0] - 2026-09-05

### Changed — Build を auto mode 前提として規約化

- **「Build は auto mode で `/goal` を実行する」を規約にした**: 3.4.0 では「`/goal` は permission mode を変えない」という事実の提示に留めていたが、これは APD の中核主張である「Build 中は人間の介入ゼロ」の成立条件そのものなので、選択肢ではなく規約に組み込むと決定した。`/goal` はターンの継続を、auto mode はツール呼び出しの許可を担い、両方を揃えて初めて実装中の介入がゼロになる。auto mode への切り替えは Shift+Tab、起動時の `--permission-mode auto`、またはユーザー設定の `permissions.defaultMode`（ほかに Bash の許可プロンプトの **Yes, and switch to auto mode**）で行うが、プロジェクト設定（`.claude/settings.json`）では `auto` が効かず、プラグインが同梱できる `settings.json` のキーは `agent` と `subagentStatusLine` だけなので **APD 側からは強制できない**。そのため担保は `/apd:go` と `/apd:spec` の案内で人間に確認を促す形にした。`rules/apd/01-phases.md`（フェーズ図と「Build 中は止まらない」）、`rules/apd/00-principles.md`（介入ゼロの原則）、`skills/go/SKILL.md`（提示ステップ）、`skills/spec/SKILL.md`（承認後の案内）、`QUICKREF.md`（Build のフロー）、`APD-FRAMEWORK.md`（設計原理・機能表・Build の動作）、`README.md`、`MIGRATION.md` を更新した
- **auto mode でも止まる場面を明記**: classifier が 3 回連続または累計 20 回ブロックすると auto mode が一時停止して通常の許可プロンプトに戻る（閾値は変更不可）、`permissions.ask` に合致する操作は常に確認が入る、作業ディレクトリ外の初回読み取りは確認が入る。これらは「止まって当然の場面」として扱い、condition の文言で回避しようとしない方針を `rules/apd/01-phases.md` と `APD-FRAMEWORK.md` に書いた。あわせて `skills/go/SKILL.md` の「失敗時の手がかり」に「Build 中に許可プロンプトで止まる → Manual mode のまま `/goal` を貼っている」を追加した（公式の goal クリア条件は Met / Impossible / unrecoverable error / `/goal clear` / `/clear` で、permission mode の切り替えは含まれないため、Shift+Tab で切り替えるだけでよく貼り直しは不要）
- **調査ノートに auto mode の節と見送り判断 2 件を追記**: `docs/research/claude-code-refresh-2026-09-04.md` に §7「auto mode の要件と残る停止点」を追加し、既定の permission mode・プラン/組織/モデルの利用条件・有効化の経路・残る停止点・`-p` での挙動・subagent への適用を公式ドキュメントの原文とともに記録した。§6 には「並列 Build を dynamic workflow として同梱する」（`/goal` の評価器が使えず収束判定を再実装することになり、中間結果が会話に載らないため検証モデルが成り立たない）と「CI に `claude plugin validate --strict` を入れる」（プラグインルートの CLAUDE.md への警告で落ち、既存 CI への上積みが小さい）の見送り判断を追加した

## [3.4.0] - 2026-09-04

### Changed — Claude Code 2.1.260 に合わせて仕様記述を更新

- **`/goal` は permission mode を変えないことを明記**: APD の看板である「Build 中は人間の介入ゼロ」は `/goal` 単体では成立せず、auto mode との併用が前提。`/goal` はターンの継続だけを自動化し、ツール呼び出しの許可は permission mode の責務のままで、Manual mode では許可されていないツール呼び出しのたびに人間の確認が入る。`skills/go/SKILL.md` の提示ステップ、`rules/apd/01-phases.md` の「Build 中は止まらない」、`skills/spec/SKILL.md` の承認後の案内、`QUICKREF.md` のフロー、`APD-FRAMEWORK.md` の機能表に追記した
- **`/goal` の評価タイミングを「毎ターン後」から実際の仕様に修正**: subagent やバックグラウンドシェルが動いたまま turn が終わると、その turn の評価はスキップされ、バックグラウンド作業のない次の turn 終了時に判定される。APD は Build の並列化に subagent を推奨しているため日常的に踏む条件で、知らないと「評価器が動いていない」と誤診して condition をいじる方向に走る。バックグラウンド待ちが 30 分を超えると自動 check-in が入ること（30分 → 1h → 以降 2h ごとで初回間隔の 4 倍が上限。回数制限があるのは対話セッションの idle check-in だけで、1 goal あたりユーザーのプロンプト間で最大 3 回）も併記した
- **unrecoverable error での goal 自動クリアを `/apd:go` に追記**: 認証失敗・クレジット切れ・auto-compaction で解消できないコンテキスト超過・モデル利用不可のいずれかで turn が落ちると `/goal` は自動的にクリアされる。復旧後に貼り直せるよう、condition の文面を手元に残すことをユーザーに案内するようにした（レート制限などの一時的なエラーでは goal は維持される）
- **`/goal` が使えないときの確認項目を追加**: 評価器は hooks の仕組みの上に載っているため、Claude Code のバージョンだけでなく workspace の trust、`disableAllHooks`、managed settings の `allowManagedHooksOnly` も利用可否を左右する
- **進捗なしでのループ停止を `/apd:go` の失敗時の手がかりに追加**: ツールを使わない turn が数回続くと Claude Code がループを止めて warning を出す。goal はセットされたまま制御がユーザーに戻り、次のプロンプトで評価が再開するため、goal を貼り直す必要はない
- **Task ツールの提供条件を明記**: Claude Code 2.1.233 以降、`TaskCreate` などの Task ツール（TaskCreate/Get/Update/List・TodoWrite）は Opus 4.8 / Sonnet 5 / Fable 5 / Mythos 5 およびそれ以降のモデルでは既定で提供されず（`CLAUDE_CODE_ENABLE_TODO_TOOLS=1` で戻せる）、モデル自身が多段作業を追跡する。「in-session todo は `TaskCreate`」という指示が現行モデルで空振りしていた（`QUICKREF.md` / `APD-FRAMEWORK.md` / `rules/apd/00-principles.md`）
- **並列化の選択肢に dynamic workflows を追加**: 公式は subagents / agent view / agent teams / dynamic workflows の 4 本立てで整理しており、APD の一覧は 3 本のままだった。あわせて各手段の「人間の介入が入る箇所」を判断材料として併記した —— agent teams は既定で無効（`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` が要る）で teammate の許可プロンプトはリーダーセッションに出る、`/batch` は分解後に計画の承認を求めて一度止まる、dynamic workflows は run 中にユーザーの入力を受け付けず、run を止めうるのはエージェントの許可プロンプトだけ（無人で回すなら auto mode か allow ルールで事前に許可しておく）
- **`scripts/verify-migration.sh` に 3.4.0 以前のルール文言の検査を追加**: `.claude/rules/apd/` に「毎ターン後」「TaskCreate」が残っていれば FAIL にする（3.2.0 の Stop フック検査と同じ方式。`/apd:migrate` か `/apd:init` で最新版に更新する）
- **調査ノートを追加**: `docs/research/claude-code-refresh-2026-09-04.md` —— 2.1.218 → 2.1.260 の照合結果、現行仕様のスナップショット、および検討して採用しなかった案とその理由

### Fixed

- **`MIGRATION.md` のロールバック手順を実行可能な形に修正**: `/plugin install apd@apd-marketplace --version 2.0.0` は存在しないオプションで実行できなかった。`/plugin install` にバージョン指定は無く、marketplace の git URL に `#<ref>` を付けて ref を固定する方式が正しい。APD は過去リリース（v0.1.0〜）にも `v{version}` 形式のタグが付いている（3.3.1 で遡及付与し、以降は CI が自動付与）ので、戻したいバージョンのタグをそのまま指定できる
- **`docs/research/contract-abolishment-2026-03-15.md` にアーカイブ注記を追加**: `docs/` 配下のアーカイブ文書のうちこの 1 本だけ注記が無く（3.3.1 で他 3 本には付与済み）、現行に存在しない Phase 番号で書かれた本文が現行仕様と誤読されうる状態だった

## [3.3.2] - 2026-07-05

### Changed — リポジトリ名を実態に合わせて変更

- **リポジトリを `autopilot-development-boilerplate` → `apd-framework` にリネーム**: 実態は boilerplate（コピーして使う雛形）ではなく Claude Code プラグインとして配布されるフレームワークのため。GitHub が旧名からのリダイレクトを張るので、既存のインストール・`git clone`・`/plugin update` は動き続ける
- `plugin.json` の `repository`、`marketplace.json` の `homepage`、README のインストールコマンド、MIGRATION.md の issue URL を新名に更新
- 新しいマーケットプレイス追加コマンド: `/plugin marketplace add koyakimu/apd-framework`

## [3.3.1] - 2026-07-05

### Fixed — リポジトリ監査で見つかった不整合の一括修正

- **同梱テンプレートを現行 frontmatter モデルへ更新**: `templates/spec.md` / `design.md` / `cross-context-scenarios.md` に残っていた v2 の `cycle_ref` / `created_at` を除去し、`issue_ref` モデルに統一。従来はテンプレートから作った Spec が `verify-migration.sh` に「未移行」と FAIL 判定される自己矛盾があった
- **`templates/todo.md` の旧フェーズ表記を修正**: `Phase 0/1/2` → 現行の `Intent / Spec / Build`
- **cross-context ファイルの命名を統一**: `/apd:spec` が作るファイルを `spec-cross-context.md` → `cross-context-scenarios.md` に変更（テンプレート名と一致させ、`spec-*.md` glob によるビルド対象 Spec との混同を解消）。`rules/apd/03-documents.md` に任意ファイルとして明記
- **decisions.md フォーマットを三者統一**: `rules/apd/03-documents.md` / `templates/decision.md` / `skills/spec/SKILL.md` で食い違っていたフォーマット（Options / AI Recommendation の有無）と追記順序（「新しい判断ほど上に積む」に確定）を `templates/decision.md` を正本として統一
- **`skills/spec/SKILL.md` の v2 残骸を除去**: 廃止済み「エスカレーションポリシー」を CLAUDE.md から読む指示を削除
- **`scripts/bump-version.sh` を堅牢化**: 実行権限を付与（`./` 起動が permission denied だった）、非 semver バージョンでのエラーメッセージ追加、marketplace.json に plugin が見つからない場合のサイレント no-op を修正
- **`scripts/verify-migration.sh` の grep バグ修正**: ブラケット式 `[^\n]`（POSIX では「n と \ 以外」の意味）を `.` に修正
- **`MIGRATION.md` の陳腐化を修正**: 期待ファイル一覧の `decision-*.md` → `decisions.md`、ロールバック先の例を `--version 0.5.1` → `2.0.0` に更新（3.x 移行ガイドの直近旧版に合わせる）、backup 救出手順が verify に FAIL する per-file Decision を作らないよう decisions.md 追記方式に変更、例示ブランチ名を 3.x に
- **歴史的文書にアーカイブ注記を追加**: `docs/apd-v3-redesign.md` / `docs/apd-v3-implementation-plan.md` / `docs/research/harness-engineering-2026-04-29.md` に「実装完了済み・現行仕様の正本は rules/apd と skills」の注記を付与（存在しない hooks 等への dangling 参照の誤読防止）
- **`examples/templates/` を削除**: どこからも参照されない `templates/` の古い複製（NFR セクション欠落）だった
- **`README.md` の構成表に `migrate` skill を追加**（同 README 内のスキル表と不一致だった）
- **`.gitignore` に `.serena/` を追加**
- **CI を追加**: `.github/workflows/ci.yml` — JSON 妥当性、version 三点一致（plugin.json / marketplace.json / CHANGELOG）、SKILL.md frontmatter、テンプレートの旧 frontmatter 混入、shellcheck、スクリプト実行権限を PR ごとに検査
- **リリースタグ運用を開始**: main へのマージ後、CI が plugin.json の version から `v{version}` タグを自動付与する（`tag-release` ジョブ）。過去リリース v0.1.0〜v3.3.0 にも遡及してタグを付与した

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
