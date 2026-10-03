---
name: go
description: >
  Starts Build for an approved Spec. By default builds right away in
  the current session, using the Spec's Acceptance Criteria as the
  completion checklist; optionally assembles a /goal condition for a
  long unattended run. Use when the user approves a Spec and asks to
  implement it ("この方向で実装して", "実装を開始", "ビルドを開始"),
  or runs /apd:go. If neither a Spec nor an approved Plan covers the
  work, do not build — go to apd:spec or apd:plan first.
argument-hint: "<spec-file or issue#>"
---

# APD Go — 承認済み Spec の Build

## 常に守ること

- 対象を扱う Spec（`docs/apd/spec-*.md`）も、この会話で承認された Plan も無ければ Build しない。Spec なら `apd:spec`、Plan で足りるなら `apd:plan` に進む。承認済み Plan の Build は `apd:plan` の手順で行う
- 既定はその場で Build する。達成条件を 3〜5 行に要約して会話に出し、確認のために止まらずに実装・テスト・PR まで進める。ユーザーにコマンドの入力を求めない
- ユーザーが長時間の無人実行を望んだときだけ `/goal` で Build する。手順は [goal.md](goal.md)
- 実装中は人にエスカレーションしない。Spec に無い判断は、Spec に先出し済みのものに従うか、完成後の実機確認に回す
- 達成条件の全項目（Spec チェックを含む）を満たして PR を出したら、Build 完了として報告する

## 1. 対象 Spec を特定する

引数があればそれを使う。無ければ `docs/apd/spec-*.md` から候補を提示する。

## 2. Spec を読む

Spec 全体と `docs/apd/design.md` を読み、次を拾う: AC の ID と Given/When/Then、AC Coverage のテスト種別、Deliverable Previews の有無、`decision_refs`、委譲した非機能要件（`/security-review` 等）。テストの実行方法はプロジェクトを見て決める。

次が見つかったら、Build の前に warning として伝え、ユーザーの判断を待つ:

- `decision_refs` に対応する判断が `docs/apd/decisions.md` に無い
- Deliverable Previews が記載されているのに成果物が無い

## 3. 達成条件を組み立てる

Spec の表現を引用し、会話に出した証拠で判定できる書き方にする（「良い品質で」のような抽象表現は使わない）。

**受け入れ条件**
- Spec の全 AC を ID と Given/When/Then の要約付きで列挙する

**検証**
- 自動テストが pass し、AC Coverage の方針どおりのテストがあり、既存テストを壊していない
- Spec チェック: 完了前に各 AC を Spec・Design と照合し、「OK / ずれ / 未実装」を根拠（ファイル:行）付きで会話に出す。ずれ・未実装は直してから完了とする
- 委譲した非機能要件の実行結果が OK
- テスト実行ログ・変更内容・成果物の確認結果を会話に出す

**Handoff**
- PR を作成または更新し、本文に Spec への参照と「試し方」を書く。「試し方」は各 AC を人が実機で確かめる手順にする
- 自動検証できない AC（実機限定・外部サービス・主観評価）は、実装と「試し方」の記載で完了とし、その旨を明記する

**制約**
- Spec に無いビジネスルール、Spec 範囲外のリファクタリングを足さない。`decisions.md` の判断に従う
- 同じ論点でループしたら止めて報告する
- Spec チェックが通らない状態が続いたら、途中までを draft PR で残して止め、完成後の実機確認に回す

## 4. Build する

並列化は既定で subagent（ファイルを書き換えるなら `isolation: "worktree"`）を使う。
