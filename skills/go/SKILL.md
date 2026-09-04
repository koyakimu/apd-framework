---
name: go
description: >
  Builds a /goal condition from a Spec's Acceptance Criteria, then
  hands off Build to Claude Code's /goal loop. Use when the user
  asks to start build, begin implementation, or run /apd:go
  ("実装を開始", "ビルドを開始").
argument-hint: "<spec-file or issue#>"
---

# APD Go — Spec から /goal condition を組み立てて自律 build に入る

このスキルは APD の Build フェーズのエントリーポイント。**自前で実装ループを回さず、Claude Code の `/goal` 機能に処理を委譲する**。

`/goal` は session-scoped な「条件達成までターン継続」機能。小型評価モデル（既定 Haiku）がターン終了ごとに condition 達成を判定する。subagent やバックグラウンドシェルが動いたまま turn が終わった場合は、その turn の評価はスキップされ、バックグラウンド作業のない次の turn 終了時に判定される。APD はこの評価器に渡す condition の組み立て役に徹する。

## 責務

このスキルは以下だけを行う:

1. 対象 Spec を特定する
2. Spec を読み、condition の素材を抽出する
3. condition を組み立ててユーザーに提示する
4. 必要なら事前チェックの warning を伝える

`/goal` 自体の送信はユーザーアクションに残す (slash command は user input channel からのみ発火する)。

## 1. 対象 Spec を特定する

ユーザーの引数を優先する。引数がなければ `docs/apd/` を Glob して候補を提示する。
Spec ファイルの命名規約はプロジェクトのルール (`.claude/rules/apd/`) に従う。

## 2. Spec を読み、素材を抽出する

Read で Spec ファイル全体を読む。以下を condition 構築用に抽出する:

- spec_id, title (frontmatter)
- Acceptance Criteria の AC ID と Given/When/Then の要約
- AC Coverage テーブルから想定テスト種別
- Deliverable Previews の有無
- Decision Records への参照
- 非機能要件の委譲先（`/security-review` 等に委ねた項目）

副次的に `CLAUDE.md` と `docs/apd/design.md` を読み、テストの実行方法・コーディング規約・Success Criteria の手がかりを得る。**テストコマンドや実行手順を skill 側で推測する fallback table は持たない。AI がプロジェクトを観察して判断する**。

## 3. condition を組み立てる

condition は `/goal` の制約 (4000 字以内) に収めつつ、以下の責務カテゴリを必ず含める。具体の文言は Spec とプロジェクトに合わせて AI が組み立てる:

### 受け入れ条件
- Spec の全 AC を ID 付きで列挙する
- Given/When/Then の要約を添える

### 検証
- 自動テストが pass する (テストコマンドはプロジェクトから AI が解決)
- AC Coverage テーブルの方針に沿ったテストが実装されている
- 既存テストを壊していない
- **Spec チェックが OK** — 完了前に、ビルド担当の AI 自身が各 AC を Spec・Design と照合し「OK / ずれ / 未実装」を根拠（ファイル:行）付きで turn に明示する。ずれ・未実装があれば自律修正してから完了とする。評価器はこの照合結果を判定材料にする（別プロセスのフックではなく Build のステップとして実施）
- 非機能要件のうち委譲したもの（`/security-review` 等）の実行結果が合格（OK）であることを達成条件に含める
- **テスト実行ログ・実装変更内容・成果物の確認結果を turn の出力に surface する**
  (`/goal` 評価器はツールを呼ばないため、会話に現れた情報からのみ判定する)

### Handoff (人間に渡す準備)
- 該当する PR を作成または更新し、PR 本文に「試し方」セクションを記載する
- 「試し方」は各 AC を人間が実機で検証できる手順として書く（完成後の実機確認用）
- AI が自動検証できない AC (実機限定・外部サービス連携・人間の主観評価等) は、実装と試し方ドキュメント化をもって完了とみなす旨を明記する
- Spec ファイルへの参照を PR 本文に含める

