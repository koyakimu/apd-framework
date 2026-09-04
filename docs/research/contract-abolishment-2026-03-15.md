# Contract廃止の調査結果

> **⚠️ 歴史的文書（アーカイブ）**: 本書は 2026-03-15 時点の調査記録。ここで前提にしている Phase 番号（Phase 2 / Phase 3）は
> その後の再設計で廃止され、現行のフェーズは Intent / Spec / Build / 完成後の実機確認。**現行仕様の正本は `rules/apd/` と各 `skills/*/SKILL.md`**。

Phase 2 (Contract) 廃止の判断を裏付ける外部ソース調査（2026-03-15実施）

## 背景

APDフレームワークのPhase 2 (Contract) とPhase 3 (Execute) の分離に疑問が生じ、外部ソースを調査した。

**Why:** Phase 2もPhase 3もAI自律であり、間のゲートもAI Checkpoint（自動承認）。人間が介入しない設計なのに分離する意義が不明確だった。

**結論:** Contract を廃止し、Spec に成果物プレビューとAC-テスト対応表を吸収。Phase 2 (Build) として統合。

## 調査結果の詳細

### 1. AI時代のSpec-Driven Development

**GitHub Spec Kit** (2025, オープンソース)
- 3ファイルモデル: `spec.md` → `plan.md` → `tasks.md`
- plan と tasks は人間レビュー対象ではなく、AIが消費するもの
- 設計意図: "The same spec.md can generate a .NET/Blazor implementation on one branch and a Vite/vanilla-JS implementation on another."
- Specが実装非依存、planは実装時にAIが内部的に生成
- Source: https://github.com/github/spec-kit, https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/

**Kiro (AWS)** (2025)
- 同様の3ファイルモデル: `requirements.md` → `design.md` → `tasks.md`
- Source: https://kiro.dev/, https://kiro.dev/docs/specs/

**Martin Fowler の分析**
- SDDを "a structured, behavior-oriented artifact written in natural language that expresses software functionality and serves as guidance to AI coding agents" と定義
- 警告: "SDD encodes the assumption that you aren't going to learn anything during implementation that would change the specification."
- Source: https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html

**Thoughtworks Technology Radar**
- SDDをRadarに掲載。"The latest AI coding agents generally separate the planning and implementation phases of the development process."
- Source: https://www.thoughtworks.com/radar/techniques/spec-driven-development

**批判的意見**
- Marmelab: "slow, heavy, and less effective than iterative prompting"
- 反論: "when AI compresses the build cycle from months to minutes, that changes the calculus entirely"
- Source: https://marmelab.com/blog/2025/11/12/spec-driven-development-waterfall-strikes-back.html

### 2. Executable Specifications (BDD / Specification by Example)

**Gojko Adzic「Specification by Example」**
- ACを実行可能なテストとして書けば、Spec自体が検証可能な契約になる
- 別途「技術的な契約」は不要
- APDのSpecは既にGiven/When/Then形式のACを持っており、Executable Specificationの構造
- Source: https://gojko.net/books/specification-by-example/

### 3. 企業のDesign Doc実践

| 企業 | 構造 | Source |
|------|------|--------|
| Google | What + How を1つのdesign docに統合 | https://www.industrialempathy.com/posts/design-docs-at-google/ |
| Amazon | PR/FAQ（what）と技術設計（how）を分離 | https://justingarrison.com/blog/2021-03-15-the-document-culture-of-amazon/ |
| Spotify | RFC（議論用）+ ADR（決定記録） | https://engineering.atspotify.com/2020/04/when-should-i-write-an-architecture-decision-record |
| Uber | PRD + Engineering RFC（規模が大きくなると分離） | https://blog.pragmaticengineer.com/rfcs-and-design-docs/ |

### 4. ADR (Architecture Decision Records)

- AWS・Google Cloud・Spotifyいずれも: ADRは「why」を記録するもの。「what」や「how」の詳細は書かない
- APDには既にDecision Recordsがあり、技術選定の「why」はそこに記録される
- Contractの技術選定セクションはDecision Recordsと重複していた
- Sources: https://aws.amazon.com/blogs/architecture/master-architecture-decision-records-adrs-best-practices-for-effective-decision-making/, https://cloud.google.com/architecture/architecture-decision-records

### 5. 軽量ドキュメンテーション

- YAGNI原則: "The cost of creating a document may be magnitudes smaller than the cost of maintaining that document"
- Agile原則: "just barely good enough" (JBGE) documentation
- 小規模プロジェクトではfunctional + technical designを統合すべき

## APDへの適用

```
APDが既に持っているもの:
  - Spec (What + AC)        ← GitHub Spec Kit の spec.md と同等
  - Decision Records (Why)  ← ADR と同等
  - Design (北極星)         ← Amazon の PR/FAQ と同等

Contractが担っていたもの → 行き先:
  - Tech Stack / 構成       → Decision Records で十分
  - タスク分解 / 並列計画    → AIの内部処理（永続化不要）
  - テスト戦略のAC対応表    → Specに吸収
  - 成果物プレビュー        → Specに吸収
```

Phase構成を Design → Spec → Build の3フェーズに変更。
