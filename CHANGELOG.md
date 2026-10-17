# Changelog

## [3.8.0] - 2026-10-18

### Changed — Backlog is no longer limited to GitHub issues

- **The backlog is the project's issue tracker, whichever it is**: decided in the order CLAUDE.md → what the user says → GitHub issues (if `origin` is on GitHub and `gh` is installed); `docs/apd/todo.md` when there is none. Other trackers (GitLab, Linear, Jira, etc.) are used through whatever tool or connector is available. The canonical rule is the new "Backlog (issue tracker)" section in `rules/apd/03-documents.md`
- **`/apd:init` no longer runs `gh auth status`**: credentials are not read to decide the backlog. If a tracker command fails (e.g. not signed in), Claude says so and appends to `todo.md` instead
- Wording that assumed GitHub issues ("GitHub issue number", "human review surface = GitHub") now says the project's tracker / PRs and issues, in the rules, skills (design / spec / status / migrate / init), the Spec template's `issue_ref`, the READMEs and the reference docs

### Changed — Prepare for the official plugin directory

- **Added a listing icon** at `.claude-plugin/icon.png` (1024×1024 PNG): three forward chevrons, the first in amber for the human's decision and the rest for the AI running on its own
- **Added `displayName`** ("APD — Autopilot Development") to `plugin.json`, so the listing is not shown under the bare name `apd`. `name` stays `apd`, so installs and `/apd:*` commands are unchanged
- **Moved this repository's development rules from `CLAUDE.md` to `.claude/CLAUDE.md`**: a `CLAUDE.md` at the plugin root is not loaded for plugin users and triggered a validation warning. Claude Code still loads it when working on this repository

## [3.7.0] - 2026-10-17

### Changed — Write the plugin in English and state that it works in the language of the person giving instructions

- **Translated the skills, rules, templates, SessionStart hook and reference docs (QUICKREF / APD-FRAMEWORK / MIGRATION) into English**: for English-speaking users, such as those coming from the official plugin directory. Structure, IDs, frontmatter and commands are unchanged. Skill descriptions were already in English, and the Japanese trigger examples are kept. In migrate and MIGRATION, the literals used to match Japanese text in legacy projects remain in Japanese (they correspond to the detection in `scripts/verify-migration.sh`)
- **Added a language rule**: converse in the language the person giving instructions is using, and write `docs/apd/` documents, Plans, PR bodies (including "How to try it") and issues in that language. Template section names (which skills reference by name), structure, IDs, and frontmatter keys and structural values are kept; body text, placeholders and the descriptive part of headings are written in that language. Existing files outside `docs/apd/`, such as CLAUDE.md, follow that file's language (as do migrate's replacement texts). The source of truth is Language in `rules/apd/00-principles.md`; it is also placed in `hooks/session-start.md` so it applies in uninitialized repositories, and is referenced from the skills that write documents (design / spec / plan / go / init). The body of the `todo.md` that init copies is written in the user's language
- **Made `README.md` English and moved the Japanese version to `README.ja.md`** (cross-linked). Added a language section to both
- **Made the descriptions in `plugin.json` / `marketplace.json` English**. Added `homepage` to `plugin.json`, and added `spec-driven` / `workflow` / `claude-code` to keywords
- **Translated this CHANGELOG into English**, including past entries
- Terminology: 「試し方」 is now "How to try it", 「完成後の実機確認」 is now "post-completion hands-on check", 「区分」 is now "classification", and 「達成条件」 is now "completion condition"

## [3.6.2] - 2026-10-03

### Changed — Align skills with the official best practices

Checked against the official Skill authoring best practices and the Claude Code skills doc (original text).

- **Put important instructions first**: after compaction only the first 5,000 tokens of each skill remain, so each skill now has an "Always" section, to which items such as "don't write code until approval" and "Build right away after approval" were moved. In spec, the handoff to Build was at the end, a position that could be cut off in long conversations. migrate moved its safety principles to the top
- **Split go**: content specific to `/goal` (how to pass the condition, the evaluator's verdict, what to do when it doesn't work) moved to `skills/go/goal.md`, read only when `/goal` is chosen. Content unused by the default "Build right away" stayed in context every turn once invoked. Set the default for parallelization to subagents
- **Removed prompts asking the user to type a command**: design's "Proceed with `/apd:spec`" and init's "Create with `/apd:design`" now continue straight to the next step. When called from Spec / Design, init returns to the original flow
- **Removed explanations of reasons, leaving only instructions** (design / spec / init / migrate). Also removed the "read `CLAUDE.md`" instruction
- **status**: removed mentions of hooks retired in 3.1.0 and added Plan to the decision table. Unified the notation to "Build"
- **migrate**: with `disable-model-invocation: true` the description does not enter Claude's context, so the model-facing trigger condition ("use right after a plugin update") was removed

