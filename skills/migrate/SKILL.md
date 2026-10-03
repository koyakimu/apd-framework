---
name: migrate
description: >
  Migrates an existing APD project to the current model: folds Patch
  files into their Spec, consolidates per-file Decision Records into a
  single decisions.md, flattens old subdirectories, updates frontmatter,
  cleans APD cruft out of CLAUDE.md (injected banners, duplicated/stale
  rules, deprecated commands), and refreshes .claude/rules/apd/ to the
  installed version. Use when the user asks to migrate APD, upgrade APD,
  run /apd:migrate, or has just updated the APD plugin.
disable-model-invocation: true
argument-hint: "[--dry-run]"
---

# APD Migrate — 既存プロジェクトを現行モデルへ移行

このスキルは **AI 判断ベースで** 既存 APD プロジェクトを現行モデルに揃える。対象は `docs/apd/` の構造だけでなく、**CLAUDE.md と `.claude/rules/apd/`** も含む。現行モデルの要点:

- ドキュメントは生きた 1 枚（差分を別ファイルで積まない、git が正史）
- 3 ファイル種別: `design.md` / `decisions.md` / `spec-{feature}.md`
- Patch ファイルは廃止 → 親 Spec に畳む
- Decision は per-file をやめて単一 `decisions.md` に集約
- Preview は任意
- 人間の確認面は GitHub（PR + issue）
- 用語・コマンド・フックは現行（3.x）に統一: **完成後の実機確認** / `/apd:go` / プラグインは Stop フックを持たない（SessionStart フックは 3.6.0 から、設計の区分を注入するためだけに持つ）
- **CLAUDE.md は「プロジェクト固有のことだけ」**。APD 汎用ルールの正本は `.claude/rules/apd/`（自動ロード）に一本化する

検証は `scripts/verify-migration.sh` で行う（プラグイン同梱）。

## 移行元のパターン

プロジェクトの現状を見て、該当するもの（複数可）を適用する:

- **0.x（サブディレクトリ構造）**: `docs/apd/{design,specs,decisions,cycles,previews}/` がある
- **1.0.x（フラット + Patch ファイル）**: `docs/apd/spec-*-patch-*.md` や `decision-*.md` が並んでいる
- **2.x → 3.x（用語・コマンド・フックの刷新）**: ドキュメント構造は現行でも、CLAUDE.md・本文・rules に旧 3.x 以前の記述が残っている。具体的には:
  - 「Acceptance」「Human Checkpoint」→ **完成後の実機確認**
  - `/apd:build` / `/apd:start` → `/apd:go`、`/apd:cycle` / `/apd:progress` は廃止（会話 + `gh`）
  - `apd:peer-review` / `apd:checkpoint` エージェント → 廃止
  - **Spec チェック Stop フック**（3.0〜3.1）→ 廃止。Build の達成条件でビルド AI 自身が AC を照合する
  - **状態サジェストフック**（3.1）→ 廃止。案内はメイン AI の常駐ルール（`07-next-step.md`）+ `/apd:status`

## 責務

- 既存 `docs/apd/`・`CLAUDE.md`・`.claude/rules/apd/` を読んで現状を把握する
- 現行モデルへの移行プランを立て、ユーザーに確認を取る
- バックアップを取った上で移行を実行する
- **CLAUDE.md から APD 由来の注入・重複・陳腐化を除去**する（プロジェクト固有は残す）
- **`.claude/rules/apd/` を最新版に更新**する
- 機械的に変換できない箇所は **手動レビュー項目として明示** する
- 完了後に `scripts/verify-migration.sh` を実行して検証する

## 手順

### 1. 前提確認

- git working tree が clean（or 専用ブランチ）であること。clean でなければ実行せず、commit/stash/別ブランチを促す
- `docs/apd/` または `.claude/rules/apd/` が存在すること（APD プロジェクトであること）
- **完全に現行モデル**（`docs/apd/` がフラット 3 種別・Patch/per-file Decision・旧サブディレクトリなし、CLAUDE.md に APD 由来の注入/陳腐化なし、rules が最新版と一致）なら "already migrated" と返して終了。**冪等**: 既に揃っている項目はスキップする

### 2. 現状把握

Glob + Read + Bash で以下を把握する:

