# APD Migration Guide

既存 APD プロジェクトを現行モデルへ移行する手順。0.x（サブディレクトリ構造）・1.0.x（フラット + Patch ファイル）・2.x（用語/コマンド/フックが旧式）のいずれからでも、同じ `/apd:migrate` で現行モデルに揃う。移行対象は `docs/apd/` の構造だけでなく **CLAUDE.md と `.claude/rules/apd/`** も含む。

現行モデルの要点:
- ドキュメントは生きた 1 枚（差分を別ファイルで積まない、git が正史）
- 3 ファイル種別: `design.md` / `decisions.md` / `spec-{feature}.md`
- Patch ファイル廃止 → 親 Spec に畳む。Decision は単一 `decisions.md` に集約。Preview は任意
- 人間の確認面は GitHub（PR + issue）
- 用語・コマンド・フックは 3.x: **完成後の実機確認** / `/apd:go` / プラグインは Stop・SessionStart フックを持たない
- **CLAUDE.md はプロジェクト固有のことだけ**。APD 汎用ルールの正本は `.claude/rules/apd/`（自動ロード）に一本化
- Build は auto mode で実行する（3.5.0 で規約化）。3.6.0 から既定は承認を受けてその場で実装し、`/goal` は長時間の無人実行用の任意の手段になった
- 3.6.0 で Plan 区分（`/apd:plan`）と、設計の区分を注入する SessionStart フックを追加した。`.claude/rules/apd/` を最新にするには `/apd:migrate` を実行する

## アプローチ

**AI 主導の `/apd:migrate` スキルで移行する**。スクリプトでの一括置換ではなく、AI が個々のファイルを読んで文脈を踏まえて変換する。検証は `scripts/verify-migration.sh` で行う。

理由:
- Patch ファイルの畳み込みは内容理解が要る (どの AC に対応する差分かを読んで統合)
- frontmatter フィールドの変換は値の意味解釈が要る (`cycle_ref: "C-001"` → `issue_ref: <番号 or null>` は実 issue 確認が必要)
- 本文中のパス参照置換は文脈依存 (リンクなのか歴史的言及なのか)
- 命名規約に合わないファイルの扱いは判断が要る
- CLAUDE.md の更新はプロジェクト固有

## 主な変更

| 項目 | 旧 (0.x / 1.0.x) | 新（生きたドキュメント） |
|------|---------|---------|
| ディレクトリ | `docs/apd/{design,specs,decisions,cycles,previews}/` (0.x) | `docs/apd/` フラット、3 種別のみ |
| Design | `docs/apd/design/product-design.md` | `docs/apd/design.md` |
| Spec | `docs/apd/specs/{name}.v{N}.md` | `docs/apd/spec-{feature}.md` |
| Spec 修正 | Amendment / Patch を別ファイルで積む | **既存 Spec を直接編集** (`version` を上げる)。履歴は git |
| Decision | `decisions/D-{NNN}.md` (0.x) / `decision-{NNN}.md` (1.0.x) | `docs/apd/decisions.md` (単一の追記ログ) |
| Preview | 原則必須 | **任意**。作る場合のみ `docs/apd/preview-{feature}/` |
| Cycle | `docs/apd/cycles/C-{NNN}.md` | **廃止** (GitHub issue で代替) |
| Build スキル | `/apd:build` / `/apd:start` | `/apd:go <spec>`（既定はその場で Build、`/goal` は任意） |
| サイクル開始 | `/apd:cycle` | 会話 + `gh issue create` |
| 進行確認 | `/apd:progress` | `/apd:status` + `gh issue list` + `ls docs/apd/` |
| 機械検証 agent | `apd:checkpoint` / `apd:peer-review` | **廃止** (`/goal` 評価器 + Build の Spec チェックステップ) |
| Spec チェック | Stop フック (3.0〜3.1) | **Build の達成条件**（ビルド AI が AC を照合） |
| 次コマンド案内 | 状態サジェストフック (3.1) | 常駐ルール `07-next-step.md` + `/apd:status` |
| Handoff | サイクル定義ファイル | PR 本文の「## 試し方」セクション |
| Backlog | `docs/apd/todo.md` | GitHub issue (gh 環境) / `todo.md` (フォールバック) |
| 人間の確認面 | docs/apd/ をスキャン | **GitHub (PR + issue)**。docs/apd/ は AI の作業場 |
| 用語 | "Amendment" / "Acceptance" / "Human Checkpoint" | (廃止) / **完成後の実機確認** |
| CLAUDE.md | APD 汎用ルールを丸写し・宣伝行 | **プロジェクト固有のみ**。汎用ルールは `.claude/rules/apd/` |

