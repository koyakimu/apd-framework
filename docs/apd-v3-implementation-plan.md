# APD v3 実装計画

> **⚠️ 歴史的文書（実行済み・アーカイブ）**: この計画は v3.0.0 で実行完了した（チェックボックスは未更新のまま）。
> ここに登場する `hooks/hooks.json`・`hooks/suggest-next.sh`・`agents/peer-review.md` 等は
> **その後 3.0.1〜3.2 で廃止され、現在のリポジトリには存在しない**。この手順を再実行しないこと。
> 現行仕様の正本は `rules/apd/` と各 `skills/*/SKILL.md`。
>
> **実行者向け:** この計画は superpowers:subagent-driven-development または
> superpowers:executing-plans でタスク単位に実行する。ステップは `- [ ]` で進捗管理する。

**Goal:** APD を「実装中は止めない自動完走＋ Spec チェック（type:agent Stop フック）」型に作り変え、人の関与を上流2点＋完成後の実機確認に絞る。

**Architecture:** 公式機能（`/goal`・hooks・superpowers）に作業を委譲し、APD は「段取り」と「Spec チェック」だけを持つ。Spec チェックは Claude Code の `type:"agent"` Stop フックで実装し、毎ターン design.md と Spec を直読して未達なら続行させる。設計の詳細は `docs/apd-v3-redesign.md`。

**Tech Stack:** Claude Code プラグイン（skills=Markdown、agents=Markdown、hooks=JSON＋bash、plugin.json、rules=Markdown）。テストコードは無く、検証は「JSON パース・grep・スクリプト実行・実機でのフック発火確認」で行う。

## Global Constraints

- ドキュメントは日本語・簡潔・短文。エンジニアに馴染む語（Spec / Design / AC / PR / フック）はそのまま、硬い造語は避ける（`docs/apd-v3-redesign.md` の用語に統一）。
- 最終バージョンは **3.0.0**。更新は `./scripts/bump-version.sh major`（`plugin.json` と `marketplace.json` を一括更新）。bump は最終タスクでまとめて行う。
- 破壊的変更を許容: `/apd:start` は `/apd:go` に改名（後方互換エイリアスは作らない）。
- `type:"agent"` フックは **experimental**。Task 1 の spike で実機確認し、使えなければ subagent フォールバック（AI が照合して結果を会話に surface）に切り替える。
- フック登録: `plugin.json` に `"hooks": "hooks/hooks.json"` を追加し、定義は `hooks/hooks.json` に置く。スクリプトは `${CLAUDE_PLUGIN_ROOT}`、プロジェクト参照は `${CLAUDE_PROJECT_DIR}` を使う。
- コミットは Conventional Commits。各タスク末でコミットする。

---

### Task 1: type:agent Stop フックの実機検証（spike）

最大の不確実性を最初に潰す。`type:"agent"` フックが (a) ファイルを読めるか、(b) `ok:false` で stop をブロックして続行させるか、(c) matcher 要否、を実機で確認する。結果で Task 2 の実装方式が決まる。

**Files:**
- Create（一時・検証後に Task 2 へ発展）: `hooks/hooks.json`
- Modify: `.claude-plugin/plugin.json`（`"hooks"` 参照を追加）
- Record: `docs/apd-v3-redesign.md`（§6 に「spike 結果」を1段追記）

**Interfaces:**
- Produces: 「agent フックが使えるツール集合」「ok:false の挙動」「matcher 要否」の確定事実。Task 2 がこれに依存。

- [ ] **Step 1: 最小の検証用フックを書く**

`hooks/hooks.json`:
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "agent",
            "prompt": "このリポジトリの docs/apd-v3-redesign.md を読み、ファイル冒頭の見出しが '# APD v3 再設計' であれば ok:true を、違えば ok:false と reason を返してください。ファイルを読めなかった場合は ok:false で reason に 'cannot read file' と書いてください。",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: plugin.json にフック参照を追加**

