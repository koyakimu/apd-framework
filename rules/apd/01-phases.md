# APD フェーズ定義

## フェーズ

```
Intent ── 人間 + AI 対話
  成果物: Design（北極星）
Spec ── AI ドラフト + 人間レビュー
  成果物: Spec（AC + 検証方針 + 成果物プレビュー記述）+ Decision Records
Build ── AI 自律（実装中は止まらない自動完走）
  成果物: 実装 + テスト全パス + PR（試し方記載済み）。Claude Code の `/goal` に auto mode で委譲
完成後の実機確認 ── 人間
  PR の「試し方」に沿って実機で触り、受け入れ判断する
  差異があれば差し戻さず次サイクル（Spec 修正 → Build）へ進む
```

人間が関与するのは Intent（意図を決める）・Spec（仕様を確認する）・完成後の実機確認（動く成果物が意図どおりか確認する）の 3 つ。

## Build 中は止まらない

Build フェーズに人間は介入しない。実装中は人間に問い合わせずエスカレーションもしない。新しいビジネスルールや外部インターフェース変更など Spec にない判断が必要な場合は、**Spec に先出し**（Spec フェーズで人間が確認済み）するか、**完成後の実機確認で気づき次サイクルで Spec を修正する**。

**Build は auto mode で `/goal` を実行する（規約）。** `/goal` はターンの継続だけを自動化し、ツール呼び出しの許可は permission mode の責務のままなので、Manual mode では許可されていないツール呼び出しのたびに人間の確認が入り「止まらない」が成立しない。切り替えは Shift+Tab、起動時の `--permission-mode auto`、ユーザー設定の `permissions.defaultMode`。プロジェクト設定やプラグインからは強制できないため、`/apd:go` が `/goal` を貼る直前に確認を促す。

auto mode でも止まる場面は残る。classifier が 3 回連続または累計 20 回ブロックすると通常のプロンプトに戻る、`permissions.ask` に合致する操作は常に確認が入る、作業ディレクトリ外の初回読み取りは確認が入る。これらは止まって当然の場面として扱い、condition で回避しようとしない。auto mode が使えない環境（組織設定で無効、モデル要件を満たさない）では、Build 中に許可プロンプトで止まることを前提に人間が付き添う。

## Build の収束判定

判定役は `/goal` の評価器と、`/apd:go` が condition に組み込む Spec チェック。AC 準拠・テスト pass・PR の Handoff 記載をターン終了ごとに判定し、ビルド AI が照合結果を surface して自律修正する。

- **評価器はツールを呼ばない**。Claude が turn 内で test 実行ログ・PR diff・実装内容を会話に surface する必要がある
- **バックグラウンド作業がある turn は評価がスキップされる**。subagent やバックグラウンドシェルが動いたまま turn が終わると、判定はバックグラウンド作業のない次の turn 終了時になる。並列化した Build では収束が遅れて見えるが異常ではない
- 同一論点でループした場合は condition に明記した上限（turn 数や時間）で停止して報告する
- AI が自動検証できない AC（実機限定・人間の主観評価等）は、実装と「試し方」ドキュメント化をもって Build 側の完了とみなす（実際の判定は完成後の実機確認に委ねる）

## 並列実行

並列化の手段は Claude Code 本体が持つ。APD は選択を強制せず、Build の規模に応じてリーダーが判断する。選ぶときは「止まらない」との相性を見る: subagent（`isolation: "worktree"` でファイル隔離）、agent teams（既定で無効。`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` が要り、共有 task list は Task ツールを持つセッションでのみ使われる。teammate の許可プロンプトはリーダーセッションに出る）、dynamic workflows（大規模ファンアウト。1 run 最大 1,000 エージェント・同時 16、run 中はユーザー入力を受け付けず、止めうるのは許可プロンプトだけ。Manual / accept edits mode では起動のたびに承認が出る）、`/batch`（5〜30 の worktree 隔離 subagent が実装・テスト・PR まで行う。git リポジトリ必須、分解後の計画承認で一度止まる）。