## 移行手順

### 1. プラグインを更新

```bash
/plugin update apd@apd-marketplace
```

### 2. プロジェクトでブランチを切る

```bash
cd /path/to/your/project
git checkout -b chore/apd-3.x-migration
```

未コミットの変更があれば commit / stash しておく。

### 3. AI 主導の移行を起動

Claude Code 内で:

```
/apd:migrate
```

AI が以下を実行する:

1. `docs/apd/`・`CLAUDE.md`・`.claude/rules/apd/` を読んで現状を把握
2. **移行プランを提示** (ファイル移動・frontmatter / 本文の書き換え・CLAUDE.md から除く APD 由来の記述・rules の更新・手動レビューが必要な箇所)
3. ユーザーが yes と返したら実行
4. バックアップ（docs/apd/ と CLAUDE.md）→ ファイル移動 → frontmatter 更新 → 本文参照更新 → **CLAUDE.md の掃除**（宣伝行・汎用ルールの丸写し・陳腐化記述・旧コマンド名を除去、固有は残す）→ **`.claude/rules/apd/` を最新版に更新**
5. `scripts/verify-migration.sh` を呼んで結果を検証
6. レポート出力 (何をしたか・手動レビュー残項目)

**`--dry-run` 引数** を付けて起動すると、プラン提示と dry-run 出力のみで fs 操作はしない。

### 4. 検証

`/apd:migrate` 内部でも呼ばれるが、手動で再実行することもできる:

```bash
bash <path-to-apd-plugin>/scripts/verify-migration.sh
```

検査項目:
- 旧サブディレクトリ (`design/`, `specs/`, `decisions/`, `cycles/`, `previews/`) が消えているか
- 旧命名 (`*.A-*.md`, `*.v{N}.md`) が残っていないか
- **Patch ファイル (`spec-*-patch-*.md`) が残っていないか**（親 Spec に畳み込み済みか）
- **per-file Decision (`D-*.md` / `decision-*.md`) が残っていないか**（`decisions.md` に集約済みか）
- 旧 frontmatter フィールド (`amendment_id:`, `patch_id:`, `cycle_ref:`) が残っていないか
- `docs/apd/`・CLAUDE.md に旧サブディレクトリパス参照がないか
- **CLAUDE.md の APD 汚れ**: 宣伝行（`APD … フレームワーク x.y.z … で開発`）、廃止済み「Spec チェック Stop フック」参照、旧「エスカレーションポリシー」二分リスト、旧コマンド/エージェント（`/apd:build|start|cycle|progress`、`apd:peer-review|checkpoint`）が残っていないか
- **`.claude/rules/apd/` の鮮度**: 存在するか、`Stop フック` 等の陳腐化記述が無いか、（`CLAUDE_PLUGIN_ROOT` 設定時）インストール済みプラグインの rules と一致するか

PASS / FAIL を表示し、FAIL があれば exit 1。

### 5. ルールファイル（`.claude/rules/apd/`）の更新

`/apd:migrate` が最新版へ更新する（上書き前に差分を確認し、独自カスタムがあれば手動レビューに倒す）。migrate を使わず手動で揃える場合は `/apd:init` でも `.claude/rules/apd/*.md` が最新版で上書きされる。

### 6. 残った手動レビュー項目を対応

`/apd:migrate` のレポートに「手動レビュー」として出た項目を順番に処理する。典型的なもの:

- 命名規約に合わなかったファイル (`random.md` 等): 用途を判断して新名で配置 or 削除
- 古い version の Spec: backup から拾うか、backup のみで済ますか
- CLAUDE.md で「汎用 APD ルールか / プロジェクト固有か」の判断が分かれた節（migrate が削除を保留したもの）
- `.claude/rules/apd/` に独自カスタムがあったファイル（最新版で上書きするか、カスタムを残すか）

