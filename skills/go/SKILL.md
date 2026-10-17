---
name: go
description: >
  Starts Build for an approved Spec. By default builds right away in
  the current session, using the Spec's Acceptance Criteria as the
  completion checklist; optionally assembles a /goal condition for a
  long unattended run. Use when the user approves a Spec and asks to
  implement it ("この方向で実装して", "実装を開始", "ビルドを開始"),
  or runs /apd:go. If neither a Spec nor an approved Plan covers the
  work, do not build — go to apd:spec or apd:plan first.
argument-hint: "<spec-file or issue#>"
---

# APD Go — Build for an approved Spec

## Always

- Do not Build if there is neither a Spec covering the work (`docs/apd/spec-*.md`) nor a Plan approved in this conversation. Go to `apd:spec` for a Spec, or `apd:plan` if a Plan is enough. Build an approved Plan following the `apd:plan` steps
- By default, Build on the spot. Summarize the completion condition in 3–5 lines in the conversation, then proceed through implementation, tests, and PR without stopping for confirmation. Do not ask the user to type a command
- Build with `/goal` only when the user wants a long unattended run. Steps: [goal.md](goal.md)
- Do not escalate to the user during implementation. For decisions not in the Spec, follow what the Spec has already settled in advance, or defer them to the hands-on check after completion
- When every item of the completion condition (including the Spec check) is met and the PR is open, report Build as complete
- Write the PR description (including "How to try it") and any issues in the user's language (`rules/apd/00-principles.md` › Language)

## 1. Identify the target Spec

Use the argument if given. Otherwise, present candidates from `docs/apd/spec-*.md`.

## 2. Read the Spec

Read the whole Spec and `docs/apd/design.md`, and pick out: AC IDs and Given/When/Then, the test types in AC Coverage, whether there are Deliverable Previews, `decision_refs`, and delegated non-functional requirements (`/security-review` etc.). Decide how to run tests by looking at the project.

If you find any of the following, report it as a warning before Build and wait for the user's decision:

- A decision referenced in `decision_refs` is missing from `docs/apd/decisions.md`
- Deliverable Previews are listed but the deliverables do not exist

## 3. Assemble the completion condition

Quote the Spec's wording, and write it so it can be judged from evidence put in the conversation (do not use abstract phrases like "with good quality").

**Acceptance criteria**
- List every AC in the Spec with its ID and a summary of its Given/When/Then

**Verification**
- Automated tests pass, tests exist as per the AC Coverage policy, and existing tests are not broken
- Spec check: before completion, check each AC against the Spec and Design, and put "OK / deviation / not implemented" with evidence (file:line) in the conversation. Fix deviations and unimplemented items before calling it complete
- Results of running delegated non-functional requirements are OK
- Put test run logs, the changes, and the results of checking deliverables in the conversation

**Handoff**
- Create or update the PR, and write a reference to the Spec and "How to try it" in the body. "How to try it" gives steps for a person to verify each AC hands-on on a real device
- For AC that cannot be verified automatically (real-device only, external services, subjective evaluation), treat implementation plus the "How to try it" entry as complete, and state so explicitly

**Constraints**
- Do not add business rules not in the Spec or refactoring outside the Spec's scope. Follow the decisions in `decisions.md`
- If you loop on the same issue, stop and report
- If the Spec check keeps failing, leave the work so far in a draft PR, stop, and defer to the hands-on check after completion

## 4. Build

For parallelization, use subagents by default (with `isolation: "worktree"` if they modify files).
