# APD Plugin — Autopilot Development Framework

> **人間は意思決定だけ、AI が自律で完走する**

Autopilot Development（APD）は、AI エージェントが自律的にソフトウェアを開発し、人間は「意図を決める」と「完成後の実機確認」の2点のみで関わる開発フレームワークです。Claude Code プラグインとして提供されます。

## フロー

```
意図・Spec ← 人間+AI（意図を固め、Spec を承認）
   ↓
Build      ← AI 自律完走（途中で止まらない）
   ↓
実機確認   ← 人間が実機で触って受け入れ
```

人間は **意図を決める**（Intent / Spec 承認）と **完成後の実機確認** の2点のみ担当する。Build 中の進行管理・並列化・タスク追跡・品質ゲートは Claude Code 本体の機能（`/goal`、subagent、agent teams、hooks）に委譲する。APD は薄い規約レイヤに留まる。

## インストール

```bash
# マーケットプレース追加
/plugin marketplace add koyakimu/apd-framework

# プラグインインストール
/plugin install apd@apd-marketplace
```

## プロジェクトへの初期化

プロジェクトディレクトリで:

```
/apd:init
```

これにより:

- `.claude/rules/apd/` にフレームワーク方針がコピーされる（Claude Code が自動ロード）
- `docs/apd/` ディレクトリが作成される（フラット構造）
- `gh` が使える環境では GitHub issue を一次 backlog として案内、使えない環境では `docs/apd/todo.md` をフォールバックとして作成

## スキル

| コマンド | 役割 |
|---------|------|
| `/apd:init`    | プロジェクト初期化 |
| `/apd:design`  | Design 文書（北極星）の対話的作成 |
| `/apd:spec`    | Spec ドラフト生成・更新（full / add / bugfix モード） |
| `/apd:go`      | 達成条件を作り `/goal` に貼って起動（Spec の AC → condition 組み立て） |
| `/apd:status`  | 現在地と次の一手を案内（ファイル状態＋会話文脈から判定） |
| `/apd:migrate` | 既存プロジェクトを現行のドキュメント構造へ移行（[MIGRATION.md](MIGRATION.md) 参照） |

`docs/apd/` は **生きた 3 ファイル** で構成される: `design.md`（北極星）、`decisions.md`（判断ログ）、`spec-{feature}.md`（機能ごと）。ドキュメントは編集し続け、履歴は git が持つ。人間の確認面は GitHub（PR + issue）。

詳細は `QUICKREF.md`、設計原理は `APD-FRAMEWORK.md` を参照。

## プラグイン構成

| パス | 内容 |
|------|------|
| `.claude-plugin/plugin.json` | プラグインマニフェスト |
| `skills/` | スラッシュコマンド（`init`, `design`, `spec`, `go`, `status`, `migrate`） |
| `rules/apd/` | フレームワーク方針（`/apd:init` でプロジェクトにコピー） |
| `templates/` | ドキュメントテンプレート |

## ライセンス

MIT
