---
name: migrate
description: >
  Migrates an existing APD project to the current model: folds Patch
  files into their Spec, consolidates per-file Decision Records into a
  single decisions.md, flattens old subdirectories, updates frontmatter,
  cleans APD cruft out of CLAUDE.md (injected banners, duplicated/stale
  rules, deprecated commands), and refreshes .claude/rules/apd/ to the
  installed version. Run with /apd:migrate after updating the APD
  plugin.
disable-model-invocation: true
argument-hint: "[--dry-run]"
---

# APD Migrate — Move an existing project to the current model

Bring an existing APD project's `docs/apd/`, CLAUDE.md, and `.claude/rules/apd/` in line with the current model. Key points of the current model:

- Each document is a single living document (do not pile up diffs in separate files; git is the history)
- 3 file types: `design.md` / `decisions.md` / `spec-{feature}.md`
- Patch files are abolished → fold them into the parent Spec
- Decisions are no longer per-file; consolidate them into a single `decisions.md`
- Preview is optional
- The human review surface is GitHub (PR + issue)
- Terms, commands, and hooks are unified to the current (3.x) ones: **post-completion hands-on check** / `/apd:go` / the plugin has no Stop hook (since 3.6.0 it has a SessionStart hook, used only to inject the design classification)
- **CLAUDE.md holds "only project-specific things"**. The single source of truth for generic APD rules is `.claude/rules/apd/` (auto-loaded)

Verify with `scripts/verify-migration.sh` (bundled with the plugin).

## Always (safety principles)

- **Do not change anything without a backup** (both docs/apd/ and CLAUDE.md)
- **When in doubt, make it a manual review item**
- **Always keep project-specific content in CLAUDE.md**: remove only generic APD rules; do not delete project-specific conventions, settings, or state
- **Overwrite rules only after checking the diff**: do not crush local customizations
- **Read the content before folding a Patch**; **preserve order when consolidating Decisions**
- **Idempotent**: safe to re-run. Skip anything already current

## Source patterns

Look at the project's current state and apply whichever apply (more than one is possible):

- **0.x (subdirectory layout)**: `docs/apd/{design,specs,decisions,cycles,previews}/` exists
- **1.0.x (flat + Patch files)**: `docs/apd/spec-*-patch-*.md` or `decision-*.md` files are present
- **2.x → 3.x (terms, commands, and hooks overhaul)**: the document structure is current, but CLAUDE.md, document bodies, or rules still contain pre-3.x wording. Specifically:
  - "Acceptance", "Human Checkpoint" → **post-completion hands-on check**
  - `/apd:build` / `/apd:start` → `/apd:go`; `/apd:cycle` / `/apd:progress` are removed (conversation + `gh`)
  - `apd:peer-review` / `apd:checkpoint` agents → removed
  - **Spec-check Stop hook** (3.0–3.1) → removed. The AI checks ACs against the Build's completion condition
  - **State-suggestion hook** (3.1) → removed. Guidance comes from the main AI's always-loaded rule (`07-next-step.md`) + `/apd:status`

## Responsibilities

- Read the existing `docs/apd/`, `CLAUDE.md`, and `.claude/rules/apd/` to understand the current state
- Draw up a migration plan to the current model and get the user's confirmation
- Take a backup, then run the migration
- **Remove APD-originated injections, duplication, and stale content from CLAUDE.md** (keep project-specific content)
- **Update `.claude/rules/apd/` to the latest version**
- **Explicitly list as manual review items** anything that cannot be converted mechanically
- After completion, run `scripts/verify-migration.sh` to verify

## Procedure

### 1. Preconditions

- The git working tree is clean (or on a dedicated branch). If not clean, do not run; prompt the user to commit/stash/use a separate branch
- `docs/apd/` or `.claude/rules/apd/` exists (it is an APD project)
- If it is **fully on the current model** (`docs/apd/` is flat with the 3 file types, no Patch/per-file Decision/old subdirectories, no APD-originated injection/stale content in CLAUDE.md, rules match the latest version), return "already migrated" and stop. **Idempotent**: skip items that are already in line

### 2. Assess the current state

Use Glob + Read + Bash to identify:

- **docs/apd/**: old subdirectories, `spec-*-patch-*.md`, `decision-*.md` / `D-*.md`, `preview-*/`, files outside the naming convention
- **CLAUDE.md**: list APD-originated content (grep for the targets listed in "Cleaning CLAUDE.md" below)
- **.claude/rules/apd/**: check the diff against the plugin's bundled rules (`${CLAUDE_PLUGIN_ROOT}/rules/apd/`) with `diff`. Tell whether a diff is a "version difference" or a "project-specific customization"

### 3. Present the migration plan and confirm

List what will change and how (docs / CLAUDE.md / rules), plus what goes to manual review, and get agreement. If the `--dry-run` argument is given, output only the plan and "what would happen if run" (no fs operations).

### 4. Execute

After the user agrees, run the steps in order with Bash + Edit. After each step, surface **what was done** in the conversation.

1. **Backup**: `cp -R docs/apd docs/apd.backup-{timestamp}`, `cp CLAUDE.md CLAUDE.md.apd-backup-{timestamp}` (never delete these; a dedicated branch, if any, is extra insurance)
2. **Flatten subdirectories** (for 0.x): move files with `git mv`
3. **Fold Patches**: Read each patch → Edit the relevant ACs of the parent Spec to integrate it + increment `version` → `git rm` the patch (do not mechanically append to the end)
4. **Consolidate Decisions**: Read each `decision-*.md` → append to `decisions.md` in descending number order → `git rm` the original
5. **Update frontmatter**: `cycle_ref` → `issue_ref`; `amendment_id` / `patch_id` are removed by folding
6. **Clean CLAUDE.md** (below)
7. **Update rules** (below)

#### Cleaning CLAUDE.md (removing APD-originated injection, duplication, and stale content)

Remove generic APD rules from CLAUDE.md and **always keep project-specific content** (tech stack, naming conventions, test runner, CI, distribution, security, project state, etc.). Judge each section and line: "generic APD rule or project-specific?"

Targets to remove or fix (legacy projects contain these in Japanese; match the Japanese literals as quoted):

- **Banner line**: APD usage declarations or lines containing a version, such as 「**APD（Autopilot Development）フレームワーク x.y.z …で開発。詳細ルール: `.claude/rules/apd/`**」 ("Developed with the APD (Autopilot Development) framework x.y.z … Detailed rules: …") → **delete**
- **Copies of generic rules**: sections duplicating the contents of `.claude/rules/apd/` in CLAUDE.md → **delete**. Typical: 「APD 準拠ルール」 (APD compliance rules), 「並列実行・Git 戦略（…準拠）」 (parallel execution / Git strategy (… compliant)), the generic parts of the testing policy, 「Build の収束判定」 (Build convergence check), general rules on referencing Decisions, general rules on living documents. If there are project-specific parts (test runner, areas where mocks are forbidden, custom branching rules, etc.), keep only those
- **Stale content**:
  - Mentions of the 「**Spec チェック Stop フック**」 (Spec-check Stop hook) → removed. Rewrite as "the AI checks ACs against the Build's completion condition" or delete
  - The two-list 「**Build 中のエスカレーションポリシー**」 (escalation policy during Build) (人間に渡す (hand to the human) / Build 内で完結 (resolve within Build)) → old model. Delete (current model: "zero intervention during implementation; the post-completion hands-on check feeds the next cycle")
  - Mentions of the state-suggestion hook (状態サジェストフック) → delete (always-loaded rule + `/apd:status`)
- **Old command and agent names**: `/apd:build` `/apd:start` `/apd:cycle` `/apd:progress` `apd:checkpoint` `apd:peer-review` → rewrite to current ones (`/apd:go` etc.) or delete
- **Old terms**: "Acceptance", "Human Checkpoint" → "post-completion hands-on check"

Do not delete sections you are unsure about; make them **manual review items**.

#### Updating rules

Update `.claude/rules/apd/*.md` to the latest version bundled with the plugin. Always check the diff before overwriting; if there are project-specific customizations, make them manual review items:

```bash
# Check the diff (version difference only, or local customizations?)
for f in "${CLAUDE_PLUGIN_ROOT}/rules/apd/"*.md; do
  diff -q ".claude/rules/apd/$(basename "$f")" "$f" 2>/dev/null
done
# If there are no local customizations, overwrite with the latest version
mkdir -p .claude/rules/apd
cp "${CLAUDE_PLUGIN_ROOT}/rules/apd/"*.md .claude/rules/apd/
```

### 5. Verify

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/verify-migration.sh"
```

Fix any FAIL.

### 6. Report

````markdown
## Migration complete

### docs/apd/
- Patches folded (N) / Decisions consolidated (N) / flattened (N) / frontmatter updated (N)

### CLAUDE.md cleanup
- Deleted: banner line / generic rule sections (…) / stale content (Stop hook, escalation two-list, etc.)
- Rewritten: old command names, old terms
- Kept: project-specific (tech stack, test runner, distribution, security, etc.)

### .claude/rules/apd/
- Updated N files to the latest version (local customizations: none / sent to manual review)

### Manual review needed (N)
- ...

### Backup
- docs/apd.backup-{timestamp}/ · CLAUDE.md.apd-backup-{timestamp}

### Next steps
1. Handle the manual review items
2. git add -A && git commit -m "chore: migrate to current APD model"
3. After confirming everything works, delete the backup in a separate PR
````

## What this skill intentionally does not do

- Update paths in project-specific `src/` `tests/` — make them manual review items
- Modify project-specific content in CLAUDE.md — only APD-originated generic rules, injections, and stale content are targeted

## Rollback

```bash
rm -rf docs/apd && mv docs/apd.backup-{timestamp} docs/apd
mv CLAUDE.md.apd-backup-{timestamp} CLAUDE.md
git checkout -- .claude/rules/apd/
```
