---
name: plan
description: >
  Writes a lightweight implementation plan (goal, files and approach,
  alternatives considered, how to verify) in the conversation, gets
  the user's approval, then builds without stopping. No Spec file is
  created and APD does not need to be initialized. Use before writing
  code for a change that does not alter user-visible behavior or is
  too small for a Spec — refactoring, internal technical changes,
  dev tooling / infra / config, scripts, multi-file fixes — even if
  the user did not ask for a plan. Also use when the user asks for a
  plan or runs /apd:plan ("設計して", "方針を出して", "Plan を作って").
  Skip it for typos, config value changes, few-line edits, and bug
  fixes whose cause and fix are both obvious.
---

# APD Plan — 軽い設計（Spec を作らない変更）

Spec を作るほどではない変更の設計を会話に出し、承認を得てから Build に入る。ファイルを作らないので、APD を初期化していないリポジトリでも使う。

## 常に守ること

- Plan の承認を得るまでコードを書かない
- 承認後は実装・テスト・PR まで止まらずに進める。ユーザーにコマンドの入力を求めない
- 実装中に Plan の前提が崩れたときだけ、止まって Plan を直し、承認を取り直す

## 1. 区分を確かめる

依頼が Plan で足りるかを判定し、1 行で宣言する（例: 「プロダクトの振る舞いは変わらない開発基盤の変更なので、Plan で設計します」）。

| 依頼 | 区分 |
|------|------|
| 新しいプロダクト、大きな方向転換 | Design → `/apd:design` |
| 外から見える振る舞いが変わる（新機能・仕様変更）。AC が書ける | Spec → `/apd:spec` |
| 振る舞いは変わらない、または Spec にするほどでない | **Plan（このスキル）** |
| typo、設定値の変更、数行の修正、原因と直し方が 1 つに決まるバグ修正 | 設計なしで実装 |

`docs/apd/` が無いリポジトリでは Spec の受け皿が無いため、振る舞いが変わる小さな変更も Plan で扱ってよい。大きな新機能なら `/apd:init` から Spec を回すことを提案する。ユーザーが区分を指定したらそれに従う。

## 2. 調べる

コードベース・既存の `CLAUDE.md`・`docs/apd/decisions.md`（あれば）を読み、設計に必要な事実を集める。意図や要件に不明点があれば、ここで質問する（設計の段階では止まって聞いてよい）。

## 3. Plan を提示する

以下を会話に出す。分量は変更の大きさに合わせる。

- **目的**: 何のために、何ができるようになるか
- **変更するファイルと方針**: ファイルごとに何をどう変えるか
- **検討した代替案と採らない理由**: 少なくとも 1 案
- **検証方法**: どのテスト・どのコマンド・どの操作で完了を判定するか
- **確認したい点**（あれば）: ユーザーの判断が要る論点と、AI の推奨

技術選定など後から参照される判断を含む場合は、承認後に `docs/apd/decisions.md` へ追記する（`docs/apd/` があるリポジトリのみ。フォーマットは `${CLAUDE_PLUGIN_ROOT}/templates/decision.md`）。

## 4. 承認を待つ

提示したら止まり、ユーザーの返答を待つ。修正指示があれば Plan を直して再提示する。

「この方向で実装して」「OK」「進めて」など承認が出たら Build に入る。

## 5. Build

- 検証方法に書いた手段で完了を確かめ、結果（テスト実行ログ・確認した操作）を会話に出す
- PR を出す場合は、本文の冒頭に承認された Plan を載せ、続けて「試し方」を書く
- Plan に無い範囲のリファクタリングや機能追加をしない。見つけた別問題は issue として起票する

## このスキルが意図的にやらないこと

- ファイルの生成 — Plan は会話と PR 本文に残す。`docs/apd/` に plan ファイルは作らない
- AC の定義 — 振る舞いを AC で固定したい変更は Spec にする
