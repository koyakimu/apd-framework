# APD クイックリファレンス

## フェーズ早見表

| フェーズ | 誰の時間 | やること | 成果物 | 完了の合図 |
|---------|---------|---------|--------|------------|
| **Intent** | 人間+AI | 対話で Design 文書作成 | `docs/apd/design.md` | 人間の合意 |
| **Spec** | 人間+AI | AI ドラフト → 人間確認 | `docs/apd/spec-*.md` + `docs/apd/decisions.md` | 人間の合意 |
| **Plan** | 人間+AI | Spec を作らない変更の設計を会話に提示 → 人間確認 | 会話 + PR 本文 | 人間の合意 |
| **Build** | AI 自律 | 実装 + テスト + PR | `src/` + `tests/` + PR（試し方記載済み） | 達成条件の充足（`/goal` 使用時は評価器の収束） |
| **実機確認** | 人間 | 実機で触る | merge or 差し戻し | 人間の判断 |

## スキル使用フロー

```
① 変更が発生
   └→ GitHub issue を起票（gh 環境）or todo.md に追記
      └→ 必要なら /apd:design で Design 文書を作成・更新

② 設計（コードを書く前に区分を判定。依頼するだけで AI が提案する）
   └→ 振る舞いが変わる → Spec / 変わらない・小さい → Plan / typo・数行 → 設計なし
   └→ Plan: /apd:plan で会話に設計を提示 → 承認 → ③ Build へ
   └→ Spec: /apd:spec [full|add|bugfix] で Spec ドラフト生成
   └→ full モードではスコーピング → スコープ外は backlog へ
   └→ 確認依頼箇所のみレビュー → フィードバック → 合意

③ Build
   └→ 「この方向で実装して」と承認 → AI がその場で実装開始（途中で止まらない。コマンド不要）
   └→ auto mode で実行する（規約）
   └→ 長時間の無人実行をしたいときだけ /apd:go で /goal condition を組み立てて貼る
   └→ 並列化が必要なら subagent / agent teams / dynamic workflows / /batch を使う
   └→ 完了時に PR 本文に「試し方」が記載される

④ 実機確認
   └→ 人間が PR の「試し方」に沿って実機で触る
   └→ OK → merge → issue 自動 close
   └→ NG → コメントで返す → 次サイクル（Spec 編集 等）
```

## 初回セットアップ

```
/apd:init  → ルールファイルコピー + docs/apd/ 作成 + backlog 案内
```

## 迷ったら

```
/apd:status  → 現在地と次の一手を案内（ファイル状態＋会話文脈から判定）
```

次の一手は基本的に AI が節目で自発的に案内する（`.claude/rules/apd/07-next-step.md`）。明示的に確認したいときだけ `/apd:status` を打つ。

## 人間がやること（だけ）

### Intent / Spec: 意図を決める
- Design 文書の対話的作成
- Spec ドラフトの確認依頼箇所をレビュー
- スコープの判断
- Decision Record の判断を記入

### 実機確認: 受け入れる
- PR 本文の「試し方」に沿って実機で触る
- 動く成果物が期待通りか確認
- OK なら merge、NG なら差し戻し（次サイクル）
- **コードレビューは求めない**

## 判断フロー

```
CLAUDE.md に書いてある？
  ├─ Yes → それに従う
  └─ No → リーダーエージェントが判断できる？
              ├─ Yes → リーダーが判断
              └─ No → 完成後の実機確認としてエスカレーション
```

## ファイル構成（3 種別）

```
docs/apd/
├── design.md            ← 北極星（編集し続ける）
├── decisions.md         ← 判断の追記ログ（単一ファイル）
└── spec-{feature}.md    ← 機能ごと 1 枚（編集し続ける）
```

- **ドキュメントは生きた 1 枚**。差分を別ファイルで積まない。修正は既存ファイルを編集して `version` を上げる。履歴は git が正史
- ファイルが増えるのは新機能を作るときだけ
- 成果物プレビューを作る場合のみ `docs/apd/preview-{feature}/` を追加（任意）
- `{feature}` は GitHub issue 番号があれば issue 番号（例: `spec-42.md`）、なければ短い slug

## Claude Code 機能の使い分け

| 用途 | 使う機能 |
|------|---------|
| Build の自律ループ | `/goal` |
| サイドタスクの分離 | subagent（必要なら `isolation: "worktree"`） |
| 複数セッション協調 | agent teams（experimental・既定で無効。`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` が要る） |
| 大規模並列化 | `/batch`（分解後に計画の承認を求めて一度止まる。git リポジトリ必須） |
| スクリプト化した大規模ファンアウト | dynamic workflows（プロンプトに `ultracode` を含めるか「workflow で」と頼んで起動。走っている run の確認は `/workflows`） |
| in-session todo | Task ツール（`TaskCreate` 等）。Opus 4.8 / Sonnet 5 / Fable 5 / Mythos 5 以降では既定で提供されず、モデル自身が多段作業を追跡する |
| 累積知識 | auto memory |
| backlog | GitHub issue（`gh` 環境）or `docs/apd/todo.md` |
| GitHub 連携 | ローカルの `gh` CLI で十分。GitHub Actions/routines は任意 |
| Handoff（試し方） | PR 本文 |
| 人間の確認面 | GitHub（PR + issue）。`docs/apd/` は AI の作業場で、日常的にスキャンしない |
| ドキュメント履歴 | git log / git blame（差分ファイルを積まない） |
