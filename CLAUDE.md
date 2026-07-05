# APD Framework - 開発ルール

## バージョン管理

- 機能追加・バグ修正をコミットする際は、必ずバージョンを更新する
- バージョン更新は `./scripts/bump-version.sh <major|minor|patch>` を使用する（`plugin.json` と `marketplace.json` を一括更新）
- semver に従う: breaking change → major、機能追加 → minor、バグ修正 → patch
- リリースタグ（`v{version}` 形式、例: `v3.3.1`）は main へのマージ後に CI が自動付与する。手動で打たない
