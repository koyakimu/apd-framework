# APD ドキュメント管理

## 生きたドキュメント + git が正史

- ドキュメントは **作ったら同じ場所で編集し続ける**。差分を別ファイル（Amendment / Patch）で積まない。移動を前提にしない（移動漏れと不整合の元）
- 「過去どうだったか」は **git log / git blame** が正史。AI の作業記録はコミットログと PR 履歴、人間の判断記録は `decisions.md`（単一の追記ログ）

## ドキュメントツリー

```
docs/apd/
├── design.md            ← 北極星（編集し続ける、滅多に変わらない）
├── decisions.md         ← 判断の追記ログ（単一ファイル）
└── spec-{feature}.md    ← 機能ごと 1 枚（編集し続ける）
```

- サブディレクトリは作らない。ファイルが増えるのは新機能を作るときだけ
- 機能が削除されたら、その機能の Spec も削除する（これが唯一の「削除」）
- 成果物プレビューを作る場合のみ `docs/apd/preview-{feature}/` を追加（任意。`05-deliverable-preview.md`）
- コンテキスト間のデータフローが複雑な場合のみ `docs/apd/cross-context-scenarios.md` を追加（任意。`spec-*.md` とは別名にし、ビルド対象の Spec と混同させない）
- `docs/apd/` 内に人間用ダッシュボード（INDEX 等）は置かない。人間が見るのは `gh issue list`（進行中・backlog）、PR の「試し方」（個別の変更の受け入れ）、`design.md`（全体像）
- `spec-{feature}.md` の `{feature}` は GitHub issue 番号があれば issue 番号、なければ短い slug。Spec ID は frontmatter で別途定義する（`spec_id: "AUTH-042"` 等）

## Spec フォーマット（Markdown + YAML frontmatter。エラーケース・非機能 AC や委譲する非機能要件まで含む完全版は `${CLAUDE_PLUGIN_ROOT}/templates/spec.md`）

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
**As a** {誰が} / **I want** {何を} / **So that** {なぜ}

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

バグ修正・仕様変更は **既存 Spec を直接編集** する。該当 AC を修正 or 追加し、frontmatter の `version` を上げ、変更理由は git のコミットメッセージに書く（別ファイルに差分を残さない）。

## decisions.md フォーマット

技術選定・設計判断は単一の `docs/apd/decisions.md` に追記する。新しい判断ほど上に積む。1 判断ぶんのブロックのフォーマットの定義元は APD プラグイン同梱の `${CLAUDE_PLUGIN_ROOT}/templates/decision.md`。Spec から特定の判断を参照したい場合は `decisions.md#d-001` のようにアンカーで引く。