`.claude-plugin/plugin.json` の末尾フィールドに追加（`keywords` の後ろ、JSON 妥当性を保つ）:
```json
  "hooks": "hooks/hooks.json"
```

- [ ] **Step 3: JSON の妥当性を確認**

Run: `jq . hooks/hooks.json && jq . .claude-plugin/plugin.json`
Expected: 両方ともエラーなくパースされ整形表示される。

- [ ] **Step 4: 実機でフック発火を確認（ユーザー操作が必要）**

このステップは実行者（人間）に依頼する。手順:
1. プラグインを再読込（`/plugin` で apd を再インストール、または開発用にローカル登録）し、Claude Code セッションを開始する。
2. `/hooks` コマンドで Stop フックに agent エントリが登録されていることを確認する。
3. 適当な応答を1ターン行い、停止しようとしたときにフックが「docs を読んで ok を返す」挙動になるか観察する。
4. 検証ポイントを記録: (a) agent フックがファイルを読めたか、(b) ok:false にしたとき続行したか（別途 prompt を `ok:false 固定` にして試す）、(c) `matcher: ""` で発火したか。

Expected: フックが発火し、ファイル読込ができることを確認。

- [ ] **Step 5: 結果を design doc に追記**

`docs/apd-v3-redesign.md` の §6 直後に「### spike 結果（YYYY-MM-DD）」を追記し、(a)(b)(c) の確定事実と、使えなかった場合のフォールバック判断を1段で記録する。

- [ ] **Step 6: コミット**

```bash
git add hooks/hooks.json .claude-plugin/plugin.json docs/apd-v3-redesign.md
git commit -m "spike: type:agent Stop フックの実機挙動を検証"
```

---

### Task 2: Spec チェック（type:agent Stop フック）の実装

Task 1 で確認した挙動に基づき、Spec チェック本体を作る。基準は承認済み AC + Design、出力は OK/ずれ/未実装＋根拠＋保証範囲。Spec バグの疑いも判定するが**実装は止めない**。

**Files:**
- Modify: `hooks/hooks.json`（検証用 prompt を本番 Spec チェック prompt に差し替え）
- Delete: `agents/peer-review.md`（汎用レビューを廃し、Spec チェックに役割を移す）
- Create: `docs/apd-v3-redesign.md` 参照（基準の出典）

**Interfaces:**
- Consumes: Task 1 の「agent フックが読めるファイル／ok 挙動」。
- Produces: Stop 時に走る Spec チェック。`/goal` condition から「Spec チェック最新結果が OK」を参照される（Task 5）。

- [ ] **Step 1: Spec チェックの prompt を hooks.json に書く**

`hooks/hooks.json` の Stop → agent の `prompt` を以下に差し替える（Task 1 でフォールバックに切り替えた場合は、この prompt を `apd:peer-review` 相当の subagent 起動指示として skills 側に置く）:
```
このプロジェクトの docs/apd/design.md（プロダクトの軸）と docs/apd/spec-*.md（承認済み Spec の受け入れ条件 AC）を読み、直近の実装差分（git diff）が AC と Design に準拠しているか検証してください。

各 AC について「OK / ずれ / 未実装」を判定し、根拠をファイル:行で示してください。

判定の原則:
- これは Spec との一致だけを見る静的チェックです。実際の動作・セキュリティ実害・使い心地は保証しません（保証範囲を出力に明記）。
- 「ずれ」が実装ミスか Spec 自体の誤りかを推定し、Spec バグが疑わしくても実装は止めず、その旨を理由に記録してください。
- 未達（ずれ/未実装）があり、かつ実装ミス側で直せる場合は ok:false とし、reason に「どの AC が・どうずれていて・どう直すか」を具体的に書いてください。
- すべての AC が OK、または残るずれが Spec バグ起因のみの場合は ok:true とし、reason に保証範囲と Spec バグ候補を記録してください。
```