## [3.6.1] - 2026-10-03

### Added — Evaluation scenarios (#44)

- **Added 6 `claude plugin eval` cases in `evals/`**: they check, in two arms (with and without APD), whether work starts from design (`new-feature` / `devtool-plan` / `test-infra-plan`), whether implementation happens right away after approval (`approved-build`), and whether it avoids interrupting typos or questions (`typo` / `question`). Grading centers on the number of Edit / Write calls, file presence and a regex on the final message; only the design content is LLM-graded. How to run is in the README's "Evaluation scenarios"
- `approved-build` includes the approved Plan in the prompt instead of using conversation history (`history_file`). A history transcript could contain the author's CLAUDE.md and the like, so it is not kept in the public repository
- Fixtures use `evals/_fixture/fixture.sh` as the source of truth and are copied to each case by `scripts/sync-eval-fixtures.sh` (because `scaffold_script` must live in the case directory). CI checks the copies for drift

## [3.6.0] - 2026-10-03

### Added — Start from design just by asking

- **Added the Plan classification and `/apd:plan`**: a lightweight design for changes that don't warrant a Spec (refactors with no behavior change, internal technical changes, dev tooling, infra, config, scripts, multi-file fixes). It presents Goal / Files to change and approach / Alternatives considered / Verification in the conversation, enters Build once approved, and puts the same design at the top of the PR body. It creates no files, so it works in repositories without `/apd:init`. Replaces the former row "technical change → append to `decisions.md` → Build"
- **Reintroduced the SessionStart hook**: puts the classification table in `hooks/session-start.md` (Design / Spec / Plan / No design) and "don't write code until approval; don't stop after approval" into context on startup / clear / compact. The hooks removed in 3.1.0 / 3.2.0 made decisions or launched agents on every Stop; this one is a single `cat` line with no logic. SessionStart cannot block the session, and on failure it only shows an error and continues. CI also checks `hooks/hooks.json` for JSON validity

### Changed

- **Rewrote skill descriptions so the model selects them on its own**: `spec` / `design` / `plan` are used not only "when the user asks" but also "when asked for a new feature, a behavior change or a new product and no design covering it exists yet (even if not asked)". Previously only `go` triggered, on "start implementation", leaving open only the path into implementation without a Spec
- **Added an entry check to `/apd:go`**: if there is neither a Spec nor an approved Plan covering the target, it does not enter Build and routes to `apd:spec` / `apd:plan`
- **Changed the Build default to "implement right away on approval"**: with just an approval reply ("implement it this way", etc.), the AI turns the completion conditions into a checklist and proceeds through implementation, tests and PR. Having the user paste a condition into `/goal` is now an optional method for long unattended runs. The content of the completion conditions (including the Spec check) is unchanged
- **Added an exception to "don't push (the next step) on the user" in `rules/apd/07-next-step.md`**: an implementation request without a design is not "a choice to skip design", so instead of just giving guidance, start by creating a Spec or Plan. Excludes cases where the user explicitly says to skip it and the "No design" classification
- **Made `/apd:init` callable by the model too**: removed `disable-model-invocation: true`. It runs only when the user agrees to a suggestion to initialize (the description states it does not run without agreement)
- **Prefixed references to `templates/decision.md` with `${CLAUDE_PLUGIN_ROOT}`** (`spec` / `plan`): the old wording could be read as a relative path in the consuming repository
- Unified the term as "completion condition" (so "condition" and "done condition" are not mixed in the body of `go`)

## [3.5.0] - 2026-09-05

### Changed — Make auto mode a convention for Build

