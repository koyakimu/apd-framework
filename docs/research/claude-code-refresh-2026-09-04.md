# Claude Code 仕様リフレッシュ調査（2026-09-04）

> **調査メモ（日付付き）**: APD 3.3.2（最終更新 2026-07-05、当時の Claude Code はおよそ 2.1.218）の記述を、Claude Code 2.1.260 と公式ドキュメントに照合した記録。
> 現行仕様の正本は公式ドキュメントであり、本書はこの日時点のスナップショット。APD の規約の正本は `rules/apd/` と各 `skills/*/SKILL.md`。

- 調査日: 2026-09-04
- 手元の Claude Code: 2.1.260（`claude --version`）
- 参照した CHANGELOG の範囲: 2.1.218 → 2.1.260

---

## 1. `/goal`（Build の自律ループ）

**結論: 健在。APD が委譲先として `/goal` を選び続ける前提は崩れていない。**

現行仕様として確認できたこと:

| 項目 | 現行仕様 |
|------|---------|
| 位置づけ | session-scoped な prompt ベース Stop hook のラッパー。1 セッションに 1 つ |
| 評価モデル | 小型の高速モデル（Claude API では既定 Haiku） |
| 評価器のツール利用 | **しない**。会話に surface された内容だけで判定する |
| 判定結果 | Not yet met / Met / Impossible の 3 値 |
| condition の長さ | 最大 4,000 字 |
| 起動 | `/goal <condition>` を送った時点で 1 ターン目が走る |
| 停止 | Met、Impossible、unrecoverable error、`/goal clear` |
| ループの一時停止 | ツールを使わない turn が数回続くと（評価器に返事するだけで進捗がない状態）Claude Code がループを止めて warning を出す。goal はセットされたまま制御がユーザーに戻り、次のプロンプトで評価が再開する |

APD の既存記述（`skills/go/SKILL.md`、`rules/apd/01-phases.md`）のうち「評価器はツールを呼ばない」「condition は 4,000 字以内」「小型評価モデルが判定する」はすべて現行仕様どおり。

### 1.1 permission mode は変わらない（今回の最重要）

> A goal doesn't change your permission mode. To let goal turns run unattended, run `/goal` in auto mode. In Manual mode, Claude still asks before tool calls that your settings don't already allow, such as the test command above.

APD の「Build 中の人間の介入をゼロにする」は、`/goal` を auto mode で走らせて初めて成立する。ターンの継続は `/goal` が、ツール許可は permission mode が担当しており、両者は別物。

### 1.2 バックグラウンド作業があると評価が繰り延べられる

> If a subagent or a background shell command is still running when a turn ends, Claude Code skips the evaluation for that turn. It evaluates at the end of the next turn that finishes with no background work running.

APD は Build の並列化に subagent を推奨しているため、この条件は日常的に踏む。「毎ターン後に判定」という記述は不正確。

バックグラウンド作業が goal を 30 分以上待たせると自動 check-in が入る。間隔は 30 分 → 1 時間 → 以降 2 時間（最初の間隔の 4 倍が上限）。対話セッションでは idle check-in が **1 goal あたりユーザーのプロンプト間で最大 3 回**で、3 回目に「次のプロンプトまで idle check-in を止める」と告知される。`CLAUDE_CODE_GOAL_CHECKIN_MINUTES` で最初の間隔を変更でき、`0` で無効。

なお、進捗が止まった場合の扱いは check-in とは別に定義されている。ツールを使わない turn が数回続くと Claude Code はループ自体を止めて warning を出す。goal はクリアされずセットされたままで、ユーザーが次のプロンプトを送ると評価が再開する。

関連する変更（CHANGELOG）:

| バージョン | 変更 |
|-----------|------|
| 2.1.234 | バックグラウンド待ちが 30 分超で自動 check-in を導入（`CLAUDE_CODE_GOAL_CHECKIN_MINUTES=0` で opt out） |
| 2.1.236 | idle セッションでも自動 check-in（30分 → 1h → 2h） |
| 2.1.239 | turn 終端の check-in も backoff するようになった／`claude --resume` のピッカーからの復元で active goal が戻るようになった |
| 2.1.246 | idle check-in を 1 goal あたりユーザーのプロンプト間で最大 3 回に制限（次のプロンプトを送るとまた 3 回まで） |

### 1.3 unrecoverable error では goal が自動クリアされる

unrecoverable error での自動クリアは 2.1.234 で入った。現行ドキュメントが挙げる次の 4 種の失敗で turn が落ちると `/goal` は自ら goal をクリアし、`Goal cleared after an unrecoverable error` で始まり `Run /goal again to continue` で終わる警告を出す:

1. 認証失敗（Claude Code 自身が資格情報を管理している場合。desktop app / VS Code 拡張 / cloud session のようにホストが管理している場合は goal は維持される）
2. クレジット残高切れ
3. auto-compaction で解消できないコンテキスト超過
4. モデルが利用できない

レート制限やサーバー過負荷などの一時的なエラーでは goal は維持される。

### 1.4 利用条件

> Claude Code makes `/goal` available under the same workspace trust rule as hooks in settings files, because the evaluator is part of the hooks system. `/goal` is also unavailable when `disableAllHooks` is `true` after settings precedence applies, or when `allowManagedHooksOnly` is set in managed settings.

公式が要件として挙げているのは workspace trust と hooks 系の設定（`disableAllHooks` / `allowManagedHooksOnly`）で、バージョン要件は挙げられていない。いずれの場合も、コマンド自身が使えない理由を表示する。

### 1.5 セッション再開

2.1.239 以降、`--continue` / `--resume <id|name>` / セッションピッカーのすべての経路で active goal が復元される。ただし condition だけが引き継がれ、**`/goal` が表示する turn 数・タイマー・token 消費のベースラインはリセットされる**。達成済み・クリア済みの goal は復元されない。なお condition に「N ターンで停止」のような上限句を入れている場合、その句を数え直すかどうかは公式ドキュメントに記載がない（評価器は会話の内容から判断するため）。

### 1.6 非対話実行

`/goal` は非対話モード（`claude -p`）・desktop app・Remote Control でも使える。`claude -p "/goal <condition>"` は 1 回の起動でループを完走まで回す。

```bash
claude -p "/goal CHANGELOG.md has an entry for every PR merged this week"
```

既定のテキスト出力では終了まで何も表示されないため、ターン数の多い goal は停止しているように見える。`--output-format stream-json --verbose` を付けると各メッセージが流れる。Ctrl+C で解決前に中断できる。

なお非対話セッションでは、idle check-in（セッションが空いている間に Claude Code が自分でターンを起こす経路）は使われず、check-in は turn 終端でのみ配送される。

**出典**: https://code.claude.com/docs/en/goal ／ CHANGELOG L456, L585-586, L671, L746-747

---

## 2. 並列実行の手段（4 本立て）

公式は並列化を次の 4 つで整理している。APD の一覧は 3 つ（subagent / agent teams / `/batch`）だったので dynamic workflows を追加した。

| 手段 | 何をくれるか | 選ぶ場面 |
|------|------------|---------|
| subagents | 1 セッション内の委譲ワーカー。自前のコンテキストで作業し要約を返す | サイドタスクでメインの会話を汚したくない |
| agent view | バックグラウンドセッションの起動と監視をまとめた画面（`claude agents`）。research preview | 独立タスクを投げて後で様子を見る |
| agent teams | 共有 task list とエージェント間メッセージを持つ複数セッション。**experimental・既定で無効** | Claude に分割・割り当て・同期までさせたい |
| dynamic workflows | 多数の subagent を回して結果を相互検証するスクリプト | 1 ターンずつでは捌けない規模、または複数パスの検証が要る |

`/batch` はこの 4 つと並ぶ別カテゴリではなく、subagent と worktree を組み合わせた既製のスキル:

> `/batch` is a skill that has Claude split one large change into 5 to 30 worktree-isolated subagents that each open a pull request. It's a packaged use of subagents and worktrees, not a separate coordination style.

公式コマンド表の定義では、`/batch` は「コードベースを調査 → 5〜30 の独立ユニットに分解 → **計画を提示して承認を求める** → 承認後に 1 ユニット 1 background subagent を worktree 隔離で spawn → 各 subagent が実装・テスト実行・PR 作成」で、git リポジトリが必須。**承認のために一度止まる**点が APD の Build と噛み合わない場合がある。

### 2.1 agent teams

- **既定で無効**。`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` を settings.json か環境変数に置かないと、teammate は一切 spawn されない
- 非対話モード（`-p`、Agent SDK）では teammate を spawn しない。Claude が名前を付けた subagent も通常の subagent として走る
- **teammate の許可プロンプトはリーダーセッションに出る**（plan approval だけが例外）。Build フェーズの「止まらない」前提と直接ぶつかる
- 共有 task list は Task ツールを持つセッションでのみ使われ、無い場合はメッセージで協調する
- 有効化すると、Claude が名前を付けた通常の subagent も teammate として起動する（意図せずチームが組まれうる）
- 複数の teammate が同じファイルを編集すると上書きになるため、teammate ごとに担当ファイルを分ける（公式 Best practices「Avoid file conflicts」）
- 既知の制限: `/resume` / `/rewind` で in-process teammate は復元されない、ネストしたチーム不可、in-process teammate はバックグラウンド subagent を起動できない、リーダーは交代できない
- 推奨サイズは 3〜5 teammate

### 2.2 dynamic workflows

