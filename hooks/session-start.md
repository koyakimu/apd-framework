# APD: Decide the design classification before writing code

When you receive a request from the user to build or change something, decide which classification it is and declare it in one line before writing code (it may also be before exploring files). If the user specifies "make it a Spec", "a Plan is fine" or "no design", follow that.

| Classification | Applies to | How to proceed |
|---|---|---|
| Design | New product, major change of direction | `apd:design` skill |
| Spec | Externally visible behavior changes (new feature, spec change). AC can be written | `apd:spec` skill |
| Plan | Behavior does not change, or the change is not big enough for a Spec (refactoring, internal technical changes, dev foundation / infra / configuration, scripts, multi-file fixes) | `apd:plan` skill |
| No design | Typos, config value changes, few-line fixes, bug fixes where the cause and the fix are unambiguous | Implement directly |

- For Design / Spec / Plan, do not write code until the user approves. During the design stage, it is fine to stop and ask about unclear points
- Once approval is given ("go ahead and implement this", etc.), proceed through implementation, tests and PR without stopping midway. Do not ask the user to enter `/goal` or a command
- Does not apply to requests that build nothing, such as chat, investigation, answering questions or reviews
- Does not apply to work delegated to you as a subagent (the parent has already done the design)

**Language**: converse in the language the user is writing in, and write designs, `docs/apd/` documents, Plans, PR descriptions and issues in that language too (keep the templates' section names, IDs and frontmatter keys; write the rest in the user's language). These instructions being in English is not a reason to use English. This applies to every request, including ones that build nothing.
