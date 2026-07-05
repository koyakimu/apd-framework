---
name: spec
description: >
  Generates or updates Spec documents from the Design document.
  Supports three modes: full (initial generation), add (new feature
  spec), and bugfix (edit an existing spec in place). Use when the
  user asks to generate specs, add a feature spec, fix a bug spec,
  or run /apd:spec ("Spec を生成", "仕様書を作成", "機能追加の Spec",
  "バグ修正").
argument-hint: "[full|add|bugfix] [issue#?]"
---

# APD Spec — 仕様書の生成・更新

Spec フェーズの担当として、Design 文書から Spec を生成、または既存 Spec を更新する。Spec フェーズは「人間の時間」だが、AI がドラフトを生成し、人間がサマリーと確認依頼箇所だけレビューする。

**ドキュメントは生きた 1 枚**。差分を別ファイルで積まず、既存 Spec を直接編集して `version` を上げる。履歴は git が持つ。

## 事前準備

以下を読み込む:

1. `CLAUDE.md` — プロジェクト設定（技術スタック、プロジェクト固有の規約等）
2. `docs/apd/design.md` — Design 文書
3. `docs/apd/spec-*.md` — 既存 Spec（あれば）
4. `docs/apd/decisions.md` — 既存の判断ログ（あれば）
5. 対象の GitHub issue（あれば。`gh issue view {number}` で内容を取得）

## モード判定

ユーザーの指示またはトリガー種別から、実行モードを判定する:

- **full** — 初回フル Spec 生成
- **add** — 機能追加 Spec（新規 spec ファイル）
- **bugfix** — 既存 Spec の修正（in-place 編集）

不明な場合はユーザーに確認する。

---

## モード: full（初回フル Spec 生成）

### スコーピング

Design 文書の **What** セクションに記載された全機能を確認し、ユーザーと対話して**今回のサイクルのスコープ**を決定する:

1. 全機能を一覧化し、**今回のスコープ** と **スコープ外（後続サイクルで実装）** に分類する提案を行う
2. ユーザーの判断を仰ぎ、スコープを確定する
3. **スコープ外に分類された機能は backlog に記録する**。GitHub issue が使える環境では `gh issue create` で起票し、`apd:scope-out` ラベルを付ける。使えない環境では `docs/apd/todo.md` に追記する
4. 確定したスコープ内の機能についてのみ Spec を生成する

### 生成ルール

1. スコープ内の機能について Spec を作成する（機能ごと 1 ファイル）
2. **What Not** に含まれるものは絶対に Spec に入れない
3. 各 Spec は以下を含む:
   - `spec_id`: コンテキスト略称 + 連番（例: AUTH-001）
   - `issue_ref`: 関連 GitHub issue 番号（あれば）
   - `version: 1`
   - ユーザーストーリー（誰が・何を・なぜ）
   - 受け入れ条件（Given/When/Then 形式）
   - UI 記述またはモック指示（該当する場合）
   - コンテキスト境界の定義（inputs / outputs / dependencies）
   - **テスト戦略**（AC Coverage テーブル）
   - **成果物プレビュー記述**（任意。必要なときだけ）
   - **非機能要件**：測定可能なものは AC（AC-NFR-xxx）として Given/When/Then 形式で書く。測定可能な形で書けないもの（セキュリティ等）は「委譲する非機能要件」セクションに委譲先（/security-review 等）を明記する
4. コンテキスト間のデータフローが複雑な場合は `docs/apd/cross-context-scenarios.md` にまとめる（`spec-*.md` とは別名にし、ビルド対象の Spec と混同させない）
5. 判断が必要だった箇所は `docs/apd/decisions.md` に追記する

### 出力

1. **Spec ファイル群** — `docs/apd/spec-{slug}.md`。`{slug}` は issue 番号があれば issue 番号、なければ短い slug
2. **確認チェックリスト**（下記参照）
3. **確認依頼リスト**（下記参照）
4. **判断の追記** — `docs/apd/decisions.md`（判断が発生した場合）

---

## モード: add（機能追加 Spec）

### 追加ルール

1. 既存 Spec との整合性を確認し、矛盾があれば報告する
2. 新機能は **新規 Spec ファイル** として作成する（`docs/apd/spec-{slug}.md`）
3. 既存 Spec に影響がある場合は、その**既存 Spec を直接編集**して `version` を上げる（別ファイルの差分を作らない）
4. コンテキスト間データフローに影響がある場合、`cross-context-scenarios.md` を編集する