- JavaScript のスクリプトが計画を持ち、ランタイムがバックグラウンドで実行する。中間結果はスクリプトの変数に留まり、Claude のコンテキストには最終結果だけが載る
- 有料プラン全般、Anthropic API、Amazon Bedrock、Google Cloud の Agent Platform、Microsoft Foundry で利用可。Pro は `/config` の Dynamic workflows 行で有効化する
- 無効化は個人向けが 3 経路（`/config` のトグル、`~/.claude/settings.json` の `disableWorkflows: true`、`CLAUDE_CODE_DISABLE_WORKFLOWS=1`）、組織向けが 2 経路（managed settings の `disableWorkflows`、Claude Code admin settings ページのトグル）。無効化すると bundled の workflow コマンドと `/workflow-authoring` skill が使えなくなり、`ultracode` キーワードも発火せず、`ultracode` は `/effort` メニューからも消える
- 実行時の上限: 同時実行は最大 16 エージェント（CPU が少ない環境ではさらに減る）、`parallel()` / `pipeline()` の 1 コールあたり 4,096 件（超えるとエラーで拒否）、1 run あたり 1,000 エージェント
- **run 中はスクリプトが人間に入力を求められない**（run を一時停止させうるのはエージェントの許可プロンプトだけ。ユーザー側からは `/workflows` で `p` 一時停止・`x` 停止ができる）。段階ごとに人の承認を挟みたいなら段ごとに別 workflow にする
- 起動は permission mode 依存: auto mode は初回のみ（ultracode 有効時はプロンプト自体が出ない）、Manual / accept edits は毎回（bundled / 保存済み / プラグインの workflow を名前で実行したときだけ "Yes, and don't ask again" を選べ、そのプロジェクトのその workflow に限り以降スキップされる。Claude がその場のタスク用に書いた script ではこの選択肢は出ないので毎回プロンプトが出る）、bypass permissions はプロンプトなし。`claude -p` / Agent SDK ではプロンプトが出ず通常の permission 評価にかかるため、`Workflow` / `Workflow(<name>)` の allow rule、auto mode、bypass permissions、`PreToolUse` hook、ホスト側の承認（`--permission-prompt-tool`、Agent SDK の `canUseTool` / `PermissionRequest` hook）のいずれかで通す
- 既定のサイズ指針は `medium`（15 エージェント未満）。この既定は 2.1.219 以降で、それ以前は `unrestricted`。変更は `/config` の Dynamic workflow size（サイズ指針自体は 2.1.202 以降）か、任意の設定ファイルの `workflowSizeGuideline` キー（2.1.219 以降。設定ファイルの値が `/config` より優先され、その間 `/config` 行は隠れる）
- 25 エージェント超、または見込みトークンが 150 万を超えると task panel の進捗行に `Large workflow` の警告が出る。25 という閾値が効くのは既定のサイズ指針のときで、サイズ指針を自分で選ぶとその指針のエージェント数が閾値になる。ultracode 有効のセッションでは警告自体が出ない。警告は助言で、run を止めも制限もしない
- プラグインでの配布も可能（プラグインルートの `workflows/` ディレクトリ、または manifest の `workflows` フィールド。`/<plugin>:<meta.name>` で起動）
- スクリプト執筆の参考は bundled skill の `/workflow-authoring`（2.1.248 以降）

**出典**: https://code.claude.com/docs/en/agents ／ https://code.claude.com/docs/en/agent-teams ／ https://code.claude.com/docs/en/workflows ／ https://code.claude.com/docs/en/commands

---

## 3. Task ツール（in-session todo）

**v2.1.233 以降、`TodoWrite` / `TaskCreate` / `TaskGet` / `TaskUpdate` / `TaskList` は Opus 4.8・Sonnet 5・Fable 5・Mythos 5 とそれ以降の同系列では既定で提供されない。**

> Those models keep track of multi-step work without a written checklist, and the tools' definitions and reminders take up context, so Claude Code leaves them out.

復活させる手段は 4 つ（`CLAUDE_CODE_ENABLE_TODO_TOOLS=1` を起動前に export、`--allowedTools` でツール名を指定、`--tools` で列挙、Agent SDK の `allowedTools` / `tools`）。ただし「これらのモデルは書き出さずに追跡できるから外している」という設計なので、APD 側から opt-in を推奨する理由は無い。バックグラウンドセッションと Claude Code on the web では、モデルに関わらず同じツールが提供される。

subagent はセッションが持っている場合のみ Task ツールを持つ（subagent のモデルは関係しない）。in-process の teammate も同様、split pane の teammate は自分のモデルで決まる。

**出典**: https://code.claude.com/docs/en/tools-reference#task-tool-availability ／ CHANGELOG L776（2.1.233）

---

## 4. プラグイン配布（APD 自身の配布経路）