### 7. 動作確認

```bash
ls docs/apd/
# 期待: design.md, decisions.md, spec-*.md, preview-*/ (任意), todo.md (gh 未使用なら)
```

新フローでサイクルを通す:

```
# Claude Code 内で (動作確認用、本物のサイクルでなくても)
/apd:status   # 現在地と次の一手が出るか
/apd:spec     # 既存 Spec が新形式で読み込めるか
/apd:go spec-{slug}.md  # /goal condition が組み立てられるか
```

### 8. コミット

```bash
git add -A
git commit -m "chore: migrate to current APD model"
```

backup ディレクトリ (`docs/apd.backup-{timestamp}/`) は安全のためコミットに含めて残し、数サイクル運用して問題なければ別 PR で削除するのが安全。

## ロールバック

問題があれば backup から戻せる:

```bash
rm -rf docs/apd
mv docs/apd.backup-{timestamp} docs/apd
mv CLAUDE.md.apd-backup-{timestamp} CLAUDE.md   # CLAUDE.md を掃除した場合
git checkout -- .claude/rules/apd/ .  # rules 更新や Edit が staged されている場合
```

または旧バージョンのタグに固定したマーケットプレースを追加し直して戻す。`/plugin install` にバージョン指定オプションは無く、git URL に `#<ref>` を付けて ref を固定する:

```
/plugin marketplace remove apd-marketplace
/plugin marketplace add https://github.com/koyakimu/apd-framework.git#v2.0.0
/plugin install apd@apd-marketplace
```

`remove` はそのマーケットプレース由来のプラグインをアンインストールするので、ロールバック時はその挙動でよい。APD は v{version} 形式のリリースタグを CI が自動付与しているので、戻したいバージョンのタグをそのまま指定できる。なお追加したマーケットプレースは指定した ref に固定されたままなので、この状態では `/plugin update` を実行しても最新版には上がらない。最新に戻すときは同じ手順で `/plugin marketplace remove apd-marketplace` してから、ref を付けずに `/plugin marketplace add koyakimu/apd-framework` を追加し直す。

## トラブルシューティング

### `/apd:migrate` が「already migrated」と返す

`docs/apd/design.md` が存在し、`docs/apd/design/` ディレクトリが存在しない場合、AI は既に移行済みと判定する。誤検知の場合は手動で対応するか、状況を AI に伝えて部分移行を指示する。

### 検証スクリプトが FAIL を返す

`scripts/verify-migration.sh` の出力を見て、FAIL 項目を特定する。よくあるケース:

- **`docs/apd/specs/` がまだ存在する**: 認識できないファイル (random.md 等) が残っているため。中身を確認して新名で配置 or 削除
- **Patch ファイルが残っている**: 親 Spec への畳み込みが漏れている。`/apd:migrate` を再実行するか、内容を手動で Spec に統合してから patch ファイルを削除
- **`amendment_id:` / `patch_id:` の frontmatter が残っている**: AI が変換漏れ。Edit で手動修正、または `/apd:migrate` を再実行
- **本文に旧パス参照が残っている**: 該当ファイルを開いて確認、コンテキスト判断して置換 or 残置

### backup から特定のファイルを救出したい

過去サイクルの意思決定で重要なものは、backup の中身（例: `docs/apd.backup-{timestamp}/cycles/C-001.md`）を読み、`docs/apd/decisions.md` に `## D-{NNN}: ...` セクションとして追記して救出する。per-file の `decision-*.md` を作ると `verify-migration.sh` の Check 2 で FAIL になるので、単一の `decisions.md` に集約すること。

## 関連スクリプトの責務分担

| ツール | 何をする | しないこと |
|--------|---------|-----------|
| `/apd:migrate` (skill) | 実際の移行 (ファイル移動・rename・frontmatter 更新・本文置換) を AI 判断で実行 | 検証は外部スクリプトに委ねる |
| `scripts/verify-migration.sh` | 新構造が成立しているかを機械的にチェック | 何も書き換えない |

## 不明点

スクリプトや移行で想定外のケースを踏んだら GitHub issue を切ってください: https://github.com/koyakimu/apd-framework/issues
