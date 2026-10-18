# APD Migration Guide

Steps to migrate an existing APD project to the current model. Whether you are on 0.x (subdirectory structure), 1.0.x (flat + Patch files) or 2.x (old terminology/commands/hooks), the same `/apd:migrate` brings it to the current model. The migration covers not only the structure of `docs/apd/` but also **CLAUDE.md and `.claude/rules/apd/`**.

Key points of the current model:
- Each document is a single living document (do not stack diffs in separate files; git is the source of truth)
- 3 kinds of files: `design.md` / `decisions.md` / `spec-{feature}.md`
- Patch files abolished → folded into the parent Spec. Decisions consolidated into a single `decisions.md`. Previews are optional
- Where the human checks is GitHub (PR + issue)
- Terminology, commands and hooks are 3.x: **hands-on check after completion** / `/apd:go` / the plugin has no Stop or SessionStart hooks
- **CLAUDE.md holds only project-specific content**. The canonical source of generic APD rules is consolidated in `.claude/rules/apd/` (auto-loaded)
- Build runs in auto mode (made a convention in 3.5.0). From 3.6.0 the default is to implement on the spot once approved, and `/goal` became an optional means for long unattended runs
- 3.6.0 added the Plan classification (`/apd:plan`) and a SessionStart hook that injects the design classification. Run `/apd:migrate` to bring `.claude/rules/apd/` up to date

## Approach

**Migrate with the AI-driven `/apd:migrate` skill**. Rather than bulk replacement by script, the AI reads each file and converts it with its context in mind. Verification is done with `scripts/verify-migration.sh`.

Reasons:
- Folding Patch files requires understanding the content (read which AC each diff corresponds to and merge it)
- Converting frontmatter fields requires interpreting the meaning of values (`cycle_ref: "C-001"` → `issue_ref: <number or null>` requires checking the actual issue)
- Replacing path references in the body is context-dependent (is it a link or a historical mention?)
- Handling files that do not match the naming convention requires judgement
- Updating CLAUDE.md is project-specific

## Main changes

