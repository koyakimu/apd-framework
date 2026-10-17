---
name: init
description: >
  Initializes APD in this project. Copies framework rules to
  `.claude/rules/apd/` and creates the `docs/apd/` document
  directory. Use when the user asks to initialize APD, set up
  APD, or run /apd:init ("APD を初期化", "APD をセットアップ"), or
  when the user agrees to a proposal to initialize APD. Never run it
  without the user's explicit agreement.
---

# APD Init — Project initialization

Copy the rule files and create the document directory. Do not modify CLAUDE.md.

## Steps

### 1. Check the existing state

Check the following:

- Whether `.claude/rules/apd/` already exists
- Whether `docs/apd/` already exists
- Whether `gh auth status` succeeds (to decide whether to use GitHub issues as the primary backlog)

If APD is already initialized, ask the user "Update the rule files to the latest version?"

### 2. Copy the rule files

Copy the rule files bundled with the plugin into the project:

```bash
mkdir -p .claude/rules/apd
cp "${CLAUDE_PLUGIN_ROOT}/rules/apd/"*.md .claude/rules/apd/
```

### 3. Create the document directory

Create `docs/apd/`. Do not create subdirectories:

```bash
mkdir -p docs/apd
```

### 4. Initialize the backlog

Create `docs/apd/todo.md` only in environments where `gh auth status` fails (where it succeeds, GitHub issues are the backlog):

```bash
if ! gh auth status >/dev/null 2>&1; then
  if [ ! -f docs/apd/todo.md ]; then
    cp "${CLAUDE_PLUGIN_ROOT}/templates/todo.md" docs/apd/todo.md
  fi
fi
```

If you created `docs/apd/todo.md` and the user is writing in a language other than English, translate its headings and text into that language. Write the completion message below in the user's language as well.

### 5. Completion message

Output the following:

```
## APD initialization complete

Copied:
  - .claude/rules/apd/  — APD framework policy (auto-loaded by Claude Code)

Created:
  - docs/apd/           — location for APD documents (flat structure)
  {if gh is unavailable: }
  - docs/apd/todo.md    — ToDo backlog (fallback. GitHub issues are used when gh is available)

Backlog operation:
  {if gh is detected: }
  - Use GitHub issues as the primary backlog
  - Classify issues with labels such as apd:todo / apd:scope-out when filing
  {if gh is absent: }
  - Append to docs/apd/todo.md (append-only)

```

### 6. Return to the original flow

If initialization was proposed while creating a Spec or Design, return straight to the original steps (`apd:spec` / `apd:design`). If only initialization was requested, ask the user whether to start with the Design. Do not ask the user to type a command.

The rules in `.claude/rules/apd/` are loaded automatically from the next session.
