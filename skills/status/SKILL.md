---
name: status
description: >
  Reports where the project stands in the APD flow and the sensible
  next step, based on docs/apd/ state and the conversation. Use when
  the user asks where they are or what to do next, or runs /apd:status
  ("今どこ", "次なに", "状況確認", "APD の状態").
---

# APD Status — 現在地と次の一手

APD フローの現在地と次の一手を、ファイルの状態と会話の文脈の両方から判定して答える。

## 手順

### 1. 状態を集める

- `docs/apd/design.md` の有無
- `docs/apd/spec-*.md` の有無と一覧（あれば各 Spec の `status` / `version` を見る）
- オープン中の PR / issue（`gh pr list` / `gh issue list` が使える環境なら）
- 直近の会話の内容（APD で新規開発中なのか、保守・調査など別作業なのか）

### 2. 現在地を判定する

| 状態 | 現在地 | 標準の次の一手 |
|------|--------|----------------|
| `design.md` が無い | 未着手 | `/apd:design` |
| `design.md` はある／`spec-*.md` が無い | 設計済み | `/apd:spec` |
| `spec-*.md` がある／Build 前 | 仕様済み | 承認して `apd:go` で Build |
| 会話で Plan を承認済み／Build 前 | 設計済み（Plan） | `apd:plan` の手順で Build |
| Build 済み・PR あり | 検証待ち | 完成後の実機確認 |

判定根拠は会話の文脈で上書きしてよい。例: spec があっても、ユーザーが今は別の Spec を編集中ならそちらが現在地。

### 3. 報告する

簡潔に出力する:

```
## APD 現在地
- 状態: {現在地}（根拠: {見たファイル/PR}）
- 次の一手: {コマンドまたはアクション}
- 補足: {会話の文脈を踏まえた注意}
```

会話が APD と無関係なら、無理に次の APD ステップへ誘導しない。現在地だけ伝え、進めるかはユーザーに委ねる。