| Item | Old (0.x / 1.0.x) | New (living documents) |
|------|---------|---------|
| Directory | `docs/apd/{design,specs,decisions,cycles,previews}/` (0.x) | `docs/apd/` flat, 3 kinds only |
| Design | `docs/apd/design/product-design.md` | `docs/apd/design.md` |
| Spec | `docs/apd/specs/{name}.v{N}.md` | `docs/apd/spec-{feature}.md` |
| Spec changes | Stack Amendment / Patch in separate files | **Edit the existing Spec directly** (bump `version`). History is in git |
| Decision | `decisions/D-{NNN}.md` (0.x) / `decision-{NNN}.md` (1.0.x) | `docs/apd/decisions.md` (single append-only log) |
| Preview | Required in principle | **Optional**. Only if created: `docs/apd/preview-{feature}/` |
| Cycle | `docs/apd/cycles/C-{NNN}.md` | **Abolished** (replaced by GitHub issues) |
| Build skill | `/apd:build` / `/apd:start` | `/apd:go <spec>` (default is Build on the spot; `/goal` is optional) |
| Starting a cycle | `/apd:cycle` | Conversation + `gh issue create` |
| Progress check | `/apd:progress` | `/apd:status` + `gh issue list` + `ls docs/apd/` |
| Mechanical verification agents | `apd:checkpoint` / `apd:peer-review` | **Abolished** (`/goal` evaluator + Build's Spec check step) |
| Spec check | Stop hook (3.0–3.1) | **Build's completion condition** (the build AI checks the AC) |
| Next-command guidance | State-suggestion hook (3.1) | Always-loaded rule `07-next-step.md` + `/apd:status` |
| Handoff | Cycle definition file | "## How to try it" section of the PR body |
| Backlog | `docs/apd/todo.md` | The project's issue tracker (e.g. GitHub issues) / `todo.md` (if there is none) |
| Where the human checks | Scan docs/apd/ | **GitHub (PR + issue)**. docs/apd/ is the AI's workspace |
| Terminology | "Amendment" / "Acceptance" / "Human Checkpoint" | (abolished) / **hands-on check after completion** |
| CLAUDE.md | Generic APD rules copied verbatim, promotional line | **Project-specific only**. Generic rules live in `.claude/rules/apd/` |

## Migration steps

### 1. Update the plugin

```bash
/plugin update apd@apd-marketplace
```

### 2. Create a branch in the project

```bash
cd /path/to/your/project
git checkout -b chore/apd-3.x-migration
```

If there are uncommitted changes, commit or stash them first.

### 3. Start the AI-driven migration

In Claude Code:

```
/apd:migrate
```

The AI does the following:

1. Reads `docs/apd/`, `CLAUDE.md` and `.claude/rules/apd/` to understand the current state
2. **Presents a migration plan** (file moves, frontmatter / body rewrites, APD-derived content to remove from CLAUDE.md, rules updates, places that need manual review)
3. Executes once the user replies yes
4. Backup (docs/apd/ and CLAUDE.md) → file moves → frontmatter updates → body reference updates → **CLAUDE.md cleanup** (removes promotional lines, verbatim copies of generic rules, outdated content and old command names; keeps project-specific content) → **updates `.claude/rules/apd/` to the latest version**
5. Calls `scripts/verify-migration.sh` to verify the result
6. Outputs a report (what was done, remaining manual review items)

Starting it with the **`--dry-run` argument** only presents the plan and dry-run output, with no filesystem operations.

### 4. Verify

It is also called inside `/apd:migrate`, but you can rerun it manually:

```bash
bash <path-to-apd-plugin>/scripts/verify-migration.sh
```

Checks:
- Old subdirectories (`design/`, `specs/`, `decisions/`, `cycles/`, `previews/`) are gone
- No old naming (`*.A-*.md`, `*.v{N}.md`) remains
- **No Patch files (`spec-*-patch-*.md`) remain** (folded into the parent Spec)
- **No per-file Decisions (`D-*.md` / `decision-*.md`) remain** (consolidated into `decisions.md`)
- No old frontmatter fields (`amendment_id:`, `patch_id:`, `cycle_ref:`) remain
- No references to old subdirectory paths in `docs/apd/` or CLAUDE.md
- **APD cruft in CLAUDE.md**: no promotional line (`APD … フレームワーク x.y.z … で開発` — "developed with APD framework x.y.z"), no references to the removed 「Spec チェック Stop フック」 ("Spec check Stop hook"), no old 「エスカレーションポリシー」 ("escalation policy") two-list, no old commands/agents (`/apd:build|start|cycle|progress`, `apd:peer-review|checkpoint`)
- **Freshness of `.claude/rules/apd/`**: it exists, has no outdated wording such as `Stop フック` ("Stop hook"), and (when `CLAUDE_PLUGIN_ROOT` is set) matches the rules of the installed plugin

Shows PASS / FAIL, and exits 1 if anything FAILs.

### 5. Update the rule files (`.claude/rules/apd/`)

`/apd:migrate` updates them to the latest version (it checks the diff before overwriting and routes any custom changes to manual review). If you align them manually without migrate, `/apd:init` also overwrites `.claude/rules/apd/*.md` with the latest version.

### 6. Handle the remaining manual review items

Work through the items reported as "manual review" in the `/apd:migrate` report, in order. Typical ones:

- Files that did not match the naming convention (`random.md` etc.): decide their purpose and place them under a new name, or delete them
- Specs at old versions: recover them from the backup, or leave them only in the backup
- Sections of CLAUDE.md where it was unclear whether they are "generic APD rules or project-specific" (deletion deferred by migrate)
- Files in `.claude/rules/apd/` that had custom changes (overwrite with the latest version, or keep the customizations)

### 7. Check that it works

```bash
ls docs/apd/
# Expected: design.md, decisions.md, spec-*.md, preview-*/ (optional), todo.md (if not using gh)
```

Run a cycle through the new flow:

```
# In Claude Code (to check it works; does not need to be a real cycle)
/apd:status   # Does it show where you are and the next step?
/apd:spec     # Can existing Specs be read in the new format?
/apd:go spec-{slug}.md  # Is a /goal condition assembled?
```

### 8. Commit

```bash
git add -A
git commit -m "chore: migrate to current APD model"
```

It is safest to keep the backup directory (`docs/apd.backup-{timestamp}/`) in the commit, and delete it in a separate PR once a few cycles have run without problems.

## Rollback

If there is a problem, you can restore from the backup:

```bash
rm -rf docs/apd
mv docs/apd.backup-{timestamp} docs/apd
mv CLAUDE.md.apd-backup-{timestamp} CLAUDE.md   # if CLAUDE.md was cleaned up
git checkout -- .claude/rules/apd/ .  # if rules updates or edits are staged
```

Or roll back by re-adding the marketplace pinned to an old version's tag. `/plugin install` has no version option; pin the ref by appending `#<ref>` to the git URL:

```
/plugin marketplace remove apd-marketplace
/plugin marketplace add https://github.com/koyakimu/apd-framework.git#v2.0.0
/plugin install apd@apd-marketplace
```

`remove` uninstalls the plugins that came from that marketplace, which is fine for a rollback. CI automatically adds release tags in v{version} format to APD, so you can specify the tag of the version you want to go back to as is. Note that the added marketplace stays pinned to the specified ref, so in this state running `/plugin update` will not move to the latest version. To return to the latest, follow the same steps: `/plugin marketplace remove apd-marketplace`, then re-add it without a ref with `/plugin marketplace add koyakimu/apd-framework`.

## Troubleshooting

### `/apd:migrate` returns "already migrated"

If `docs/apd/design.md` exists and the `docs/apd/design/` directory does not, the AI judges that it is already migrated. If this is a false positive, handle it manually, or explain the situation to the AI and instruct a partial migration.

### The verification script returns FAIL

Look at the output of `scripts/verify-migration.sh` and identify the FAIL items. Common cases:

- **`docs/apd/specs/` still exists**: unrecognized files (random.md etc.) remain. Check their contents and place them under a new name, or delete them
- **Patch files remain**: folding into the parent Spec was missed. Rerun `/apd:migrate`, or merge the content into the Spec manually and then delete the patch file
- **`amendment_id:` / `patch_id:` frontmatter remains**: the AI missed a conversion. Fix it manually with Edit, or rerun `/apd:migrate`
- **Old path references remain in the body**: open the file, check it, and replace or leave it based on context

### Recovering a specific file from the backup

For important decisions from past cycles, read the backup contents (e.g. `docs/apd.backup-{timestamp}/cycles/C-001.md`) and recover them by appending them to `docs/apd/decisions.md` as a `## D-{NNN}: ...` section. Creating per-file `decision-*.md` files causes Check 2 of `verify-migration.sh` to FAIL, so consolidate into the single `decisions.md`.

## Division of responsibility between related tools

| Tool | What it does | What it does not do |
|--------|---------|-----------|
| `/apd:migrate` (skill) | Performs the actual migration (file moves, renames, frontmatter updates, body replacements) using AI judgement | Leaves verification to the external script |
| `scripts/verify-migration.sh` | Mechanically checks that the new structure holds | Rewrites nothing |

## Questions

If you hit an unexpected case with the scripts or migration, please open a GitHub issue: https://github.com/koyakimu/apd-framework/issues
