---
name: design
description: >
  Creates the product Design document (the north star) through
  interactive dialogue. Writes to `docs/apd/design.md`. Use before
  writing any code when the user asks to build a new product or app,
  or to change a product's direction, and `docs/apd/design.md` does
  not exist yet, even if the user did not ask for a design. Also use
  when the user asks to create a design document, design a product,
  or run /apd:design ("Design 文書を作成", "プロダクトを設計").
---

# APD Design — Design 文書の対話的作成

プロダクトの Design 文書（北極星）を、ユーザーとの数往復の対話で作る。

## 常に守ること

- Design の承認を得るまでコードを書かない
- 承認が出たら、そのまま `apd:spec` の手順で Spec に進む。ユーザーにコマンドの入力を求めない
- 技術スタック・実装方法は Design に含めない。ユーザーから出たら「Spec で技術選定として扱います」と伝える

## 対話の進め方

### 1. ヒアリング

プロダクトのアイデアを聞き、不明点を質問する。

### 2. ドラフト生成

以下の Amazon PR/FAQ 形式で Design 文書のドラフトを一気に生成する:

1. **Who（誰のため）**: ターゲットユーザーのペルソナ、課題、コンテキスト
2. **Why（なぜ今）**: 市場機会、タイミングの根拠、既存ソリューションの限界
3. **What（何ができるか）**: ユーザー視点での機能・体験の記述（技術サービス名・アーキテクチャ構成は含めない）
4. **What Not（何をやらないか）**: スコープ外の明示。曖昧な境界を排除する（技術的な制約ではなくプロダクトスコープとして記述する）
5. **FAQ**: 想定される疑問と回答。ステークホルダー・ユーザー・エンジニア視点を含む（技術実装の詳細は含めず、プロダクト・運用の観点で記述する）
6. **Success Criteria**: 定量・定性の成功指標

### 3. 信頼度の明示

各セクションについて以下を明示する:

- **自信がある部分** — ユーザーの入力から明確に導出できた内容
- **推論で埋めた部分（確認が必要）** — ユーザーの入力からは不明で、AI が補完した内容
- **Spec フェーズに移管した情報** — ユーザーから提供されたが Design 文書のスコープ外のため、Spec フェーズで扱う技術選定情報（該当がある場合のみ）

### 4. フィードバックループ

ユーザーのフィードバックを受けて修正する。数往復で収束させる。

## ToDo 記録

対話の中で「今回の Design スコープ外だが将来的に検討すべきアイデア」が出た場合は記録する。GitHub issue が使える環境では `gh issue create` で起票する。使えない環境では `docs/apd/todo.md` に追記する。Design 文書本体には含めない。

## 制約

- **ドラフトのセクション構成はテンプレート（Who / Why / What / What Not / FAQ / Success Criteria）に厳密に従い、独自セクション（例: ホスティング構成、技術アーキテクチャ等）を追加しない**
- **What Not は必ず 5 項目以上** 記述する
- **FAQ は最低 10 問** 設定する
- **Success Criteria には測定可能な指標** を含める

## 出力

Design 文書を `docs/apd/design.md` に Markdown 形式（YAML frontmatter 付き）で書き出す。CLAUDE.md に定義されたフォーマットがあればそれに従う。

## 確認

Design 文書が完成したら、以下のチェックリストを提示する:

- [ ] Who: ターゲットユーザーが明確に定義されているか
- [ ] Why: 作る理由と今のタイミングが説得力あるか
- [ ] What: ユーザー価値が技術用語なしで記述されているか
- [ ] What Not: スコープ外が十分に明示されているか（最低 5 項目）
- [ ] FAQ: 主要な疑問が網羅されているか（最低 10 問）
- [ ] Success Criteria: 測定可能な指標があるか

修正の指示があれば対話を続ける。
