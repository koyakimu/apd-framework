# APD Document Management

## Living documents + git as the authoritative history

- Once a document is created, **keep editing it in the same place**. Do not pile up diffs in separate files (Amendment / Patch)
- For "what it used to be", **git log / git blame** is the authoritative history
- AI work record: Git commit log + PR history
- Human decision record: `decisions.md` (a single append-only log)

Constantly moving and adding files leads to missed moves and inconsistencies. Design so that **moving files is not assumed**.

## Document tree (3 file types)

```
docs/apd/
├── design.md            ← north star (keep editing; rarely changes)
├── decisions.md         ← append-only decision log (single file)
└── spec-{feature}.md    ← one per feature (keep editing)
```

- Do not create subdirectories
- Files are added **only when building a new feature** (an essential increase, so acceptable)
- When a feature is removed, remove that feature's Spec too (this is the only "deletion")
- Add `docs/apd/preview-{feature}/` only when creating deliverable previews (optional; see `05-deliverable-preview.md`)
- Add `docs/apd/cross-context-scenarios.md` only when data flow between contexts is complex (optional; name it differently from `spec-*.md` so it is not confused with Specs that are build targets)

### Naming guidelines

- `{feature}` in `spec-{feature}.md` is the issue number (or ID) in the project's issue tracker if there is one, otherwise a short slug
- The Spec ID is defined separately in the frontmatter (`spec_id: "AUTH-042"` etc.)

## Human review surface = PRs and issues

The specs in `docs/apd/` are **working material for the AI**. The human is not expected to scan them day to day. What the human looks at:

| What they want to know | Where to look |
|------------|---------|
| In progress / backlog | The project's issue tracker (e.g. `gh issue list`; updated automatically, no sync needed), or `docs/apd/todo.md` when there is none |
| Accept an individual change | The "How to try it" section of that PR (post-completion hands-on check) |
| Overall product picture | `docs/apd/design.md` |

Do not place a "human dashboard (INDEX etc.)" in `docs/apd/`. It adds things to keep in sync, a risk of the same kind as missed moves. Use the PRs and the issue tracker as the human dashboard.

## Backlog (issue tracker)

- If the project has an issue tracker, use it as the backlog. Decide which one in this order: (1) what the project's CLAUDE.md states, (2) what the user says, (3) GitHub issues, if the `origin` remote is on GitHub and the `gh` command is installed. Other trackers (GitLab, Linear, Jira, etc.) are used through whatever tool or connector is available
- If there is none, use `docs/apd/todo.md` (append-only)
- Do not read credentials or tokens to decide. If a tracker command fails (e.g. not signed in), tell the user and append to `docs/apd/todo.md` instead
- Where the tracker supports labels, classify items with `apd:todo` / `apd:scope-out`

## Spec format

Markdown with YAML frontmatter. A Spec is a living document that keeps being edited, so bump `version` to reflect changes.

````markdown
---
spec_id: "{CONTEXT_ID}-{NNN}"
context: "{context name}"
version: 1
issue_ref: "{issue number or ID in the project's tracker, or null if none}"
title: ""
decision_refs: []
---

## User Story

**As a** {who}
**I want** {what}
**So that** {why}

## Acceptance Criteria

### AC-001
- **Given**: {precondition}
- **When**: {triggering action}
- **Then**: {expected result}

## UI Description

{mock or UI description (if applicable)}

## Context Boundary

### Inputs
- **From**: {source} — {description of the data}

### Outputs
- **To**: {destination} — {description of the data}

### Dependencies
- **{context depended on}**: {reason for the dependency}

## Test Strategy

### AC Coverage

| AC ID | Test Type | Description |
|-------|-----------|-------------|
| AC-001 | unit / integration / e2e | {what is tested} |

## Deliverable Previews

{types and descriptions of previews to generate (optional; only if applicable)}

## Notes

{additional considerations, constraints, assumptions, etc.}
````

### Updating a Spec

For bug fixes and spec changes, **edit the existing Spec directly**:

1. Fix or add the relevant AC
2. Bump `version` in the frontmatter
3. Write the reason for the change in the git commit message (do not leave diffs in a separate file)

## decisions.md format

Append technical choices and design decisions to the single `docs/apd/decisions.md`. Newer decisions go on top. The canonical format is `templates/decision.md`.

````markdown
# Decisions

## D-002: {decision title}
- **Date**: YYYY-MM-DD
- **Context**: {why this decision was needed}
- **Options**:
  - A: {option A (proposed by AI)}
  - B: {option B (proposed by AI)}
- **AI Recommendation**: {option the AI recommends}: {summary of the reason}
- **Decision**: {what was chosen — filled in by the user}
- **Reason**: {reason / trade-offs}
- **Refs**: {related spec / issue}

## D-001: {decision title}
- ...
````

To reference a specific decision from a Spec, use an anchor such as `decisions.md#d-001`.