- **Made "Build runs `/goal` in auto mode" a convention**: 3.4.0 only presented the fact that "`/goal` does not change the permission mode", but since this is the very precondition for APD's core claim of "zero human intervention during Build", we decided to make it a convention rather than an option. `/goal` handles turn continuation and auto mode handles tool-call permission; only with both is intervention during implementation zero. Switching to auto mode is done with Shift+Tab, `--permission-mode auto` at launch, or `permissions.defaultMode` in user settings (or **Yes, and switch to auto mode** on a Bash permission prompt), but `auto` has no effect in project settings (`.claude/settings.json`), and the only `settings.json` keys a plugin can bundle are `agent` and `subagentStatusLine`, so **APD cannot enforce it**. It is therefore ensured by having the guidance in `/apd:go` and `/apd:spec` prompt the human to check. Updated `rules/apd/01-phases.md` (phase diagram and "don't stop during Build"), `rules/apd/00-principles.md` (zero-intervention principle), `skills/go/SKILL.md` (presentation step), `skills/spec/SKILL.md` (post-approval guidance), `QUICKREF.md` (Build flow), `APD-FRAMEWORK.md` (design rationale, feature table, Build behavior), `README.md` and `MIGRATION.md`
- **Documented where auto mode still stops**: if the classifier blocks 3 times in a row or 20 times in total, auto mode pauses and returns to normal permission prompts (thresholds cannot be changed); operations matching `permissions.ask` always ask; the first read outside the working directory asks. `rules/apd/01-phases.md` and `APD-FRAMEWORK.md` state the policy of treating these as "places where stopping is expected" and not trying to avoid them through condition wording. Also added "stops on permission prompts during Build → `/goal` was pasted while still in Manual mode" to "Failure clues" in `skills/go/SKILL.md` (the official goal clear conditions are Met / Impossible / unrecoverable error / `/goal clear` / `/clear`, and switching permission mode is not among them, so just switching with Shift+Tab is enough and re-pasting is unnecessary)
- **Added an auto mode section and two deferral decisions to the research note**: added §7 "auto mode requirements and remaining stop points" to `docs/research/claude-code-refresh-2026-09-04.md`, recording the default permission mode, plan/organization/model availability conditions, ways to enable it, remaining stop points, behavior with `-p`, and application to subagents, together with the original text of the official docs. Added to §6 the decisions to defer "bundling parallel Build as a dynamic workflow" (the `/goal` evaluator can't be used, so convergence checking would have to be reimplemented, and intermediate results don't appear in the conversation, so the verification model doesn't hold) and "adding `claude plugin validate --strict` to CI" (it fails on a warning about the CLAUDE.md at the plugin root, and adds little on top of existing CI)

## [3.4.0] - 2026-09-04

### Changed — Update spec descriptions for Claude Code 2.1.260

- **Documented that `/goal` does not change the permission mode**: APD's headline "zero human intervention during Build" does not hold with `/goal` alone; it presupposes combining it with auto mode. `/goal` only automates turn continuation; tool-call permission remains the responsibility of the permission mode, and in Manual mode a human confirmation is required for every unpermitted tool call. Added to the presentation step in `skills/go/SKILL.md`, "don't stop during Build" in `rules/apd/01-phases.md`, the post-approval guidance in `skills/spec/SKILL.md`, the flow in `QUICKREF.md`, and the feature table in `APD-FRAMEWORK.md`
- **Corrected `/goal` evaluation timing from "after every turn" to the actual spec**: if a turn ends while a subagent or background shell is still running, evaluation for that turn is skipped and the verdict happens at the end of the next turn with no background work. APD recommends subagents for parallelizing Build, so this is hit routinely, and without knowing it one misdiagnoses "the evaluator isn't running" and starts tweaking the condition. Also noted that an automatic check-in occurs when waiting on background work exceeds 30 minutes (30 min → 1h → then every 2h, capped at 4x the initial interval; only the interactive session's idle check-in has a count limit, at most 3 per goal between user prompts)
- **Added automatic goal clearing on unrecoverable errors to `/apd:go`**: if a turn fails due to authentication failure, running out of credits, context overflow that auto-compaction cannot resolve, or model unavailability, `/goal` is cleared automatically. The user is now advised to keep the condition text at hand so it can be re-pasted after recovery (the goal is kept on transient errors such as rate limits)
- **Added checks for when `/goal` is unavailable**: the evaluator sits on top of the hooks mechanism, so availability depends not only on the Claude Code version but also on workspace trust, `disableAllHooks`, and `allowManagedHooksOnly` in managed settings
- **Added loop stopping without progress to failure clues in `/apd:go`**: when several turns in a row use no tools, Claude Code stops the loop and shows a warning. The goal stays set and control returns to the user; evaluation resumes on the next prompt, so there is no need to re-paste the goal
- **Documented availability conditions for Task tools**: since Claude Code 2.1.233, Task tools such as `TaskCreate` (TaskCreate/Get/Update/List, TodoWrite) are not provided by default on Opus 4.8 / Sonnet 5 / Fable 5 / Mythos 5 and later models (restorable with `CLAUDE_CODE_ENABLE_TODO_TOOLS=1`), and the model tracks multi-step work itself. The instruction "use `TaskCreate` for in-session todos" was a no-op on current models (`QUICKREF.md` / `APD-FRAMEWORK.md` / `rules/apd/00-principles.md`)
- **Added dynamic workflows to the parallelization options**: the official docs organize them into four (subagents / agent view / agent teams / dynamic workflows), while APD's list still had three. Also noted, as decision material, "where human intervention occurs" for each — agent teams are disabled by default (requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) and teammates' permission prompts appear in the leader session; `/batch` stops once after decomposition to ask for plan approval; dynamic workflows accept no user input during a run, and only agents' permission prompts can stop a run (to run unattended, pre-permit with auto mode or allow rules)
- **Added checks for pre-3.4.0 rule wording to `scripts/verify-migration.sh`**: FAIL if 「毎ターン後」 ("after every turn") or `TaskCreate` remain in `.claude/rules/apd/` (same approach as the 3.2.0 Stop hook check; update to the latest with `/apd:migrate` or `/apd:init`)
- **Added a research note**: `docs/research/claude-code-refresh-2026-09-04.md` — results of checking 2.1.218 → 2.1.260, a snapshot of the current spec, and ideas considered but not adopted, with reasons

### Fixed

- **Made the rollback procedure in `MIGRATION.md` executable**: `/plugin install apd@apd-marketplace --version 2.0.0` used a nonexistent option and could not run. `/plugin install` has no version option; the correct approach is to pin a ref by appending `#<ref>` to the marketplace git URL. APD's past releases (v0.1.0 onward) also have `v{version}` tags (applied retroactively in 3.3.1, and added automatically by CI since), so you can specify the tag of the version you want to roll back to directly
- **Added an archive note to `docs/research/contract-abolishment-2026-03-15.md`**: it was the only archived document under `docs/` without a note (the other 3 got one in 3.3.1), and its body, written with Phase numbers that no longer exist, could be misread as the current spec

## [3.3.2] - 2026-07-05

### Changed — Rename the repository to match what it is

- **Renamed the repository from `autopilot-development-boilerplate` to `apd-framework`**: it is not actually a boilerplate (a template to copy) but a framework distributed as a Claude Code plugin. GitHub redirects from the old name, so existing installs, `git clone` and `/plugin update` keep working
- Updated `repository` in `plugin.json`, `homepage` in `marketplace.json`, the install command in the README, and the issue URL in MIGRATION.md to the new name
- New marketplace add command: `/plugin marketplace add koyakimu/apd-framework`

## [3.3.1] - 2026-07-05

### Fixed — Batch fix of inconsistencies found in a repository audit

- **Updated bundled templates to the current frontmatter model**: removed v2 `cycle_ref` / `created_at` left in `templates/spec.md` / `design.md` / `cross-context-scenarios.md` and unified on the `issue_ref` model. Previously a Spec created from the template was judged "not migrated" (FAIL) by `verify-migration.sh`, a self-contradiction
- **Fixed old phase notation in `templates/todo.md`**: `Phase 0/1/2` → the current `Intent / Spec / Build`
- **Unified cross-context file naming**: changed the file created by `/apd:spec` from `spec-cross-context.md` to `cross-context-scenarios.md` (matching the template name and removing confusion with build-target Specs via the `spec-*.md` glob). Documented it as an optional file in `rules/apd/03-documents.md`
- **Unified the decisions.md format across three places**: the format (with or without Options / AI Recommendation) and append order (settled on "newer decisions on top"), which differed among `rules/apd/03-documents.md` / `templates/decision.md` / `skills/spec/SKILL.md`, were unified with `templates/decision.md` as the source of truth
- **Removed v2 leftovers from `skills/spec/SKILL.md`**: deleted the instruction to read the retired "escalation policy" from CLAUDE.md
- **Hardened `scripts/bump-version.sh`**: added execute permission (running via `./` gave permission denied), added an error message for non-semver versions, and fixed a silent no-op when the plugin is not found in marketplace.json
- **Fixed a grep bug in `scripts/verify-migration.sh`**: changed the bracket expression `[^\n]` (which in POSIX means "anything but n and \") to `.`
- **Fixed stale content in `MIGRATION.md`**: `decision-*.md` → `decisions.md` in the expected file list; updated the rollback example from `--version 0.5.1` to `2.0.0` (to match the most recent old version for the 3.x migration guide); changed the backup recovery steps to append to decisions.md so they don't create per-file Decisions that FAIL verify; updated example branch names to 3.x
- **Added archive notes to historical documents**: added a note "implementation complete; the source of truth for the current spec is rules/apd and skills" to `docs/apd-v3-redesign.md` / `docs/apd-v3-implementation-plan.md` / `docs/research/harness-engineering-2026-04-29.md` (to prevent misreading dangling references to nonexistent hooks, etc.)
- **Deleted `examples/templates/`**: it was an old, unreferenced copy of `templates/` (missing the NFR section)
- **Added the `migrate` skill to the structure table in `README.md`** (it was inconsistent with the skill table in the same README)
- **Added `.serena/` to `.gitignore`**
- **Added CI**: `.github/workflows/ci.yml` — checks on every PR for JSON validity, version match across three places (plugin.json / marketplace.json / CHANGELOG), SKILL.md frontmatter, old frontmatter in templates, shellcheck, and script execute permissions
- **Started release tagging**: after merging to main, CI automatically adds a `v{version}` tag from the version in plugin.json (`tag-release` job). Tags were also added retroactively to past releases v0.1.0–v3.3.0

## [3.3.0] - 2026-06-29

### Changed — Complete the migration (CLAUDE.md cleanup, rules refresh, 3.x overhaul)

- **`/apd:migrate` now cleans up CLAUDE.md**: removes APD-originated injections as a first-class step. It targets promotional lines (`APD … フレームワーク x.y.z … で開発` ("developed with the APD … framework x.y.z …")), sections copied verbatim from `.claude/rules/apd/`, stale content (references to the retired 「Spec チェック Stop フック」 (Spec check Stop hook) and the old two-part escalation list), old command/agent names (`/apd:build|start|cycle|progress`, `apd:peer-review|checkpoint`), and old terms (Acceptance/Human Checkpoint), tidying up **while keeping project-specific content**
- **`/apd:migrate` now updates `.claude/rules/apd/` to the latest version**: after reviewing the diff, updates to the version bundled with the plugin (custom changes go to manual review). Previously delegated as "the responsibility of `/apd:init`"; now integrated into migrate
- **Added the 2.x → 3.x migration pattern**: the overhaul of terms, commands and hooks (retirement of the Stop hook/suggest hook, `/apd:go`, post-completion hands-on check) is now explicitly a migration target. Migration is idempotent
- **Extended `scripts/verify-migration.sh`**: checks CLAUDE.md for APD residue (promotional lines, Stop hook references, old escalation, old commands) and `.claude/rules/apd/` for freshness (stale content, diff from the plugin)
- **Prevented re-injection**: added a guard "APD does not rewrite the user's CLAUDE.md" to `/apd:init` and `rules/apd/00-principles.md`
- Updated `MIGRATION.md` for 3.x (CLAUDE.md cleanup, rules refresh, new commands/terms)

## [3.2.0] - 2026-06-28

### Changed — Move the Spec check from a Stop hook to a Build step

- **Retired the `type:agent` Stop hook for the Spec check**: it launched a full AI agent on every Stop, so even ordinary turn endings incurred waits of tens of seconds or more each time, and at worst around 10 minutes (with block & retry). Deleted `hooks/hooks.json`; the apd plugin no longer has any Stop / SessionStart hooks
- **Integrated the Spec check into the Build completion conditions**: the `/goal` condition assembled by `/apd:go` now includes "the build AI itself checks each AC against the Spec and Design, surfaces OK/drift/not implemented with evidence, and fixes drift autonomously before completing". The check runs only during Build, when it is needed, and the per-Stop launch cost is zero
- Rewrote `rules/apd/01-phases.md` / `02-cycle-flow.md` / `skills/go/SKILL.md` from "Stop hook gatekeeper" to "Build step"
- Annotated the policy change in §6/§8 of `docs/apd-v3-redesign.md`
- Trade-off: the purity of "a separate process that doesn't rely on self-reporting" drops, but the per-Stop slowness is gone

## [3.1.0] - 2026-06-28

### Changed — Next-step guidance moves from "mechanical suggestions on every Stop" to "context-aware guidance"

- **Retired the per-Stop state suggestion hook**: removed `suggest-next.sh` from both Stop and SessionStart and deleted the script. A bash hook that only looked at file presence gave guidance every turn, which was noisy and could not understand the conversation's context
- **Moved the guide role to the main AI (B)**: added `rules/apd/07-next-step.md`. The flow map and the guidance principles "only at milestones, context first, don't push (the next step) on the user" stay resident via `.claude/rules/apd/`, so the main AI, which can see the whole conversation, gives accurate next-step guidance
- **Added `/apd:status` (C)**: an on-demand skill that returns "current position + next step + rationale" from file state and conversation context. It doesn't rely on push and can be consulted when in doubt
- The Spec check (type:agent Stop hook) is kept as before

## [3.0.3] - 2026-06-28

### Fixed

- **Fixed an execution error in the SessionStart hook**: `suggest-next.sh` always output `hookEventName` as `"Stop"`, so when run as SessionStart it failed with `Hook returned incorrect event name: expected 'SessionStart' but got 'Stop'`. Changed it to read `hook_event_name` from stdin and return the actual event name

## [3.0.2] - 2026-06-28

### Fixed

- **Fixed the Spec check Stop hook blocking stops in non-APD projects**: even in repositories where `docs/apd/spec-*.md` does not exist (APD not installed/initialized), the `type:agent` Stop hook returned `ok:false` for "preconditions not met", blocking every Stop. Added a pass-through condition at the start of the prompt: "if there are no `spec-*.md` files, there is nothing to verify, so exit immediately with `ok:true` (don't block)"

## [3.0.1] - 2026-06-28

### Fixed

- **Fixed a plugin manifest validation error**: the `"hooks": "hooks/hooks.json"` field in `plugin.json` was rejected by the schema (`hooks: Invalid input`), causing the whole plugin to fail to load. Removed the field and switched to relying on automatic detection of `hooks/hooks.json` (as official plugins do)

## [3.0.0] - 2026-06-28

### Changed (Breaking) — APD v3: an autonomous run-to-completion model with zero intervention during implementation

- **Autonomous run-to-completion with zero intervention during implementation**: changed the design so that in the Build phase Claude autonomously completes implementation without interruption. Retired the escalation policy (progress checks and interruption decision flow during implementation)
- **Introduced the Spec check (`type:agent` Stop hook)**: added an agent Stop hook to `hooks/hooks.json` that automatically verifies the Acceptance Criteria are met when Build completes
- **Renamed `/apd:start` → `/apd:go` (breaking)**: unified the start command as `/apd:go`. All `/apd:start` calls in existing workflows must be updated
- **State suggestion hook**: added a hook that automatically infers the current cycle state (Design / Spec / Build / Done) and suggests the next action
- **Redefined Acceptance as the "post-completion hands-on check"**: Acceptance Criteria are now written as manual and automated check steps after implementation is complete. Write the verification points for the finished product, not a list of up-front specs
- **Retired the generic peer-review agent**: deleted the `apd:peer-review` agent. Review is replaced by the `/code-review` skill

## [2.0.0] - 2026-05-22

### Changed (Breaking) — Move to the living document model
- **Retired the Patch / Amendment concept**. Spec changes no longer stack diffs in separate files; **edit the existing Spec directly and bump its `version`**. git is the authoritative history
- **Consolidated Decisions into a single `docs/apd/decisions.md`**. Retired per-file `decision-{NNN}.md`
- **Made Preview optional**. Dropped "required in principle"; create `docs/apd/preview-{feature}/` only when needed
- **Reduced document types to three**: `design.md` / `decisions.md` / `spec-{feature}.md`
- **Stated that the human review surface is GitHub (PRs + issues)**. `docs/apd/` is positioned as working material for the AI, not a place humans routinely scan
- `rules/apd/00-principles.md`: shifted from "don't overwrite" to "git is the authoritative history; keep editing"
- `rules/apd/03-documents.md`: fully revised for the three types, decisions.md consolidation, and the GitHub review surface
- `rules/apd/05-deliverable-preview.md`: demoted Preview to optional
- `rules/apd/02-cycle-flow.md`: changed the bug fix flow to "edit the existing Spec"
- `skills/spec`: changed bugfix mode to "edit the existing Spec and bump version", switched to appending to decisions.md, removed Patch file generation
- `skills/migrate`: supports folding Patches into Specs and consolidating Decisions into decisions.md (migration now possible from both 0.x and 1.0.x)
- `scripts/verify-migration.sh`: added checks for leftover Patch files, per-file Decisions, and `patch_id:` frontmatter
- `templates/decision.md`: changed from a single-file format to a format for one section of decisions.md

### Removed (Breaking)
- `templates/spec-patch.md` / `examples/templates/spec-patch.md` — deleted because Patch files are no longer needed

### Why
In real use on pup, `docs/apd/` accumulated too many files and became hard to navigate. Based on the experience that "assuming files get moved leads to missed moves" and "Claude writes the docs, so humans hardly look at the repo", we switched to a model that **doesn't assume moves, treats git as the authoritative history, and has humans look at GitHub**.

## [1.0.2] - 2026-05-19

### Added
- `skills/migrate/` — the `/apd:migrate` skill. Performs AI-driven 0.x → 1.x migration. Interpreting frontmatter, replacing references in body text, and sorting items for manual review are done by AI judgment. Supports a `--dry-run` argument
- `scripts/verify-migration.sh` — a script that verifies migration results. Mechanically checks for leftover old subdirectories, old naming, old frontmatter and old path references. It performs no rewrites at all (check only)
- `MIGRATION.md` — a guide for migrating from old to new. Positions the AI-driven `/apd:migrate` as primary and `verify-migration.sh` as the means of verification. Covers steps, rollback and troubleshooting

### Notes
- Adopted the policy of **letting the AI decide** rather than automatic migration via a batch shell script (frontmatter values, references in body text, and handling of files that don't match naming conventions require contextual judgment)
- Separated responsibilities so the script does verification only

## [1.0.1] - 2026-05-19

### Changed
- **Aligned skill frontmatter with Anthropic's official conventions**:
  - Removed the `tools:` field from all 4 skills (`allowed-tools` is correct for skills; `tools:` is a subagent field and was a no-op)
  - Rewrote `description` in the order "[What it does]. Use when ..." (official best practice: main use case first)
  - Added `disable-model-invocation: true` to `skills/init` (it has filesystem write side effects, so automatic invocation is suppressed)
  - Added `argument-hint: "[full|add|bugfix] [issue#?]"` to `skills/spec`
  - Added `argument-hint: "<spec-file or issue#>"` to `skills/start`
- **Reduced the impression that GitHub Actions is required**:
  - Stated in `APD-FRAMEWORK.md` / `QUICKREF.md` that "the local `gh` CLI is enough. Actions/routines are optional"
  - Added that individual developers and small teams don't need to set up GitHub Actions

## [1.0.0] - 2026-05-18

### Removed (Breaking)
- `skills/build/` — retired the `/apd:build` skill (the Build phase moved to `/apd:start` + Claude Code `/goal`)
- `skills/cycle/` — retired the `/apd:cycle` skill (starting a cycle is handled by conversation + `gh issue create`)
- `skills/progress/` — retired the `/apd:progress` skill (replaced by `gh issue list` + `ls docs/apd/` + `/memory`)
- `agents/checkpoint.md` — retired the `apd:checkpoint` agent (Build convergence is judged by the `/goal` evaluator)
- `templates/cycle.md` `examples/templates/cycle.md` — deleted the templates since cycle definition files are retired

### Changed
- **README.md** rewritten for the new approach (4-skill structure, Acceptance terminology, division of roles with Claude Code features)
- **QUICKREF.md** rewritten for the new approach (quick reference for the 4 phases Intent / Spec / Build / Acceptance, flat file naming)
- **APD-FRAMEWORK.md** fully revised (states the design principle of being a thin convention layer that delegates to Claude Code features)
- **agents/peer-review.md** path references updated to the new flat structure

### Migration Notes
Projects using the old APD:

1. `/apd:build` → replace with `/apd:start <spec file>` + run with `/goal`
2. `/apd:cycle` → saying "I'm adding a new feature" or similar in conversation is enough; use `gh issue create` if there is an issue
3. `/apd:progress` → `gh issue list` + `ls docs/apd/` + `/memory`
4. `apd:checkpoint` agent → not needed (the `/goal` evaluator takes over)
5. The document tree was flattened in PR-1 (`docs/apd/{sub}/` → `docs/apd/*.md`)

## [0.7.0] - 2026-05-18

### Changed
- **Terminology**: `Amendment` → `Spec Patch` (the name for diff documents)
- **Directory structure**: flattened `docs/apd/`. Retired the `design/` `specs/` `decisions/` `cycles/` `previews/` subdirectories in favor of classification by prefix naming (`design.md`, `spec-{slug}.md`, `decision-{NNN}.md`, `preview-{slug}/`)
- **rules/apd/*.md** fully revised for the new approach:
  - Renamed `Human Checkpoint 2` → `Acceptance`
  - Retired the `AI Checkpoint` mechanism and delegated Build convergence judgment to Claude Code's `/goal` evaluator
  - Removed the rules for handoff documents (files for handing over across context resets)
  - Removed the rules for three-way reconciliation (evaluation criteria × evidence × toolcall)
  - Retired the per-cycle directory structure (`cycles/C-{NNN}/{handoffs,evidence}/`)
  - Removed the cycle ID (C-{NNN}) numbering rules; issue numbers or slugs are recommended
  - Changed the branch naming convention from `apd/C-{NNN}/*` to Conventional Commits style (`feat/{issue#}-{slug}`, etc.)
  - Stated that parallel execution uses Claude Code's subagents / agent teams / `/batch`
- **Where handoffs go**: changed to not create files and instead write them in the 「## 試し方」 ("How to try it") section of the PR body
- **skills/init**: creates only `docs/apd/` with the flat structure. When `gh` is detected, skips `todo.md` and points to GitHub issues as the primary backlog
- **skills/design**: changed the output path from `docs/apd/design/product-design.md` to `docs/apd/design.md`, removed the `Human Checkpoint 0` term
- **skills/spec**: supports the new flat structure paths, `Amendment` → `Spec Patch`, changed the final guidance from `/apd:build` to `/apd:start`, added support for generating a Spec from an issue number (`gh issue view`)

### Removed
- `templates/amendment.md` → renamed to `templates/spec-patch.md`

### Notes
- The old skills `/apd:build` `/apd:cycle` `/apd:progress` and the `apd:checkpoint` agent are not deleted in this PR; they will be cleaned up together in PR-3
- Revisions to `README.md` `QUICKREF.md` `APD-FRAMEWORK.md` will also be done in PR-3 (doing them together with deleting the old skills keeps the descriptions consistent)

## [0.6.0] - 2026-05-18

### Added
- `skills/start/` — added the `/apd:start` skill. A thin wrapper that assembles a condition for Claude Code's `/goal` command from the Spec's Acceptance Criteria and delegates the autonomous build loop to `/goal`. A prototype to validate the new approach (centering on `/goal`) in a real environment while coexisting with the existing `/apd:build`

## [0.4.0] - 2026-03-14

### Changed
- **Retired Contract, merged Phases** — merged Phase 2 (Contract) and Phase 3 (Execute) into Phase 2 (Build). Retired the Contract document; the Spec absorbs the Test Strategy and Deliverable Previews sections
- **Simplified the phase structure to 3 phases** — Design → Spec → Build (previously: Design → Spec → Contract → Execute)
- **Moved deliverable previews** — `docs/apd/contract/previews/` → `docs/apd/previews/`
- **Simplified the tech_change flow** — changed from Contract Amendment → Execute to Decision Record → Build
- **Simplified the Checkpoint agent** — retired the Phase 2 (Contract) review checklist and replaced it with a unified checklist for Build
- **Removed the Contract/Interface Compliance perspective from Peer Review** — consolidated into Spec Compliance

### Removed
- `skills/contract/` — retired the Contract skill
- `skills/execute/` — retired the Execute skill (merged into `skills/build/`)
- `templates/contract.md` — retired the Contract template
- `docs/apd/contract/` — removed the Contract directory from the document tree

### Added
- `skills/build/` — Build skill (merging the former Contract + Execute)
- Added a `Test Strategy` section (AC Coverage table) to the Spec template
- Added a `Deliverable Previews` section to the Spec template

## [0.3.1] - 2026-03-08

### Removed
- **Deleted the SessionStart hook (`check-init.sh`)** — retired the hook that detected uninitialized projects and emptied `hooks/hooks.json`

## [0.3.0] - 2026-03-08

### Changed
- **Retired Human Checkpoint 2 (Contract)** — changed to automatic approval after passing the AI Checkpoint. A human is asked only when there are escalation items
- **Changed Human Checkpoint 3 to "finished product check"** — checks whether the working deliverable is as intended. The framework does not require code review
- **Added Adversarial Testing to Peer Review** — added the perspective of actively trying to break things to find failure cases
- **Added instructions to the Execute skill to auto-generate BDD tests** — generates test code directly from the Spec's Given/When/Then ACs

### Updated
- `rules/apd/01-phases.md` — updated phase definitions and Checkpoint principles for the new approach
- `agents/checkpoint.md` — updated the summary output format for the new approach
- `agents/peer-review.md` — added the adversarial testing perspective
- `APD-FRAMEWORK.md` — fully revised (added Mermaid diagrams, reflected the new approach)
- `QUICKREF.md` — reflected the new flow and ToDo management

## [0.2.0] - 2026-03-08

### Added
- **ToDo management** — manage a cross-cycle backlog append-only in `docs/apd/todo.md`
- **Scoping** — in Spec (full mode), classify all features in the Design as in scope / out of scope for this cycle, and record out-of-scope features in the ToDo
- **ToDo template** — added `templates/todo.md`

### Changed
- Added instructions to the Design/Execute skills to record ToDos during dialogue and implementation
- Added a todo.md reference to the Cycle skill (presents open ToDos and suggests the next work)
- Added todo.md initialization to the Init skill

## [0.1.0] - 2026-03-08

### Added
- **Version bump script** — `scripts/bump-version.sh` updates `plugin.json` and `marketplace.json` together
- **CLAUDE.md** — documents the version management rules

### Changed
- Set the initial version to `0.1.0` (changed from `1.0.0`)

### Fixed
- **Added a guardrail to the Phase 0 Design skill to prevent technology choices from creeping in** — when the user provides tech stack information, it is kept out of the Design document and carried over to Phase 1