### 出力

full モードの出力に加え:

- 既存 Spec への影響分析
- 編集が必要な既存 Spec のリスト

---

## モード: bugfix（既存 Spec の修正）

### トリアージ

まず原因を判定する:

- **Spec 起因**（仕様漏れ・曖昧さ）→ 既存 Spec を編集する
- **Build 起因**（実装が Spec と合っていない）→ 「Build 起因です。実装修正のみで対応可能です。`/apd:go` で達成条件を作り `/goal` に貼って修正を開始してください」と報告

### Spec 起因の場合

該当する `docs/apd/spec-{slug}.md` を **直接編集** する:

1. 該当 AC を修正、または新しい AC を追加する
2. frontmatter の `version` を上げる
3. 変更理由は git のコミットメッセージに書く（別ファイルの差分は作らない）
4. 仕様判断が必要なら `docs/apd/decisions.md` に追記する

---

## 技術選定（decisions.md）

Spec 生成と並行して、主要な技術選定を `docs/apd/decisions.md` に追記し、ユーザーの判断を仰ぐ。技術選定は Build フェーズの前提条件となるため、Spec フェーズで確定させる。

### 判断が必要な技術選定の特定

以下の領域について、CLAUDE.md で既に確定していない項目を洗い出す:

- プログラミング言語 / ランタイム
- フレームワーク / ライブラリ
- ビルドツール / バンドラー
- データベース / ストレージ
- インフラストラクチャ / デプロイ
- その他プロジェクト固有の重要な技術選択

### 追記フォーマット

`docs/apd/decisions.md` に新しい判断を追記する（新しいものを上に積む）:

```markdown
## D-{NNN}: {判断のタイトル}
- **Date**: YYYY-MM-DD
- **Context**: {なぜこの判断が必要か}
- **Options**:
  - A: {選択肢A（AIが提案）}
  - B: {選択肢B（AIが提案）}
- **AI Recommendation**: {AIが推奨するOption}: {推奨理由の概要}
- **Decision**: {何を選んだか — ユーザーが記入}
- **Reason**: {理由 — ユーザーが記入}
- **Refs**: {関連 spec / issue}
```

フォーマットの正本は `templates/decision.md`。AI Recommendation は参考情報で、決定権は人間にある。

### ユーザーへの提示と承認

判断ドラフトを全て提示し、各項目について `Decision` と `Reason` の記入を求める。

**全ての判断にユーザーの記入が済むまで、Spec の確認を完了できない。**

### CLAUDE.md で確定済みの場合

CLAUDE.md で技術スタックが明示的に指定されている場合、判断の追記をスキップしてよい。ただし「他に検討すべき技術選択はありますか？」とユーザーに確認する。

---

## 共通出力: 確認チェックリスト

以下の充足状況を表形式でサマリーする:

| 確認項目 | 状態 | 備考 |
|---|---|---|
| 全機能に Spec が存在する | ✅/⚠️/❌ | |
| 各 Spec にユーザーストーリーがある | ✅/⚠️/❌ | |
| 各 Spec に受け入れ条件がある | ✅/⚠️/❌ | |
| 各 Spec に UI 記述がある（該当時） | ✅/⚠️/❌ | |
| コンテキスト境界が定義されている | ✅/⚠️/❌ | |
| 各 Spec にテスト戦略（AC Coverage）がある | ✅/⚠️/❌ | |
| 判断が decisions.md に記録されている（判断発生時） | ✅/⚠️/❌ | |
| 技術選定に全てユーザー判断が記入されている | ✅/⚠️/❌ | |

## 共通出力: 確認依頼リスト

推論で埋めた箇所、自信がない箇所を明示する:

```
## 確認が必要な箇所
1. [spec_id] [箇所]: [推論内容] ← 確認してください
2. ...
```

## 確認

Spec が完成したら、以下のチェックリストを提示する:

- [ ] 確認チェックリストが全て ✅ になっているか
- [ ] 確認依頼リストの各項目について判断を返したか
- [ ] decisions.md の各判断について Decision と Reason を記入したか
- [ ] What Not に含まれるものが Spec に紛れ込んでいないか

承認されたら「`/apd:go` で達成条件を作り、その出力を `/goal` に貼って実装を開始してください（ここから先、実装中は止まりません）」と案内する。修正が必要な場合はフィードバックを受けてドラフトを更新する。