- `/plugin marketplace add koyakimu/apd-framework` と `/plugin install apd@apd-marketplace` は現行の構文どおり。変更なし
- **`/plugin install` にバージョン指定オプションは無い**。公式ドキュメントの構文は `/plugin install plugin-name@marketplace-name` だけで、バージョン指定・ピン留めの記載が無く、ローカルの `claude plugin install --help`（2.1.260）が受け付ける機能オプションも `--config` / `-s, --scope` / `-y, --yes` のみ。バージョンを固定したい場合は marketplace の git URL に `#<ref>` を付けて ref を固定する（`/plugin marketplace add https://github.com/koyakimu/apd-framework.git#v2.0.0`）
- `claude plugin validate <path>` に `--json` と `--strict` がある（2.1.260 の `--help` で確認）。`--strict` の説明は "Treat warnings as errors (exit 1). Use in CI to fail on unrecognized fields, missing metadata, and other issues that the runtime tolerates." で、CI で警告をエラー扱いにしてビルドを失敗させる用途と明記されている
- プラグインが同梱できる `settings.json` は `agent` と `subagentStatusLine` の 2 キーのみ。**プラグインからセッションの環境変数は設定できない**
- プラグイン同梱の subagent では `hooks` / `mcpServers` / `permissionMode` フロントマターが無視される
- プラグインルートの `CLAUDE.md` はプロジェクトコンテキストとしてロードされない
- workflow はプラグインで配布できる。プラグインルートの `workflows/` ディレクトリに置くか、manifest の `workflows` フィールドで別の場所を指す。起動は `/<プラグイン名>:<meta.name>`

これらの制約から、調査で挙がった「APD が subagent に MCP サーバーや hooks を設定する」「`CLAUDE_CODE_*` 系の env var を APD が設定する」「`worktree.sparsePaths` を APD が設定する」といった案はいずれも実装不能、または APD の「ユーザーの CLAUDE.md / 設定を書き換えない」原則に反するため採用しない。

**出典**: https://code.claude.com/docs/en/discover-plugins ／ https://code.claude.com/docs/en/plugins ／ https://code.claude.com/docs/en/plugins-reference ／ https://code.claude.com/docs/en/workflows ／ ローカル `claude plugin install --help` / `claude plugin validate --help`（2.1.260）

---

## 5. 変更が無かった／確認だけした項目

| 項目 | 状態 |
|------|------|
| subagent の `isolation: "worktree"` | 現行。APD が独自の worktree 管理を持たない判断は維持 |
| `/batch` | 2.1.218 → 2.1.260 で変更なし（CHANGELOG に該当エントリ無し） |
| checkpointing / `/rewind` | 現行 |
| auto memory | 現行 |
| `.claude/rules/` の自動ロード | 現行。`paths:` フロントマターの無いルールは起動時に `.claude/CLAUDE.md` と同じ優先度でロードされる |
| `gh` CLI 中心の GitHub 連携 | 現行。GitHub Actions / routines を任意とする方針も維持 |
| skill フロントマター（`name` / `description` / `argument-hint` / `disable-model-invocation`） | 現行 |
| `${CLAUDE_PLUGIN_ROOT}` の展開 | 現行 |

---

## 6. 検討して採用しなかったもの

| 案 | 不採用の理由 |
|----|------------|
| Build を `/goal` から dynamic workflow に置き換える | workflow は run 中に人間の入力を受け付けず、中間結果が Claude のコンテキストに載らない。`/goal` の「会話に surface された証拠で収束を判定する」という APD の検証モデルが成立しなくなる |
| Build を `/loop` に置き換える | `/loop` は固定間隔の cron 再実行か、間隔を省いたときのモデル自身によるペース配分（dynamic mode）で回る仕組み。止めるかどうかを判断するのは作業中のモデル自身で、`/goal` のように独立した評価器が達成条件を判定する仕組みは無い。APD が必要とするのは後者 |
| APD が subagent 定義（`agents/`）を同梱する | 並列化の選択をリーダーに委ねるという方針（`01-phases.md`）に反する。プラグイン同梱 subagent では `permissionMode` / `hooks` / `mcpServers` も効かない |
| APD が hooks を同梱する | 3.2.0 で Stop フックを廃止した判断（毎 Stop の起動コスト）を覆すことになる。プラグインの hooks はセッション全体に効くため、Build 中だけに限定できない |
| `/apd:go` から agent teams を推奨する | 既定で無効なうえ、teammate の許可プロンプトがリーダーセッションに出て Build が止まる |
| ルールに `paths:` フロントマターを付けて条件ロードにする | `rules/apd/*.md` はフェーズ・プロセスの規約でファイル種別に紐づかない。特に `04-testing.md` をテストファイルに限定すると、Spec フェーズ（Test Strategy を書く場面）で読まれなくなる |
