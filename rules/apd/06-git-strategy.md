# APD Git 運用戦略

## ブランチ戦略

各サイクルは `main` から切った専用ブランチで作業し、完了時に PR 経由でマージする。命名は GitHub issue があれば `feat/{issue#}-{slug}` / `fix/{issue#}-{slug}` / `chore/{slug}`、issue がなければ `{type}/{slug}`（type は feat / fix / chore / refactor 等）。

Build フェーズで複数タスクを並列実行する場合は git worktree を使う。subagent は `isolation: "worktree"` でファイル隔離込みで起動できるので、APD 独自の worktree 管理スクリプトは持たない。並列が不要な小規模サイクルでは worktree を作らずブランチ上で直接作業してよい。

## コミット規約

- コミットメッセージは Conventional Commits に準拠する（`feat:`, `fix:`, `refactor:` 等）
- 関連する Spec ID / issue 番号を本文か footer に含める（例: `Refs: spec-42 / Closes: #42`）
- 1 タスク = 1 つ以上のコミット（意味のある単位でコミットする）
