# APD Quick Reference

## Phases at a glance

| Phase | Whose time | What to do | Deliverables | Done when |
|---------|---------|---------|--------|------------|
| **Intent** | Human + AI | Write the Design document through dialogue | `docs/apd/design.md` | Human agreement |
| **Spec** | Human + AI | AI drafts → human reviews | `docs/apd/spec-*.md` + `docs/apd/decisions.md` | Human agreement |
| **Plan** | Human + AI | Present the design of a change that gets no Spec in the conversation → human reviews | Conversation + PR body | Human agreement |
| **Build** | AI autonomous | Implementation + tests + PR | `src/` + `tests/` + PR (with "How to try it") | Completion condition met (when using `/goal`, the evaluator converges) |
| **Hands-on check** | Human | Try it on a real device | merge or send back | Human judgement |

## Skill flow

```
① A change comes up
   └→ File an issue in the project's tracker, or append to todo.md if there is none
      └→ If needed, create/update the Design document with /apd:design

② Design (decide the classification before writing code; just ask and the AI proposes one)
   └→ Behaviour changes → Spec / no change or small → Plan / typo or a few lines → No design
   └→ Plan: /apd:plan presents the design in the conversation → approval → go to ③ Build
   └→ Spec: /apd:spec [full|add|bugfix] generates a Spec draft
   └→ In full mode, scoping → out-of-scope items go to the backlog
   └→ Review only the parts flagged for review → feedback → agreement

③ Build
   └→ Approve with something like "go ahead and implement this" → the AI starts implementing on the spot (does not stop midway; no command needed)
   └→ Run in auto mode (convention)
   └→ Only when you want a long unattended run, use /apd:go to build a /goal condition and paste it
   └→ If parallelization is needed, use subagent / agent teams / dynamic workflows / /batch
   └→ On completion, "How to try it" is written in the PR body

④ Hands-on check
   └→ The human follows the PR's "How to try it" and tries it on a real device
   └→ OK → merge → issue closes automatically
   └→ NG → reply with a comment → next cycle (edit the Spec, etc.)
```

## First-time setup

```
/apd:init  → copy rule files + create docs/apd/ + backlog guidance
```

## When unsure

```
/apd:status  → shows where you are and the next step (judged from file state + conversation context)
```

The AI normally offers the next step on its own at milestones (`.claude/rules/apd/07-next-step.md`). Type `/apd:status` only when you want to check explicitly.

## What the human does (and only this)

### Intent / Spec: decide the intent
- Create the Design document through dialogue
- Review the parts of the Spec draft flagged for review
- Decide scope
- Fill in decisions in Decision Records

### Hands-on check: accept
- Follow "How to try it" in the PR body and try it on a real device
- Check that the working deliverable is as expected
- If OK, merge; if NG, send back (next cycle)
- **No code review is required**

## Decision flow

```
Is it written in CLAUDE.md?
  ├─ Yes → follow it
  └─ No → can the leader agent decide?
              ├─ Yes → the leader decides
              └─ No → escalate as part of the hands-on check after completion
```

## File layout (3 kinds)

```
docs/apd/
├── design.md            ← north star (keep editing)
├── decisions.md         ← append-only decision log (single file)
└── spec-{feature}.md    ← one per feature (keep editing)
```

- **Each document is a single living document**. Do not stack diffs in separate files. To change something, edit the existing file and bump `version`. git is the source of truth for history
- Files increase only when building a new feature
- Add `docs/apd/preview-{feature}/` only when creating deliverable previews (optional)
- `{feature}` is the issue number in the project's tracker if there is one (e.g. `spec-42.md`), otherwise a short slug

## Which Claude Code feature to use

| Purpose | Feature |
|------|---------|
| Autonomous Build loop | `/goal` |
| Isolating side tasks | subagent (`isolation: "worktree"` if needed) |
| Multi-session coordination | agent teams (experimental, disabled by default; requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) |
| Large-scale parallelization | `/batch` (stops once after decomposition to ask for approval of the plan; requires a git repository) |
| Scripted large-scale fan-out | dynamic workflows (start by including `ultracode` in the prompt or asking to do it "with a workflow"; check running runs with `/workflows`) |
| In-session todo | Task tools (`TaskCreate` etc.). Not provided by default on Opus 4.8 / Sonnet 5 / Fable 5 / Mythos 5 and later; the model tracks multi-step work itself |
| Accumulated knowledge | auto memory |
| backlog | The project's issue tracker (e.g. GitHub issues) or `docs/apd/todo.md` |
| GitHub integration | The local `gh` CLI is enough. GitHub Actions/routines are optional |
| Handoff ("How to try it") | PR body |
| Where the human checks | PRs and issues. `docs/apd/` is the AI's workspace; do not scan it routinely |
| Document history | git log / git blame (do not stack diff files) |