- [ ] **Step 2: 旧 peer-review エージェントを削除**

Run: `git rm agents/peer-review.md`

- [ ] **Step 3: 参照の残骸を確認**

Run: `grep -rn "peer-review" skills rules README.md QUICKREF.md APD-FRAMEWORK.md`
Expected: ヒットした箇所は Task 5–8 で「Spec チェック」に書き換える対象としてメモする（このステップでは確認のみ）。

- [ ] **Step 4: JSON 妥当性確認**

Run: `jq . hooks/hooks.json`
Expected: エラーなくパースされる。

- [ ] **Step 5: コミット**

```bash
git add hooks/hooks.json agents/peer-review.md
git commit -m "feat: Spec チェックを type:agent Stop フックとして実装し、汎用 peer-review を廃止"
```

---

### Task 3: 状態サジェスト用フック（command）

「いつどのコマンドを打つか」を、状態を見て提案するフック。Spec チェック（止める）とは別の、止めない command フック。

**Files:**
- Create: `hooks/suggest-next.sh`
- Modify: `hooks/hooks.json`（Stop に command フックを追加、SessionStart も追加）

**Interfaces:**
- Consumes: なし（独立）。
- Produces: `docs/apd/` の状態に応じた次コマンド提案を `additionalContext` で会話に出す。

- [ ] **Step 1: サジェストスクリプトを書く**

`hooks/suggest-next.sh`:
```bash
#!/bin/bash
# APD: プロジェクト状態を見て次に打つコマンドを提案する（止めない）
set -euo pipefail

INPUT=$(cat)
# 無限ループ防止: 継続トリガー済みなら何もしない
if [ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
  exit 0
fi

PROJ="${CLAUDE_PROJECT_DIR:-.}"
APD_DIR="$PROJ/docs/apd"

suggest() {
  jq -n --arg msg "$1" '{ "hookSpecificOutput": { "hookEventName": "Stop", "additionalContext": $msg } }'
}

if [ ! -f "$APD_DIR/design.md" ]; then
  suggest "APD: まだ Design がありません。/apd:design でプロダクトの軸を作りましょう。"
elif ! ls "$APD_DIR"/spec-*.md >/dev/null 2>&1; then
  suggest "APD: Design はあります。/apd:spec で Spec を作りましょう。"
else
  suggest "APD: Spec があります。実装は /apd:go で達成条件を作り、出力を /goal に貼って開始します。"
fi
exit 0
```

- [ ] **Step 2: 実行権限を付与**

Run: `chmod +x hooks/suggest-next.sh`

- [ ] **Step 3: hooks.json に command フックと SessionStart を追加**

`hooks/hooks.json` の `Stop` 配列の agent エントリと同じ `hooks` 配列に command を追加し、`SessionStart` を新設:
```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          { "type": "agent", "prompt": "（Task 2 の Spec チェック prompt）", "timeout": 120 },
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/suggest-next.sh", "timeout": 10 }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/suggest-next.sh", "timeout": 10 }
        ]
      }
    ]
  }
}
```
（agent の prompt は Task 2 の本文をそのまま入れる。ここでは紙幅のため省略表記。）

- [ ] **Step 4: スクリプトの単体動作を確認**

Run: `echo '{"stop_hook_active":false}' | CLAUDE_PROJECT_DIR="$(pwd)" bash hooks/suggest-next.sh | jq .`
Expected: `hookSpecificOutput.additionalContext` に、現在の `docs/apd/` 状態に応じた提案文字列が入った JSON が出る。

- [ ] **Step 5: ループ防止の確認**

Run: `echo '{"stop_hook_active":true}' | CLAUDE_PROJECT_DIR="$(pwd)" bash hooks/suggest-next.sh; echo "exit=$?"`
Expected: 出力なし・`exit=0`。

- [ ] **Step 6: コミット**

