# APD Plugin — Autopilot Development Framework

English | [日本語](README.ja.md)

> **Humans make the decisions. The AI builds autonomously to completion.**

Autopilot Development (APD) is a development framework in which an AI agent builds software on its own, and the human is involved at only two points: **deciding the intent** and **checking the finished result on a real device**. It is distributed as a Claude Code plugin.

## Flow

```
Intent / Spec   ← Human + AI (settle the intent, approve the Spec)
   ↓
Build           ← AI runs autonomously to completion (no stopping midway)
   ↓
Device check    ← Human tries it on a real device and accepts it
```

The human owns only two things: **deciding the intent** (Intent / Spec approval) and **the final hands-on check**. Progress tracking, parallelization, task tracking and quality gates during Build are delegated to Claude Code's own features (`/goal`, subagents, dynamic workflows, hooks, and agent teams, which are experimental and off by default). APD stays a thin layer of conventions. Once approved, Build runs to completion right there in auto mode; for long unattended runs you can also use `/goal`.

It works without typing commands. When you ask for something to be built or changed, the AI classifies the request (Design / Spec / Plan / no design needed) and proposes a design. Approve it with something like "go ahead and implement this" and it proceeds through implementation, tests and a pull request. Changes too small for a Spec are handled with a Plan (a lightweight design shown in the conversation), which also works in repositories where `/apd:init` has not been run.

## Installation

```bash
# Add the marketplace
/plugin marketplace add koyakimu/apd-framework

# Install the plugin
/plugin install apd@apd-marketplace
```

## Initializing a project

In your project directory:

```
/apd:init
```

This will:

- Copy the framework rules into `.claude/rules/apd/` (loaded automatically by Claude Code)
- Create the `docs/apd/` directory (flat structure)
- Use your project's issue tracker as the backlog (GitHub issues are detected automatically; tell Claude if you use another such as GitLab, Linear or Jira); if there is none, create `docs/apd/todo.md`

## Skills

| Command | Role |
|---------|------|
| `/apd:init`    | Initialize the project |
| `/apd:design`  | Create the Design document (the north star) through dialogue |
| `/apd:spec`    | Generate or update Spec drafts (full / add / bugfix modes) |
| `/apd:plan`    | Lightweight design for changes that don't need a Spec (shown in conversation → approve → Build) |
| `/apd:go`      | Build an approved Spec (implements in place by default; for long unattended runs, assembles a completion condition for `/goal`) |
| `/apd:status`  | Show where you are and the next step (judged from file state plus conversation context) |
| `/apd:migrate` | Migrate an existing project to the current document structure (see [MIGRATION.md](MIGRATION.md)) |

`docs/apd/` consists of **three living kinds of file**: `design.md` (the north star), `decisions.md` (decision log), and `spec-{feature}.md` (one per feature). Documents keep being edited, and git holds the history. The human review surface is the pull requests and issues.

See `QUICKREF.md` for details and `APD-FRAMEWORK.md` for the design principles.

## Language

The plugin's skills, rules and templates are written in English, but APD works in **your** language: Claude converses in the language you write in, and writes the Design, Specs, decisions, Plans, PR descriptions and issues in that language too, keeping the templates' section names (such as `## Acceptance Criteria`), IDs and frontmatter keys as they are. When it edits an existing file such as your CLAUDE.md, it keeps that file's language.

## Evaluation scenarios

`evals/` contains six cases that check whether the design classification behaves as intended: whether a request starts from a design (`new-feature` / `devtool-plan` / `test-infra-plan`), whether it implements in place after approval (`approved-build`), and whether it stays out of the way for a typo or a question (`typo` / `question`). Each case runs in two arms, with and without APD, and the difference (Δ) is APD's effect. Run this at the plugin root (one run executes and grades 36 runs):

```bash
claude plugin eval . --scaffold --allow-tools Write Edit --threshold 0.8 --max-cost-usd 10
```

Add `--model` to try a different model. If you change the fixture, edit `evals/_fixture/fixture.sh` and copy it to each case with `scripts/sync-eval-fixtures.sh`.

## Plugin layout

| Path | Contents |
|------|----------|
| `.claude-plugin/plugin.json` | Plugin manifest |
| `skills/` | Slash commands (`init`, `design`, `spec`, `plan`, `go`, `status`, `migrate`) |
| `hooks/` | SessionStart hook (injects the design classification into context; `cat` only) |
| `evals/` | Evaluation scenarios for `claude plugin eval` |
| `rules/apd/` | Framework rules (copied into the project by `/apd:init`) |
| `templates/` | Document templates |

## License

MIT. See also the [privacy policy](PRIVACY.md).