### 制約
- Spec に書かれていない新ビジネスルールを足さない
- Spec 範囲外のリファクタリングをしない
- Decision Records があればそれに従う
- **実装中は人にエスカレーションせず完走する。判断は Spec に先出し済み、または完成後の実機確認で扱う**
- 同一論点でループしたら停止して報告
- 過大な turn / token 消費を防ぐ上限を condition に含める
- **エスケープハッチ**: Spec チェックが通らない状態が続いたら、途中までを下書き PR で残して停止し、完成後の実機確認に回す（上限ターン/時間は condition に含める）

### condition 書き方の原則

- **会話に現れる証拠で評価器が判定できる**表現にする。評価器はツールを呼ばないので、AI が turn 内で結果を surface することが前提
- 抽象的すぎる表現 ("良い品質で実装") は評価器が永遠に no を返すので避ける
- Spec の表現を可能な限り引用し、独自解釈を加えない

## 4. ユーザーに提示する

組み立てた condition と、それを `/goal` で送信するための文面をユーザーに渡す。並列化 (subagent / agent teams / dynamic workflows / `/batch`) や worktree 隔離が必要な場合はその選択肢も補足として伝える。

あわせて次の 2 点を添える:

- **auto mode で `/goal` を実行する（APD の規約）。** ステータスバーが `⏵⏵ auto mode on` であることを確認してから貼るよう案内する。Manual mode なら Shift+Tab で切り替える。`/goal` は permission mode を変えないため、Manual のままでは許可されていないツール呼び出しのたびに人間の確認が入り「Build 中は止まらない」が成立しない。auto mode でも classifier の連続ブロック・`permissions.ask`・作業ディレクトリ外の初回読み取りでは止まることを一言添える
- **提示した condition の文面は手元に残しておく。** 認証失敗・クレジット切れ・auto-compaction で解消できないコンテキスト超過・モデル利用不可のいずれかで turn が落ちると、`/goal` は notice を出して自動的にクリアされる。原因を解消したうえで同じ condition を貼り直して再開する（レート制限などの一時的なエラーでは goal は維持される）

## 5. 事前チェックの warning (任意)

condition 提示の前に、以下が観測されたら warning する:

- Spec の `decision_refs` に対応する Decision Record が見つからない
- Spec に `Deliverable Previews` が記載されているが該当成果物が未生成

warning は提示するだけで、ユーザーの判断を待つ。skill 側で自動修復しない。

## このスキルが意図的にやらないこと

- 自前のループ実装 — `/goal` が担当
- peer-review の起動 — Spec チェックは Build の condition（上記「検証」）に組み込み済みで、ビルド AI 自身が照合するため、skill 側でレビュー起動はしない
- 機械的な品質ゲート — `/goal` の評価器が会話に surface された情報から収束を判定する
- Handoff doc のファイル生成 — PR 本文に書く方針なのでファイルは作らない
- サイクル定義の更新 — GH issue + PR の link で trail が残る前提

## 失敗時の手がかり

- 評価器が永遠に no を返す → condition が抽象的すぎる。AC の文言を引用するなど具体化する
- token 消費が膨大 → condition に turn / 時間の上限を含める
- Build 中に許可プロンプトで止まる → Manual mode のまま `/goal` を貼っている。Shift+Tab で auto mode に切り替える。goal はセッションに残っているので貼り直しは不要（`/goal` で状態を確認できる）
- ツールを使わない turn が数回続く（評価器に返事するだけで進捗がない）→ Claude Code がループを止めて warning を出し、goal はセットされたまま制御がユーザーに戻る。次のプロンプトを送ると評価が再開する
- `/goal` が利用できない → 評価器は hooks の仕組みの上に載っているため、(1) Claude Code のバージョン、(2) workspace が trust されているか、(3) `disableAllHooks` が有効になっていないか、(4) managed settings で `allowManagedHooksOnly` が設定されていないか を確認する。いずれの場合もコマンド自身が理由を表示する