```bash
git add hooks/suggest-next.sh hooks/hooks.json
git commit -m "feat: 状態サジェスト用 Stop/SessionStart フックを追加"
```

---

### Task 4: /apd:start → /apd:go へ改名・強化

skill ディレクトリを改名し、達成条件に「Spec チェック OK」と「NFR 委譲結果」を組み込み、`/goal` 貼付の文面を整える。

**Files:**
- Rename: `skills/start/SKILL.md` → `skills/go/SKILL.md`
- Modify: `skills/go/SKILL.md`（name, 本文）

**Interfaces:**
- Consumes: Task 2 の Spec チェック（達成条件が参照）。
- Produces: `/apd:go` コマンド。Task 6 の spec skill と Task 7/8 のドキュメントが名前を参照。

- [ ] **Step 1: ディレクトリを git mv で改名**

Run: `git mv skills/start skills/go`

- [ ] **Step 2: frontmatter の name と説明を更新**

`skills/go/SKILL.md` の frontmatter `name: start` → `name: go`、description の `/apd:start` を `/apd:go` に、トリガー語に「実装を開始」を残す。

- [ ] **Step 3: 本文を強化**

`skills/go/SKILL.md` の condition 構築部に以下を反映する:
- 「検証」カテゴリに **「Spec チェック（Stop フック）の最新結果が OK」** を必須項目として追加。
- 「非機能要件のうち委譲したもの（`/security-review` 等）の結果が達成条件に含まれる」ことを追加。
- 「制約」から「判断に迷ったら Human Checkpoint にエスカレーション」を削除し、**「実装中は人にエスカレーションせず完走する。判断は Spec に先出し済み、または完成後の実機確認で扱う」** に置き換える。
- 「制約」に **エスケープハッチ** を追加: 「Spec チェックが通らない状態が続いたら、途中までを下書き PR で残して停止し、完成後の実機確認に回す（上限ターン/時間を condition に含める）」。
- 「Handoff」の「試し方」は、人間が完成後に確認する手順として残す（§3 の③）。
- 「このスキルが意図的にやらないこと」の **peer-review 起動の記述（旧 L96）** を、「Spec チェック（Stop フック）が Build 中に自動で走るため、skill 側でレビュー起動はしない」に更新する。

- [ ] **Step 4: 旧コマンド名の残骸チェック**

Run: `grep -rn "apd:start\|skills/start" skills/go/SKILL.md`
Expected: ヒットなし（全て `apd:go` / `skills/go` になっている）。

- [ ] **Step 5: コミット**

```bash
git add skills/go skills/start
git commit -m "feat!: /apd:start を /apd:go に改名し、Spec チェックを達成条件に組み込む"
```

---

### Task 5: /apd:spec の NFR 拡張と go 案内

Spec テンプレートに非機能要件を AC として書ける枠を足し、spec skill の案内を `/apd:go` に直す。

**Files:**
- Modify: `templates/spec.md`（NFR の AC 枠を追加）
- Modify: `skills/spec/SKILL.md`（NFR を AC 化する指示、承認後の案内を `/apd:go` に）

**Interfaces:**
- Consumes: Task 4 の `/apd:go` 名。
- Produces: NFR を含む Spec。Task 2 の Spec チェックがこれを基準に検証する。

- [ ] **Step 1: テンプレートに NFR セクションを追加**

`templates/spec.md` の `## Acceptance Criteria` 内、エラーケースの後に追記:
```markdown
### AC-NFR-001 (Non-Functional / 測定可能な場合のみ)
- **Given**: {前提（負荷・環境など）}
- **When**: {操作}
- **Then**: {測定可能な閾値（例: p95 < 200ms、a11y スコア ≥ 90）}
```
あわせて `## Notes` の前に追記:
```markdown
## 委譲する非機能要件
- セキュリティ等、AC に測定可能な形で書けないものは委譲先（/security-review 等）を明記し、その結果を Build の達成条件に含める。
```

