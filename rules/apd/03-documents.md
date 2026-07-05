# APD ドキュメント管理

## 生きたドキュメント + git が正史

- ドキュメントは **作ったら同じ場所で編集し続ける**。差分を別ファイル（Amendment / Patch）で積まない
- 「過去どうだったか」は **git log / git blame** が正史
- AI の作業記録: Git コミットログ + PR 履歴
- 人間の判断記録: `decisions.md`（単一の追記ログ）

ファイルを移動・追加し続けると移動漏れや不整合が出る。**移動を前提にしない**設計にする。

## ドキュメントツリー（3 ファイル種別）

```
docs/apd/
├── design.md            ← 北極星（編集し続ける、滅多に変わらない）
├── decisions.md         ← 判断の追記ログ（単一ファイル）
└── spec-{feature}.md    ← 機能ごと 1 枚（編集し続ける）
```

- サブディレクトリは作らない
- ファイルが増えるのは **新機能を作るとき** だけ（本質的な増加なので許容）
- 機能が削除されたら、その機能の Spec も削除する（これが唯一の「削除」）
- 成果物プレビューを作る場合のみ `docs/apd/preview-{feature}/` を追加（任意。`05-deliverable-preview.md` 参照）
- コンテキスト間のデータフローが複雑な場合のみ `docs/apd/cross-context-scenarios.md` を追加（任意。`spec-*.md` とは別名にし、ビルド対象の Spec と混同させない）

### 命名の指針

- `spec-{feature}.md` の `{feature}` は GitHub issue 番号があれば issue 番号、なければ短い slug
- Spec ID は frontmatter で別途定義する（`spec_id: "AUTH-042"` 等）

## 人間の確認面 = GitHub

`docs/apd/` の spec 群は **AI の作業材料**。人間が日常的にスキャンする想定ではない。人間が見るのは:

| 知りたいこと | 見る場所 |
|------------|---------|
| 進行中・backlog | `gh issue list`（自動更新、同期不要） |
| 個別の変更を受け入れたい | その PR の「試し方」セクション（完成後の実機確認） |
| プロダクト全体像 | `docs/apd/design.md` |

`docs/apd/` 内に「人間用ダッシュボード（INDEX 等）」は置かない。同期対象が増えて移動漏れと同類のリスクになるため。GitHub（issue + PR）を人間のダッシュボードとして使う。

## Spec フォーマット

Markdown 形式（YAML frontmatter付き）。Spec は編集し続ける生きたドキュメントなので、`version` を上げて変更を反映する。

````markdown
---
spec_id: "{CONTEXT_ID}-{NNN}"
context: "{コンテキスト名}"
version: 1
issue_ref: "{GitHub issue 番号、なければ null}"
title: ""
decision_refs: []
---

## User Story

**As a** {誰が}
**I want** {何を}
**So that** {なぜ}

## Acceptance Criteria

### AC-001
- **Given**: {前提条件}
- **When**: {トリガーとなる操作}
- **Then**: {期待される結果}

## UI Description

{モック or UI 記述（該当する場合）}

## Context Boundary

### Inputs
- **From**: {入力元} — {データの説明}

### Outputs
- **To**: {出力先} — {データの説明}

### Dependencies
- **{依存するコンテキスト}**: {依存理由}

## Test Strategy

### AC Coverage

| AC ID | Test Type | Description |
|-------|-----------|-------------|
| AC-001 | unit / integration / e2e | {テスト内容} |

## Deliverable Previews

{生成すべきプレビューの種別と説明（任意。該当する場合のみ）}

## Notes

{追加の考慮事項、制約、前提など}
````

### Spec の更新

バグ修正・仕様変更は **既存 Spec を直接編集** する:

1. 該当 AC を修正 or 追加する
2. frontmatter の `version` を上げる
3. 変更理由は git のコミットメッセージに書く（別ファイルに差分を残さない）

## decisions.md フォーマット

技術選定・設計判断は単一の `docs/apd/decisions.md` に追記する。新しい判断ほど上に積む。フォーマットの正本は `templates/decision.md`。

````markdown
# Decisions

## D-002: {判断のタイトル}
- **Date**: YYYY-MM-DD
- **Context**: {なぜこの判断が必要だったか}
- **Options**:
  - A: {選択肢A（AIが提案）}
  - B: {選択肢B（AIが提案）}
- **AI Recommendation**: {AIが推奨するOption}: {推奨理由の概要}
- **Decision**: {何を選んだか — ユーザーが記入}
- **Reason**: {理由・トレードオフ}
- **Refs**: {関連 spec / issue}

## D-001: {判断のタイトル}
- ...
````

Spec から特定の判断を参照したい場合は `decisions.md#d-001` のようにアンカーで引く。
