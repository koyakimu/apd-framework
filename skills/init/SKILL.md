---
name: init
description: >
  Initializes APD in this project. Copies framework rules to
  `.claude/rules/apd/` and creates the `docs/apd/` document
  directory. Use when the user asks to initialize APD, set up
  APD, or run /apd:init ("APD を初期化", "APD をセットアップ"), or
  when the user agrees to a proposal to initialize APD. Never run it
  without the user's explicit agreement.
---

# APD Init — プロジェクト初期化

APD フレームワークをプロジェクトに初期化する。ルールファイルのコピーとドキュメントディレクトリの作成を行う。

## 手順

### 1. 既存状態の確認

以下を確認する:

- `.claude/rules/apd/` が既に存在するか
- `docs/apd/` が既に存在するか
- `gh auth status` が成功するか（GitHub issue を一次 backlog として使うか判定）

既に APD が初期化されている場合は「ルールファイルを最新版に更新しますか？」とユーザーに確認する。

### 2. ルールファイルのコピー

プラグインに同梱されているルールファイルをプロジェクトにコピーする:

```bash
mkdir -p .claude/rules/apd
cp "${CLAUDE_PLUGIN_ROOT}/rules/apd/"*.md .claude/rules/apd/
```

### 3. ドキュメントディレクトリの作成

フラット構造で `docs/apd/` を作成する。サブディレクトリは作らない（必要になった時点で作る）:

```bash
mkdir -p docs/apd
```

### 4. backlog の初期化

`gh auth status` が成功した環境では GitHub issue を一次 backlog として使う方針なので `docs/apd/todo.md` は作らない。`gh` が使えない環境ではフォールバックとして `todo.md` を作成する:

```bash
if ! gh auth status >/dev/null 2>&1; then
  if [ ! -f docs/apd/todo.md ]; then
    cp "${CLAUDE_PLUGIN_ROOT}/templates/todo.md" docs/apd/todo.md
  fi
fi
```

### 5. 完了メッセージ

以下を出力する:

```
## APD 初期化完了

コピーされたもの:
  - .claude/rules/apd/  — APD フレームワーク方針（Claude Code が自動ロード）

作成されたもの:
  - docs/apd/           — APD ドキュメントの置き場所（フラット構造）
  {gh が使えない場合: }
  - docs/apd/todo.md    — ToDo backlog（フォールバック。gh が使える場合は GitHub issue を使う）

backlog の運用:
  {gh 検出時: }
  - GitHub issue を一次 backlog として使う
  - 起票時に apd:todo / apd:scope-out などのラベルを付けて分類する
  {gh 不在時: }
  - docs/apd/todo.md に append-only で追記する

次のステップ:
  /apd:design で Design 文書を作成（既にあれば /apd:spec へ）
```

## 注意事項

- ルールファイルは `.claude/rules/apd/` にコピーされ、Claude Code が自動でコンテキストにロードする
- `docs/apd/` はフラット構造。サブディレクトリは「必要になったら作る」原則
- 次回のセッションから APD フレームワークのルールが自動適用される
- **CLAUDE.md は変更しない。** APD の使用宣言やバージョンを CLAUDE.md に書き込まない（APD の存在は `.claude/rules/apd/` と `docs/apd/` で判る。バージョン入りの行は腐る）。CLAUDE.md はユーザーのもの