- [ ] **Step 2: spec skill に NFR 指示を追加**

`skills/spec/SKILL.md` の「生成ルール」の Spec 構成リストに「測定可能な非機能要件を AC（AC-NFR-xxx）として書く。書けないものは委譲先を明記する」を追加する。

- [ ] **Step 3: apd:start 参照を 2 箇所とも更新**

`skills/spec/SKILL.md` の以下2箇所を更新:
- bugfix トリアージ（旧 L103）「`/apd:start` で修正を開始してください」→「`/apd:go` で達成条件を作り `/goal` に貼って修正を開始してください」
- 承認後の案内（旧 L193）「`/apd:start` で Build を開始…」→「`/apd:go` で達成条件を作り、その出力を `/goal` に貼って実装を開始してください（ここから先、実装中は止まりません）」

- [ ] **Step 4: 残骸チェック**

Run: `grep -rn "apd:start" skills/spec/SKILL.md`
Expected: ヒットなし。

- [ ] **Step 5: コミット**

```bash
git add templates/spec.md skills/spec/SKILL.md
git commit -m "feat: Spec に非機能要件 AC を追加し、案内を /apd:go に更新"
```

---

### Task 6: rules/apd の書き直し（新しい流れ）

ルールを「実装中ゼロ介入・実機確認は残す」に合わせる。エスカレーションポリシーを廃し、Spec チェックを番人として記述する。

**Files:**
- Modify: `rules/apd/01-phases.md`, `rules/apd/02-cycle-flow.md`（主対象）
- Modify: `rules/apd/00-principles.md`, `rules/apd/03-documents.md`, `rules/apd/04-testing.md`, `rules/apd/05-deliverable-preview.md`（Acceptance 言及を「完成後の実機確認」に統一）

**Interfaces:**
- Consumes: Task 4 `/apd:go`, Task 2 Spec チェック。
- Produces: `/apd:init` がプロジェクトにコピーするフレームワーク方針。

- [ ] **Step 1: 01-phases.md を更新**

- フェーズ図の「Build ── AI 自律」を「実装中は止まらない自動完走（`/goal` ＋ Spec チェック Stop フック）」に、「Acceptance ── 人間」を「完成後の実機確認（止めない・違えば次サイクル）」に書き換える。
- 「人間が関与する場」を「意図 / Spec 確認 / 完成後の実機確認」に更新。
- **「Build 中のエスカレーションポリシー」節を削除**し、代わりに「実装中はエスカレーションしない。新ビジネスルール等の判断は Spec に先出しするか、完成後の実機確認で次サイクルに回す」を記す。

- [ ] **Step 2: 02-cycle-flow.md を更新**

- フロー表の「→ Acceptance」を「→ 完成後の実機確認」に統一。
- バグトリアージを「Spec 起因＝完成後の実機確認で気づき次サイクルで Spec 修正 / Build 起因＝実装中に Spec チェックが検出し自律修正」に更新（実装中の人間エスカレーションを除去）。

- [ ] **Step 3: 残り 4 ファイルの Acceptance を更新**

`rules/apd/00-principles.md` `03-documents.md` `04-testing.md` `05-deliverable-preview.md` の「Acceptance」言及を、文脈に応じて「完成後の実機確認」に統一する（フェーズ名としての Acceptance を廃し、工程としての実機確認に）。受け入れ条件（AC）の語は残してよい。

- [ ] **Step 4: 用語・残骸チェック**

Run: `grep -rn "エスカレーション\|Acceptance\|apd:start" rules/apd/`
Expected: フェーズ名の「Acceptance」・「apd:start」・実装中エスカレーションの記述が残っていない（受け入れ条件 AC の語は残ってよい）。

- [ ] **Step 5: コミット**

```bash
git add rules/apd/
git commit -m "docs: rules を実装中ゼロ介入・実機確認モデルに書き直し"
```

---

### Task 7: ルートドキュメントの更新と簡潔化

