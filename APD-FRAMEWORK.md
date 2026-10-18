# Autopilot Development (APD)

> **Humans only make decisions; AI runs autonomously to completion**

Autopilot Development (APD) is a development framework in which AI agents develop software autonomously and humans are involved at only two points: "deciding the intent" and "accepting the working deliverable". It is based on the self-driving metaphor: the human decides the destination and the route, the AI drives on Autopilot, and on arrival the human confirms "yes, this is the right place".

---

## Design principles

### Maximize what can be left to the AI

Human intervention during the AI phase is zero. Including mocks, user stories and tests, the AI implements the feature exactly as the human intended, through to completion. Avoid implementation stopping because human intervention is needed.

Once the design is approved, Build runs on the spot to completion, staying in auto mode. auto mode handles tool permissions, so there is zero intervention during implementation. For long unattended runs you may also use `/goal` (which handles turn continuation). Some situations still stop even in auto mode (consecutive classifier blocks, `permissions.ask`, the first read outside the working directory); treat those as situations where stopping is expected.

### Separate "human time" from "AI time"

- **Intent / Spec / Plan = human time**: dialogue and inject decisions. Do not write code before approval
- **Build = AI time**: autonomous execution (does not stop midway)
- **Hands-on check = human time (lightweight)**: after completion, try the working deliverable on a real device and accept it

### Humans decide the intent and accept the working deliverable

- **Upstream (Intent / Spec)**: decide the intent — make decisions on product vision, specification and technology choices
- **Downstream (hands-on check after completion)**: check on a real device that the working deliverable matches the intent
- **No code review is required** — quality is assured by the AI's own loop (checking the completion condition, subagents, tests, and, when using `/goal`, its evaluator)

### Stay a thin convention layer

APD provides only **the Design / Spec / Plan / Decision conventions and a minimal set of skills**. It does not reimplement features that exist in Claude Code itself:

| What you want to do | Claude Code feature to use |
|------|-----------|
| Long unattended Build | `/goal` (session-scoped; continues turns until the condition is met. It does not change the permission mode, so run in auto mode. Optional) |
| Isolating side tasks | subagent (file isolation available with `isolation: "worktree"`) |
| Multi-session coordination | agent teams (experimental, disabled by default; enable with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. Teammates' permission prompts appear in the leader session) |
| Large-scale parallelization | `/batch` (5–30 units; each subagent implements, tests and opens a PR in an isolated worktree. Requires a git repository. Stops once after decomposition to ask for approval of the plan) |
| Scripted large-scale fan-out | dynamic workflows (audits, bulk migrations, cross-verification. Up to 1,000 agents per run, up to 16 running concurrently; a run accepts no user input, and only agent permission prompts can stop it) |
| In-session todo | Task tools (`TaskCreate` etc.). Not provided by default on Opus 4.8 / Sonnet 5 / Fable 5 / Mythos 5 and later; the model tracks multi-step work itself |
| Accumulated knowledge | auto memory |
| File change tracking / rewind | checkpointing |
| GitHub integration | `gh` CLI (local-centred, sufficient). If team operation or asynchronous triggers are needed, optionally add GitHub Actions / routines |
| backlog | The project's issue tracker (e.g. GitHub issues) / `docs/apd/todo.md` (if there is none) |

---

## Phases

```
Intent     ── Human + AI dialogue
  Deliverable: Design document (north star, rarely changes)

Spec       ── AI draft + human review and approval
  Deliverable: Spec (AC + verification approach + deliverable preview description) + Decision Records

Plan       ── AI draft + human review and approval (changes that get no Spec)
  Deliverable: design kept in the conversation and PR body (goal, approach, alternatives, verification method)

Build      ── AI runs autonomously to completion (does not stop midway)
  Deliverable: implementation + all tests passing + PR (with "How to try it")
  Implementation: implement on the spot once approved (long unattended runs are delegated to /goal)

Hands-on check after completion ── Human
  Follow the PR's "How to try it", try it on a real device, and decide on acceptance
```

### Intent (Design)

Document the product vision, who it is for and what it is, and what is out of scope, in Amazon PR/FAQ format. It is referenced across all cycles as the "north star".

- Location: `docs/apd/design.md`
- Skill: `/apd:design`
- Process: interview → draft → state confidence levels → feedback loop
- Constraints: no technology choices, at least 5 What Not items, at least 10 FAQ questions

### Spec

Split the Design into implementable units and define acceptance criteria (AC) and a verification approach for each feature.

- Location: `docs/apd/spec-{feature}.md` (`{feature}` is an issue number or a short name)
- Skill: `/apd:spec [full|add|bugfix]`
- 3 modes:
  - **full**: generate the first full Spec (including Design scoping)
  - **add**: Spec for an added feature (new spec file)
  - **bugfix**: edit the existing Spec directly and bump `version`
- Structure of each Spec: User Story, Acceptance Criteria (Given/When/Then), UI description, Context Boundary, Test Strategy (AC Coverage), Deliverable Previews

### Plan

A light design for changes that do not warrant a Spec (refactors that do not change behaviour, internal technical changes, development tooling, infra, configuration, scripts, multi-file fixes). No file is created: present it in the conversation, enter Build once approved, and put the same design at the top of the PR body.

- Skill: `/apd:plan` (the AI chooses it itself from the request. Usable even in repositories without `/apd:init`)
- Contents: goal / files to change and approach / alternatives considered and why they were not taken / verification method
- If it involves a technical decision, append it to `docs/apd/decisions.md`

### Deciding the classification

When asked to build or change something, the AI decides and declares one of Design / Spec / Plan / No design before writing code (criteria in `rules/apd/02-cycle-flow.md`). The plugin's SessionStart hook puts these criteria into context every session, so work starts from the design even if the user types no command.

### Build

Implement from an approved Spec or Plan.

- Skill: `/apd:go <spec file>` (for a Spec. The AI chooses it from just an approval reply)
- Behaviour (Build on the spot, default):
  1. Read the Spec and extract the AC, test strategy and deliverable preview requirements
  2. Assemble the completion condition (all AC met + tests pass + "How to try it" written in the PR)
  3. Summarize the completion condition in the conversation and go straight into implementation. Done when all conditions are met and the PR is opened
- Behaviour (Build with `/goal`, optional): when you want a long unattended run, the completion condition is presented as a `/goal` condition and the user pastes it in auto mode → the evaluator judges completion at the end of each turn (evaluation is deferred for turns with background work; see the "Test policy" section for details)
- Parallelization: choose subagent / agent teams / dynamic workflows / `/batch` if needed (APD does not enforce it)
- Convergence check: the AI surfaces test run logs and the PR diff in the conversation within the turn (the `/goal` evaluator also judges only from information surfaced in the conversation)

### Hands-on check after completion

The human follows the PR's "How to try it" section and tries it on a real device.

- OK → merge the PR → issue closes automatically (GitHub environment)
- NG → reply with a comment → next cycle (edit the Spec, append a Decision, etc.)
- AC the AI cannot verify automatically (real device only, subjective human evaluation, etc.) are judged here

---

## Document management

### Living documents + git as the source of truth

Once a document is created, **keep editing it in the same place**. Do not stack diffs in separate files (Amendment / Patch). git log / git blame is the source of truth for "what it used to be".

Continually moving and adding files leads to missed moves and inconsistencies. Design so that **moves are not assumed**.

### 3 kinds of files

```
docs/apd/
├── design.md            ← north star (keep editing)
├── decisions.md         ← append-only decision log (single file)
└── spec-{feature}.md    ← one per feature (keep editing)
```

- Do not create subdirectories
- Files increase only when building a new feature (an essential increase, so it is acceptable)
- When a feature is removed, remove its Spec too (this is the only "deletion")
- Add `docs/apd/preview-{feature}/` only when creating deliverable previews (optional)

### Where the human checks = GitHub

The specs in `docs/apd/` are **working material for the AI**, not a place humans scan routinely. What humans look at:

| What you want to know | Where to look |
|------------|---------|
| In progress / backlog | `gh issue list` |
| Accept an individual change | Hands-on check via the PR's "How to try it" |
| The whole product picture | `docs/apd/design.md` |

Do not put human dashboards (INDEX etc.) in `docs/apd/`. They add more things to keep in sync, a risk of the same kind as missed moves, so use GitHub (issue + PR) as the human dashboard.

### Updating Specs and recording Decisions

- **Spec changes**: edit the existing `spec-{feature}.md` directly and bump `version`. The reason for the change goes in the git commit message
- **Recording Decisions**: append to the single `docs/apd/decisions.md`. To reference a specific decision from a Spec, use an anchor reference such as `decisions.md#d-001`

### Do not put the Handoff ("How to try it") in a file

When Build is complete, write it in the "## How to try it" section of the PR body. Reasons:
- The PR body is where the human looks next
- It can be checked side by side with the diff during review
- When a re-build of the same feature creates a new PR, the Handoff is naturally brought up to date

### Backlog

If the project has an issue tracker, use it as **the backlog**: whatever CLAUDE.md or the user names (GitLab, Linear, Jira, etc.), otherwise GitHub issues when `origin` is on GitHub and `gh` is installed. Credentials are not read to decide. One issue = one cycle is the norm. Cross-linking the issue number with the Spec / PR automatically leaves a trail of the cycle. **Everything is done with the local `gh` CLI** (creating, viewing and commenting on issues, linking them to PRs). There is no need to set up GitHub Actions.

Without an issue tracker, use `docs/apd/todo.md` (append-only).

### GitHub Actions / routines are optional

If asynchronous team triggers are needed (automatic review on PR open, etc.), you can optionally add GitHub Actions or routines. However, for individual development or small teams, **the local `gh` + Claude Code skill invocations are enough**, and APD does not ship workflow files.

---

## Escalation

When a decision comes up:

1. **It is stated in CLAUDE.md** → follow it
2. **It is not written in CLAUDE.md** → the leader agent (AI) decides
3. **The leader agent cannot decide** → raise it up front in the Spec, or the human notices it during the hands-on check after completion and fixes the Spec in the next cycle

Promote frequent decisions to CLAUDE.md to widen the autonomous range.

Do not escalate to the human during Build (zero interruptions). If a decision not in the Spec is needed (new business rules, external interface changes, security/authentication, breaking data model changes, etc.), either **raise it up front in the Spec** so the human checks it in advance, or **notice it during the hands-on check after completion and fix the Spec in the next cycle**. Details in `rules/apd/01-phases.md`.

---

## Unified cycle-based flow

Treat every change uniformly as a "cycle". Fixes are made in a new cycle (moving forward, not going back).

| Trigger | Flow |
|---------|--------|
| New product / major change of direction | Intent → Spec → Build → hands-on check |
| New feature | Spec (referencing the existing Design) → Build → hands-on check |
| Bug fix / spec change | Edit the existing Spec (version↑) → Build → hands-on check |
| Technical change (refactor etc.) | Decision Record → Build → hands-on check |

### Bug triage

When a bug report or test failure comes in, the AI first determines the cause:

- **Caused by the Spec** (missing or ambiguous specification) → escalate to the human → cycle that edits the existing Spec
- **Caused by the Build** (implementation does not match the Spec) → the AI fixes it autonomously → do not raise it to the human

---

## Git practice

### Branches

- With an issue: `feat/{issue#}-{slug}` / `fix/{issue#}-{slug}` / `chore/{slug}`
- Without an issue: `{type}/{slug}`

Create from `main` and merge via PR when the cycle is complete.

### Parallel execution

When running multiple tasks in parallel during Build, use git worktree. Claude Code subagents can start with file isolation via `isolation: "worktree"`, so APD has no worktree management scripts of its own.

### Commit conventions

- Follow Conventional Commits (`feat:`, `fix:`, `refactor:` etc.)
- Include the related Spec ID / issue number in the body or footer (e.g. `Refs: spec-42 / Closes: #42`)

---

## Test policy

- All tests passing is mandatory
- What to test and how is defined in the Spec's Test Strategy section and AC Coverage table
- Quality axes that cannot be verified automatically (real device only, subjective human evaluation, etc.) are checked by the human during the hands-on check after completion

### Build convergence check

Build convergence is judged by the build AI checking the completion condition (AC met, tests pass, Handoff written). When building with `/goal`, the evaluator judges the same condition. Because the evaluator judges only from information surfaced in the conversation, in either case the AI, within the turn:

- Outputs the test run log
- Summarizes the implementation changes
- Surfaces the PR diff and PR body

This lets the user (and the `/goal` evaluator) confirm that the AC are met, tests pass and the Handoff is written.

There is an exception to the timing of evaluation when using `/goal`. If a turn ends while a subagent or background shell is still running, that turn is not evaluated; judgement happens at the end of the next turn with no background work. If background work keeps the goal waiting for 30 minutes or more, Claude Code automatically inserts a check-in (by default 30 minutes → 1 hour → every 2 hours after that, capped at 4 times the first interval). Check-ins delivered at the end of a turn have no limit, but idle check-ins, which Claude Code delivers by starting a turn itself in an interactive session, are limited to at most 3 per goal between user prompts, and the third one announces that it will "stop until the next prompt".
