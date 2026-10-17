---
name: status
description: >
  Reports where the project stands in the APD flow and the sensible
  next step, based on docs/apd/ state and the conversation. Use when
  the user asks where they are or what to do next, or runs /apd:status
  ("今どこ", "次なに", "状況確認", "APD の状態").
---

# APD Status — Current position and next step

Determine and report the current position in the APD flow and the next step, from both the state of the files and the context of the conversation.

## Steps

### 1. Gather the state

- Whether `docs/apd/design.md` exists
- Whether `docs/apd/spec-*.md` exist, and the list (if any, look at each Spec's `status` / `version`)
- Open PRs / issues (in environments where `gh pr list` / `gh issue list` are available)
- The content of the recent conversation (whether this is new development with APD, or other work such as maintenance or investigation)

### 2. Determine the current position

| State | Current position | Standard next step |
|------|--------|----------------|
| No `design.md` | Not started | `/apd:design` |
| `design.md` exists / no `spec-*.md` | Designed | `/apd:spec` |
| `spec-*.md` exists / before Build | Specified | Approve and Build with `apd:go` |
| Plan approved in the conversation / before Build | Designed (Plan) | Build following the `apd:plan` steps |
| Built, PR exists | Awaiting verification | Hands-on check after completion |

The conversation's context may override the basis for the judgement. Example: even if a spec exists, if the user is currently editing a different Spec, that one is the current position.

### 3. Report

Output concisely:

```
## APD current position
- State: {current position} (basis: {files/PRs looked at})
- Next step: {command or action}
- Note: {caveats based on the conversation's context}
```

If the conversation is unrelated to APD, do not force it toward the next APD step. Report only the current position and leave whether to proceed to the user.
