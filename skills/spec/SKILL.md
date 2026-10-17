---
name: spec
description: >
  Generates or updates Spec documents from the Design document.
  Supports three modes: full (initial generation), add (new feature
  spec), and bugfix (edit an existing spec in place). Use before
  writing code when the user asks to implement a new feature or
  change user-visible behavior and no Spec covers it yet, even if
  the user did not ask for a spec; if APD is not initialized, propose
  initializing it (apd:init) first (for small changes in such repos, apd:plan is
  enough). Also use when the user asks to generate specs, add a
  feature spec, fix a bug spec, or run /apd:spec ("Spec を生成",
  "仕様書を作成", "機能追加の Spec", "バグ修正").
argument-hint: "[full|add|bugfix] [issue#?]"
---

# APD Spec — Generate and update specifications

The AI drafts the Spec; the human reviews only the summary and the items flagged for confirmation.

## Always

- Do not write code until the Spec is approved
- Once approval is given (e.g. "go ahead and implement this"), enter Build right away following the `apd:go` procedure. Do not ask the user to type a command. Output a condition for `/goal` only when the user wants a long unattended run
- Do not mark the Spec review complete until every decision in `decisions.md` has the user's Decision and Reason filled in
- Do not put anything listed in the Design's What Not into the Spec
- Edit existing Specs directly and bump `version`. Do not pile up diffs in separate files

## Preparation

Read: `docs/apd/design.md`, existing `docs/apd/spec-*.md` and `docs/apd/decisions.md` (if any), and the target GitHub issue (if any, `gh issue view {number}`).

## Mode selection

Determine the mode from the user's instruction or the trigger type:

- **full** — initial full Spec generation
- **add** — feature-addition Spec (new spec file)
- **bugfix** — fix to an existing Spec (in-place edit)

If unclear, ask the user.

---

## Mode: full (initial full Spec generation)

### Scoping

Review every feature listed in the **What** section of the Design document, and decide **the scope of this cycle** in dialogue with the user:

1. List all features and propose classifying them as **in scope this time** and **out of scope (implemented in a later cycle)**
2. Ask for the user's decision and finalize the scope
3. **Record out-of-scope features in the backlog**. Where GitHub issues are available, file them with `gh issue create` and add the `apd:scope-out` label. Otherwise, append them to `docs/apd/todo.md`
4. Generate Specs only for the features in the finalized scope

### Generation rules

1. Create a Spec for each in-scope feature (one file per feature)
2. Each Spec includes:
   - `spec_id`: context abbreviation + sequence number (e.g. AUTH-001)
   - `issue_ref`: related GitHub issue number (if any)
   - `version: 1`
   - User story (who, what, why)
   - Acceptance criteria (Given/When/Then format)
   - UI description or mock instructions (where applicable)
   - Context boundary definition (inputs / outputs / dependencies)
   - **Test strategy** (AC Coverage table)
   - **Deliverable preview description** (optional; only when needed)
   - **Non-functional requirements**: write measurable ones as ACs (AC-NFR-xxx) in Given/When/Then format. For those that cannot be written in measurable form (security, etc.), state the delegate (/security-review, etc.) in the "Delegated non-functional requirements" section
3. If data flow between contexts is complex, summarize it in `docs/apd/cross-context-scenarios.md` (use a name distinct from `spec-*.md`)
4. Append any points that required a decision to `docs/apd/decisions.md`

### Output

1. **Spec files** — `docs/apd/spec-{slug}.md`. `{slug}` is the issue number if there is one, otherwise a short slug
2. **Review checklist** (see below)
3. **Confirmation request list** (see below)
4. **Appended decisions** — `docs/apd/decisions.md` (if any decisions arose)

---

## Mode: add (feature-addition Spec)

### Addition rules

1. Check consistency with existing Specs and report any contradictions
2. Create the new feature as a **new Spec file** (`docs/apd/spec-{slug}.md`)
3. If existing Specs are affected, edit those existing Specs directly and bump `version`
4. If cross-context data flow is affected, edit `cross-context-scenarios.md`

### Output

In addition to the full-mode output:

- Impact analysis on existing Specs
- List of existing Specs that need editing

---

## Mode: bugfix (fix to an existing Spec)

### Triage

First determine the cause:

- **Spec-caused** (missing or ambiguous specification) → edit the existing Spec
- **Build-caused** (implementation does not match the Spec) → report "This is Build-caused. I'll fix only the implementation without changing the Spec", and once the user agrees, start the fix right away following the `apd:go` procedure

### If Spec-caused

**Edit directly** the relevant `docs/apd/spec-{slug}.md`:

1. Fix the relevant AC, or add a new AC
2. Bump `version` in the frontmatter
3. Write the reason for the change in the git commit message
4. If a specification decision is needed, append it to `docs/apd/decisions.md`

---

## Technology selection (decisions.md)

In parallel with Spec generation, append the major technology choices to `docs/apd/decisions.md` and ask for the user's decision.

### Identifying technology choices that need a decision

For the following areas, list the items not already settled in CLAUDE.md:

- Programming language / runtime
- Framework / libraries
- Build tool / bundler
- Database / storage
- Infrastructure / deployment
- Other project-specific important technology choices

### Entry format

Append new decisions to `docs/apd/decisions.md` (newest on top):

```markdown
## D-{NNN}: {Decision title}
- **Date**: YYYY-MM-DD
- **Context**: {Why this decision is needed}
- **Options**:
  - A: {Option A (proposed by AI)}
  - B: {Option B (proposed by AI)}
- **AI Recommendation**: {Option the AI recommends}: {Summary of the reason}
- **Decision**: {What was chosen — filled in by the user}
- **Reason**: {Why — filled in by the user}
- **Refs**: {Related spec / issue}
```

The canonical format is `${CLAUDE_PLUGIN_ROOT}/templates/decision.md`.

### Presenting to the user and approval

Present all decision drafts and ask the user to fill in `Decision` and `Reason` for each item.

### When already settled in CLAUDE.md

If CLAUDE.md explicitly specifies the tech stack, you may skip appending decisions. However, ask the user "Are there any other technology choices we should consider?"

---

## Common output: Review checklist

Summarize the status of the following as a table:

| Check item | Status | Notes |
|---|---|---|
| Every feature has a Spec | ✅/⚠️/❌ | |
| Each Spec has a user story | ✅/⚠️/❌ | |
| Each Spec has acceptance criteria | ✅/⚠️/❌ | |
| Each Spec has a UI description (where applicable) | ✅/⚠️/❌ | |
| Context boundaries are defined | ✅/⚠️/❌ | |
| Each Spec has a test strategy (AC Coverage) | ✅/⚠️/❌ | |
| Decisions are recorded in decisions.md (when decisions arose) | ✅/⚠️/❌ | |
| Every technology choice has the user's decision filled in | ✅/⚠️/❌ | |

## Common output: Confirmation request list

Make explicit the parts filled in by inference and the parts you are unsure of:

```
## Items needing confirmation
1. [spec_id] [location]: [what was inferred] ← please confirm
2. ...
```

## Review

When the Spec is complete, present the following checklist:

- [ ] Is every item in the review checklist ✅?
- [ ] Have you given a decision on each item in the confirmation request list?
- [ ] Have you filled in Decision and Reason for each decision in decisions.md?
- [ ] Has anything listed in What Not slipped into the Spec?

If corrections are requested, update the draft and present it again.