- **docs/apd/**: 旧サブディレクトリ、`spec-*-patch-*.md`、`decision-*.md` / `D-*.md`、`preview-*/`、命名規約外ファイル
- **CLAUDE.md**: APD 由来の記述を洗い出す（次の「CLAUDE.md の掃除」の対象一覧で grep する）
- **.claude/rules/apd/**: プラグイン同梱（`${CLAUDE_PLUGIN_ROOT}/rules/apd/`）との差分を `diff` で確認。差分が「版の違い」か「プロジェクト独自カスタム」かを見分ける

### 3. 移行プランの提示と確認

何を・どう変えるか（docs / CLAUDE.md / rules）と、手動レビューに倒すものを列挙して合意を得る。`--dry-run` 引数があれば、プラン提示と「実行した場合に何が起こるか」だけ出力する（fs 操作なし）。

### 4. 実行

ユーザー合意後、Bash + Edit で順番に実行する。各ステップ後に**何をしたか**を会話に surface する。

1. **バックアップ**: `cp -R docs/apd docs/apd.backup-{timestamp}`、`cp CLAUDE.md CLAUDE.md.apd-backup-{timestamp}`（絶対消さない。専用ブランチがあればそれも保険）
2. **サブディレクトリ flat 化**（0.x の場合）: `git mv` でファイル移動
3. **Patch 畳み込み**: 各 patch を Read → 親 Spec の該当 AC を Edit で統合 + `version` 加算 → patch を `git rm`（機械的な末尾追記はしない。二重定義を避ける）
4. **Decision 集約**: 各 `decision-*.md` を Read → `decisions.md` に番号降順で追記 → 元を `git rm`
5. **frontmatter 更新**: `cycle_ref` → `issue_ref`、`amendment_id` / `patch_id` は畳み込みで除去
6. **CLAUDE.md の掃除**（下記）
7. **rules の最新化**（下記）

#### CLAUDE.md の掃除（APD 由来の注入・重複・陳腐化の除去）

CLAUDE.md には APD 由来の記述が紛れ込みやすい。汎用の APD ルールは `.claude/rules/apd/`（自動ロード）が正本なので、CLAUDE.md からは除く。**プロジェクト固有の内容は必ず残す**（技術スタック・命名規約・テストランナー・CI・配信・セキュリティ・プロジェクト状態など）。AI が節・行ごとに「汎用 APD ルールか / プロジェクト固有か」を判断する。

除去・修正の対象:

- **宣伝行**: 「**APD（Autopilot Development）フレームワーク x.y.z …で開発。詳細ルール: `.claude/rules/apd/`**」のような APD 使用宣言・バージョン入りの行 → **削除**（バージョンは腐る。APD の存在は `.claude/rules/apd/` と `docs/apd/` で判る）
- **汎用ルールの丸写し**: `.claude/rules/apd/` の内容を CLAUDE.md に重複させた節 → **削除**。典型: 「APD 準拠ルール」「並列実行・Git 戦略（…準拠）」、テスト方針の汎用部分、「Build の収束判定」、Decision 参照の一般則、生きたドキュメントの一般則。固有部分（テストランナー・モック禁止領域・ブランチ運用の独自規則など）があればそこだけ残す
- **陳腐化した記述**:
  - 「**Spec チェック Stop フック**」への言及 → 廃止済み。「Build の達成条件でビルド AI が AC を照合」に書き換え or 削除
  - 「**Build 中のエスカレーションポリシー**」の二分リスト（人間に渡す / Build 内で完結）→ 旧モデル。削除（現行は「実装中ゼロ介入・完成後の実機確認で次サイクル」）
  - 状態サジェストフックへの言及 → 削除（常駐ルール + `/apd:status`）
- **旧コマンド・旧エージェント名**: `/apd:build` `/apd:start` `/apd:cycle` `/apd:progress` `apd:checkpoint` `apd:peer-review` → 現行（`/apd:go` 等）に書き換え or 削除
- **旧用語**: 「Acceptance」「Human Checkpoint」→「完成後の実機確認」

判断に迷う節は削除せず**手動レビュー項目**に倒す。

#### rules の最新化

`.claude/rules/apd/*.md` をプラグイン同梱の最新版に更新する。上書き前に必ず差分を確認し、プロジェクト独自カスタムがあれば手動レビューに倒す:

```bash
# 差分確認（版の違いのみか、独自カスタムが入っているか）
for f in "${CLAUDE_PLUGIN_ROOT}/rules/apd/"*.md; do
  diff -q ".claude/rules/apd/$(basename "$f")" "$f" 2>/dev/null
done
# 独自カスタムが無ければ最新版で上書き
mkdir -p .claude/rules/apd
cp "${CLAUDE_PLUGIN_ROOT}/rules/apd/"*.md .claude/rules/apd/
```

### 5. 検証

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/verify-migration.sh"
```

FAIL があれば修正する。

### 6. レポート

````markdown
## 移行完了

### docs/apd/
- Patch 畳み込み (N 件) / Decision 集約 (N 件) / flat 化 (N 件) / frontmatter 更新 (N 件)

### CLAUDE.md の掃除
- 削除: 宣伝行 / 汎用ルール節（…）/ 陳腐化記述（Stop フック・エスカレーション二分リスト 等）
- 書き換え: 旧コマンド名・旧用語
- 残した: プロジェクト固有（技術スタック・テストランナー・配信・セキュリティ 等）

### .claude/rules/apd/
- N ファイルを最新版に更新（独自カスタム: なし / 手動レビューへ）

### 手動レビュー必要 (N 件)
- ...

### バックアップ
- docs/apd.backup-{timestamp}/ ・ CLAUDE.md.apd-backup-{timestamp}

### 次のステップ
1. 手動レビュー項目を対応
2. git add -A && git commit -m "chore: migrate to current APD model"
3. 動作確認後、別 PR で backup を削除
````

## 安全原則

- **バックアップを取らずに変更しない**（docs/apd/ も CLAUDE.md も）
- **判断に迷ったら手動レビュー項目に倒す**
- **CLAUDE.md はプロジェクト固有を必ず残す**: 汎用 APD ルールだけを除き、固有の規約・設定・状態は消さない
- **rules の上書きは差分確認後**: 独自カスタムを握り潰さない
- **Patch 畳み込みは内容を読んでから**、**Decision 集約は順序を保つ**
- **冪等**: 再実行しても安全。既に現行のものはスキップする

## このスキルが意図的にやらないこと

- プロジェクト固有の `src/` `tests/` の path 更新 — 手動レビュー項目に倒す
- CLAUDE.md のプロジェクト固有内容の改変 — APD 由来の汎用ルール/注入/陳腐化のみを対象にする

## ロールバック

```bash
rm -rf docs/apd && mv docs/apd.backup-{timestamp} docs/apd
mv CLAUDE.md.apd-backup-{timestamp} CLAUDE.md
git checkout -- .claude/rules/apd/
```