README / APD-FRAMEWORK / QUICKREF を新フロー・新コマンドに合わせ、文章を簡潔化する。

**Files:**
- Modify: `README.md`, `APD-FRAMEWORK.md`, `QUICKREF.md`

**Interfaces:**
- Consumes: Task 4–6 の最終仕様。
- Produces: 利用者向けの最新ドキュメント。

- [ ] **Step 1: コマンド表を更新**

3ファイルのコマンド一覧で `/apd:start` を `/apd:go` に、説明を「達成条件を作り `/goal` に渡す」に更新。`peer-review` の記述を「Spec チェック（Stop フック）」に置換。

- [ ] **Step 2: フロー記述を更新**

フェーズ図/フロー説明を「意図 → Spec 承認 →（実装中は止まらない自動完走）→ 完成後の実機確認」に統一。Acceptance の語を「完成後の実機確認」に。

- [ ] **Step 3: 簡潔化**

各ファイルを一文を短く・冗長表現を削る方針で見直す（`docs/apd-v3-redesign.md` の用語に合わせる）。

- [ ] **Step 4: 残骸チェック**

Run: `grep -rn "apd:start\|peer-review\|Acceptance フェーズ" README.md APD-FRAMEWORK.md QUICKREF.md`
Expected: ヒットなし、または意図どおりに更新済み。

- [ ] **Step 5: コミット**

```bash
git add README.md APD-FRAMEWORK.md QUICKREF.md
git commit -m "docs: ルートドキュメントを v3 フロー・新コマンドに更新し簡潔化"
```

---

### Task 8: バージョン 3.0.0 と CHANGELOG

最後にまとめてバージョンを上げ、変更履歴を記録する。

**Files:**
- Modify: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`（bump スクリプト経由）
- Modify: `CHANGELOG.md`

**Interfaces:**
- Consumes: Task 1–7 の全変更。
- Produces: リリース可能な 3.0.0。

- [ ] **Step 1: メジャーバージョンを上げる**

Run: `./scripts/bump-version.sh major`
Expected: `plugin.json` と `marketplace.json` の version が `3.0.0` になる。

- [ ] **Step 2: bump 結果を確認**

Run: `grep -n '"version"' .claude-plugin/plugin.json .claude-plugin/marketplace.json`
Expected: 両方 `3.0.0`。

- [ ] **Step 3: CHANGELOG を追記**

`CHANGELOG.md` 冒頭に `## 3.0.0` を追加し、要点を箇条書き: 実装中ゼロ介入の自動完走、Spec チェック（type:agent Stop フック）、`/apd:start`→`/apd:go`、状態サジェストフック、Acceptance を完成後の実機確認に、エスカレーションポリシー廃止、3.0.0（breaking）。

- [ ] **Step 4: 全体の最終確認**

Run: `jq . .claude-plugin/plugin.json hooks/hooks.json && grep -rn "apd:start" skills rules README.md QUICKREF.md APD-FRAMEWORK.md`
Expected: JSON 妥当、`apd:start` の残骸なし。

- [ ] **Step 5: コミット**

```bash
git add .claude-plugin/plugin.json .claude-plugin/marketplace.json CHANGELOG.md
git commit -m "chore: バージョンを 3.0.0 に更新し CHANGELOG を追記"
```

---

## 実装順と依存

```
Task 1 (spike) ─→ Task 2 (Spec チェック) ─┐
Task 3 (サジェスト) ──────────────────────┤
Task 4 (go 改名) ─→ Task 5 (spec 拡張) ───┼─→ Task 7 (ルートdoc) ─→ Task 8 (bump)
Task 6 (rules) ───────────────────────────┘
```

- Task 1 は必ず最初（type:agent の可否で Task 2 の方式が決まる）。
- Task 8（bump）は必ず最後（全変更を 3.0.0 にまとめる）。
- Task 4 は Task 5/6/7 のコマンド名の前提なので先に行う。
