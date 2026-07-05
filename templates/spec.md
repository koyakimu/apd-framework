<!-- Specテンプレート: YAML frontmatter + Markdown -->
<!-- CLAUDE.mdのデフォルトSpecフォーマットに準拠 -->

---
spec_id: "{CONTEXT_ID}-{NNN}"   # 例: OM-001
context: "{コンテキスト名}"       # 例: order-management
version: 1
issue_ref: "{GitHub issue 番号、なければ null}"
title: "{機能タイトル}"
decision_refs: []
# - D-001
# - D-002
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

### AC-002
- **Given**: {前提条件}
- **When**: {トリガーとなる操作}
- **Then**: {期待される結果}

### AC-003 (Error Case)
- **Given**: {エラーが起きる前提条件}
- **When**: {操作}
- **Then**: {エラー時の期待動作}

### AC-NFR-001 (Non-Functional / 測定可能な場合のみ)
- **Given**: {前提（負荷・環境など）}
- **When**: {操作}
- **Then**: {測定可能な閾値（例: p95 < 200ms、a11y スコア ≥ 90）}

## UI Description

{画面の構成、主要要素、インタラクションの説明}
{モックツールへの指示がある場合はここに記載}

## Context Boundary

### Inputs
- **From**: {入力元コンテキスト or 外部} — {データの説明}

### Outputs
- **To**: {出力先コンテキスト or 外部} — {データの説明}

### Dependencies
- **{依存するコンテキスト}**: {依存理由}

## Test Strategy

### AC Coverage

| AC ID | Test Type | Description |
|-------|-----------|-------------|
| AC-001 | unit / integration / e2e | {テスト内容} |
| AC-002 | unit / integration / e2e | {テスト内容} |
| AC-003 | unit / integration / e2e | {テスト内容} |
| AC-NFR-001 | 計測 / `/security-review` 等の委譲先 | {測定方法・委譲先の合格基準} |

## Deliverable Previews

{生成すべきプレビューの種別と説明（該当する場合）}
{例: アーキテクチャ図、UIモック、API仕様書、データモデル図 など}

## 委譲する非機能要件
- セキュリティ等、AC に測定可能な形で書けないものは委譲先（/security-review 等）を明記し、その結果を Build の達成条件に含める。

## Notes

{追加の考慮事項、制約、前提など}
