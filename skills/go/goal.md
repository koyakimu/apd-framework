# `/goal` で Build する

ユーザーが長時間の無人実行を望んだときだけ使う。`/goal` は条件を満たすまでターンを続ける Claude Code の機能で、評価器がターン終了ごとに達成を判定する。slash command はユーザーしか送れないので、送信はユーザーに任せる。

## 手順

1. SKILL.md の「3. 達成条件を組み立てる」を 4,000 字以内にまとめ、condition にする。ターン数か時間の上限を含める
2. condition と、それを `/goal` で送る文面をユーザーに渡す。あわせて次を伝える:
   - auto mode（ステータスバーの `⏵⏵ auto mode on`）で貼る。Manual mode なら Shift+Tab で切り替える。`/goal` は permission mode を変えないので、Manual のままだと許可プロンプトで止まる
   - auto mode でも、classifier の連続ブロック・`permissions.ask`・作業ディレクトリ外の初回読み取りでは止まる
   - condition の文面は手元に残す。認証失敗・クレジット切れ・解消できないコンテキスト超過・モデル利用不可で turn が落ちると goal は自動でクリアされるので、原因を直して貼り直す（レート制限では goal は残る）
3. 並列化が必要なら、subagent のほかに agent teams・dynamic workflows・`/batch` も選択肢として添える

## 評価器の判定

- 評価器はツールを呼ばず、会話に出た情報だけで判定する。テスト実行ログ・変更内容・PR を会話に出す
- subagent やバックグラウンドシェルが動いたまま turn が終わると、その turn は評価されず、バックグラウンド作業の無い次の turn で判定される

## うまくいかないとき

| 症状 | 対処 |
|---|---|
| 評価器が no を返し続ける | condition が抽象的。AC の文言を引用して具体化する |
| token 消費が大きい | condition にターン数か時間の上限を入れる |
| 許可プロンプトで止まる | Manual mode のまま貼っている。Shift+Tab で auto mode にする。goal は残っているので貼り直し不要 |
| ツールを使わない turn が続いて止まる | Claude Code がループを止めて制御を返す。goal は残っており、次のプロンプトで評価が再開する |
| `/goal` が使えない | Claude Code のバージョン、workspace の trust、`disableAllHooks`、managed settings の `allowManagedHooksOnly` を確認する |
