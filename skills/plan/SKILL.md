---
name: plan
description: >
  Writes a lightweight implementation plan (goal, files and approach,
  alternatives considered, how to verify) in the conversation, gets
  the user's approval, then builds without stopping. No Spec file is
  created and APD does not need to be initialized. Use before writing
  code for a change that does not alter user-visible behavior or is
  too small for a Spec — refactoring, internal technical changes,
  dev tooling / infra / config, scripts, multi-file fixes — even if
  the user did not ask for a plan. Also use when the user asks for a
  plan or runs /apd:plan ("設計して", "方針を出して", "Plan を作って").
  Skip it for typos, config value changes, few-line edits, and bug
  fixes whose cause and fix are both obvious.
---

# APD Plan — Lightweight design (changes without a Spec)

Put the design for a change that does not warrant a Spec into the conversation, and enter Build after approval. It creates no files, so use it even in repositories where APD has not been initialized.

## Always

- Do not write code until the Plan is approved
- After approval, proceed through implementation, tests, and PR without stopping. Do not ask the user to type a command
- Only if the Plan's assumptions break during implementation, stop, fix the Plan, and get approval again
- Converse and write documents in the user's language; keep the templates' section names, IDs and frontmatter keys as they are (`rules/apd/00-principles.md` › Language)

## 1. Confirm the classification

Determine whether a Plan is enough for the request and declare it in one line (e.g. "This is a dev infrastructure change that does not alter product behavior, so I'll design it with a Plan").

| Request | Classification |
|------|------|
| New product, major change of direction | Design → `/apd:design` |
| Externally visible behavior changes (new feature, spec change). AC can be written | Spec → `/apd:spec` |
| Behavior does not change, or too small for a Spec | **Plan (this skill)** |
| Typo, config value change, few-line fix, bug fix with a single obvious cause and fix | Implement with no design |

In a repository without `docs/apd/`, there is nowhere to put a Spec, so small changes that alter behavior may also be handled with a Plan. For a large new feature, suggest running a Spec starting from `/apd:init`. If the user specifies a classification, follow it.

## 2. Investigate

Read the codebase, the existing `CLAUDE.md`, and `docs/apd/decisions.md` (if present), and gather the facts needed for the design. If anything about the intent or requirements is unclear, ask here (at the design stage it is fine to stop and ask).

## 3. Present the Plan

Put the following in the conversation. Scale the length to the size of the change.

- **Goal**: what it is for and what becomes possible
- **Files to change and approach**: what to change and how, per file
- **Alternatives considered and why they were not taken**: at least one
- **How to verify**: which tests, commands, or operations determine completion
- **Points to confirm** (if any): issues that need the user's judgement, and the AI's recommendation

If it includes decisions that will be referred to later, such as technology selection, append them to `docs/apd/decisions.md` after approval (only in repositories that have `docs/apd/`. Format: `${CLAUDE_PLUGIN_ROOT}/templates/decision.md`).

## 4. Wait for approval

After presenting, stop and wait for the user's reply. If they ask for revisions, fix the Plan and present it again.

When approval comes ("go ahead and implement this", "OK", "proceed", etc.), enter Build.

## 5. Build

- Confirm completion using the means written under How to verify, and put the results (test run logs, operations checked) in the conversation
- If you open a PR, put the approved Plan at the top of the body, followed by "How to try it"
- Do not refactor or add features outside the Plan. File any other problems you find as issues

## What this skill deliberately does not do

- Generate files — the Plan lives in the conversation and the PR body. Do not create plan files in `docs/apd/`
- Define AC — changes whose behavior should be pinned down by AC go to a Spec
