#!/usr/bin/env bash
# Verify that an APD project matches the current model: flat docs/apd/
# layout, a CLAUDE.md free of APD injection/duplication/stale text, and
# up-to-date .claude/rules/apd/.
#
# Usage:
#   cd /path/to/your/project
#   bash <path-to-apd-plugin>/scripts/verify-migration.sh
#   # (set CLAUDE_PLUGIN_ROOT to also diff rules against the installed plugin)
#
# Returns exit 0 if everything is in the expected current layout.
# Returns exit 1 if any issues are detected, listing them.
#
# This is a CHECK ONLY script. It does not move or rewrite anything.
# The actual migration is done by the /apd:migrate skill (AI-driven).

set -uo pipefail

if [[ ! -d "docs/apd" ]]; then
  echo "Error: docs/apd/ not found. Run this from your project root."
  exit 1
fi

FAILED=0
PASSED=0
WARNINGS=()

pass() {
  PASSED=$((PASSED + 1))
  echo "  [PASS] $1"
}

fail() {
  FAILED=$((FAILED + 1))
  echo "  [FAIL] $1"
}

warn() {
  WARNINGS+=("$1")
}

echo "=== APD Migration Verification ==="
echo ""

# ----------------------------------------------------------------------
# Check 1: Old subdirectories should not exist
# ----------------------------------------------------------------------

echo "Check 1: Old subdirectories removed"
for sub in design specs decisions cycles previews; do
  if [[ -d "docs/apd/${sub}" ]]; then
    fail "docs/apd/${sub}/ still exists (should be flattened)"
  else
    pass "docs/apd/${sub}/ absent"
  fi
done
echo ""

# ----------------------------------------------------------------------
# Check 2: New flat files use expected naming
# ----------------------------------------------------------------------

echo "Check 2: New naming conventions"

if [[ -f "docs/apd/design.md" ]]; then
  pass "docs/apd/design.md exists"
else
  warn "docs/apd/design.md not found (OK if project never had a Design)"
fi

spec_count=$(find docs/apd -maxdepth 1 -name "spec-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [[ "$spec_count" -gt 0 ]]; then
  pass "${spec_count} spec-*.md file(s) at docs/apd/ root"
else
  warn "No spec-*.md files found (OK if project has no Specs yet)"
fi

old_amend=$(find docs/apd -maxdepth 1 -name "*.A-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [[ "$old_amend" -gt 0 ]]; then
  fail "Found ${old_amend} file(s) with old amendment naming (*.A-*.md)"
  find docs/apd -maxdepth 1 -name "*.A-*.md" -type f 2>/dev/null | sed 's/^/    /'
else
  pass "No old amendment-style filenames (*.A-*.md)"
fi

old_vers=$(find docs/apd -maxdepth 1 -name "*.v[0-9]*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [[ "$old_vers" -gt 0 ]]; then
  fail "Found ${old_vers} file(s) with old version-suffix naming (*.v{N}.md)"
  find docs/apd -maxdepth 1 -name "*.v[0-9]*.md" -type f 2>/dev/null | sed 's/^/    /'
else
  pass "No old version-suffix filenames (*.v{N}.md)"
fi

old_decision=$(find docs/apd -maxdepth 1 \( -name "D-*.md" -o -name "decision-*.md" \) -type f 2>/dev/null | wc -l | tr -d ' ')
if [[ "$old_decision" -gt 0 ]]; then
  fail "Found ${old_decision} per-file Decision Record(s) (should be consolidated into decisions.md)"
  find docs/apd -maxdepth 1 \( -name "D-*.md" -o -name "decision-*.md" \) -type f 2>/dev/null | sed 's/^/    /'
else
  pass "No per-file Decision Records (D-*.md / decision-*.md)"
fi

# Patch files should be folded into their parent spec
patch_files=$(find docs/apd -maxdepth 1 -name "spec-*-patch-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
if [[ "$patch_files" -gt 0 ]]; then
  fail "Found ${patch_files} Patch file(s) (should be folded into the parent spec, then deleted)"
  find docs/apd -maxdepth 1 -name "spec-*-patch-*.md" -type f 2>/dev/null | sed 's/^/    /'
else
  pass "No Patch files (spec-*-patch-*.md)"
fi

# decisions.md presence (informational)
if [[ -f "docs/apd/decisions.md" ]]; then
  pass "docs/apd/decisions.md exists (single decision log)"
else
  warn "docs/apd/decisions.md not found (OK if project has no recorded decisions)"
fi

echo ""

# ----------------------------------------------------------------------
# Check 3: Frontmatter field updates
# ----------------------------------------------------------------------

echo "Check 3: Frontmatter fields"

amendment_id_files=$(grep -l "^amendment_id:" docs/apd/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$amendment_id_files" -gt 0 ]]; then
  fail "${amendment_id_files} file(s) still have 'amendment_id:' frontmatter (should be 'patch_id:')"
  grep -l "^amendment_id:" docs/apd/*.md 2>/dev/null | sed 's/^/    /'
else
  pass "No 'amendment_id:' frontmatter"
fi

patch_id_files=$(grep -l "^patch_id:" docs/apd/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$patch_id_files" -gt 0 ]]; then
  fail "${patch_id_files} file(s) still have 'patch_id:' frontmatter (Patch files should be folded into the parent spec)"
  grep -l "^patch_id:" docs/apd/*.md 2>/dev/null | sed 's/^/    /'
else
  pass "No 'patch_id:' frontmatter"
fi

cycle_ref_files=$(grep -l "^cycle_ref:" docs/apd/*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$cycle_ref_files" -gt 0 ]]; then
  fail "${cycle_ref_files} file(s) still have 'cycle_ref:' frontmatter (should be 'issue_ref:')"
  grep -l "^cycle_ref:" docs/apd/*.md 2>/dev/null | sed 's/^/    /'
else
  pass "No 'cycle_ref:' frontmatter"
fi

echo ""

# ----------------------------------------------------------------------
# Check 4: Body references to old paths
# ----------------------------------------------------------------------

echo "Check 4: Body references to old paths"

old_path_refs=$(grep -rEl 'docs/apd/(design|specs|decisions|cycles|previews)/' docs/apd 2>/dev/null | wc -l | tr -d ' ')
if [[ "$old_path_refs" -gt 0 ]]; then
  fail "${old_path_refs} file(s) reference old subdirectory paths in their body"
  grep -rEl 'docs/apd/(design|specs|decisions|cycles|previews)/' docs/apd 2>/dev/null | sed 's/^/    /'
else
  pass "No body references to old subdirectory paths"
fi

if [[ -f "CLAUDE.md" ]]; then
  if grep -qE 'docs/apd/(design|specs|decisions|cycles|previews)/' CLAUDE.md 2>/dev/null; then
    fail "CLAUDE.md references old subdirectory paths"
  else
    pass "CLAUDE.md has no old subdirectory path references"
  fi
fi

echo ""

# ----------------------------------------------------------------------
# Check 5: CLAUDE.md is free of APD injection / duplication / stale text
# ----------------------------------------------------------------------

echo "Check 5: CLAUDE.md cleanliness (APD cruft removed)"

if [[ -f "CLAUDE.md" ]]; then
  # Injected banner line: "APD ... フレームワーク x.y.z ... で開発"
  if grep -qE 'APD.*(フレームワーク|Framework).*[0-9]+\.[0-9]+\.[0-9]+.*(で開発|powered by|built with)' CLAUDE.md 2>/dev/null \
     || grep -qE 'フレームワーク.*[0-9]+\.[0-9]+\.[0-9]+.*で開発' CLAUDE.md 2>/dev/null; then
    fail "CLAUDE.md still has an injected APD version banner (remove it)"
  else
    pass "CLAUDE.md has no injected APD version banner"
  fi

  # Stale: removed Spec-check Stop hook
  if grep -qE 'Spec ?チェック.*Stop ?フック|Stop ?フック.*Spec ?チェック' CLAUDE.md 2>/dev/null; then
    fail "CLAUDE.md references the removed Spec-check Stop hook (now a Build step)"
  else
    pass "CLAUDE.md has no Spec-check Stop hook reference"
  fi

  # Stale: removed v2 escalation two-list (APD-specific phrasing only, to avoid
  # flagging a project's own unrelated escalation policy)
  if grep -qE 'Build 中のエスカレーションポリシー|Build 内で完結してよい' CLAUDE.md 2>/dev/null; then
    fail "CLAUDE.md has the old APD escalation policy two-list (removed model)"
  else
    pass "CLAUDE.md has no old APD escalation policy block"
  fi

  # Deprecated commands / agents
  if grep -qE '/apd:(build|start|cycle|progress)|apd:(peer-review|checkpoint)' CLAUDE.md 2>/dev/null; then
    fail "CLAUDE.md references deprecated commands/agents (/apd:build|start|cycle|progress, apd:peer-review|checkpoint)"
  else
    pass "CLAUDE.md has no deprecated command/agent references"
  fi

  # Duplicated generic rule section heading
  if grep -qE '^##+ +APD 準拠ルール' CLAUDE.md 2>/dev/null; then
    warn "CLAUDE.md has an 'APD 準拠ルール' section — likely duplicates .claude/rules/apd/ (move generic rules out)"
  fi
else
  warn "CLAUDE.md not found (skipped CLAUDE.md cleanliness checks)"
fi

echo ""

# ----------------------------------------------------------------------
# Check 6: .claude/rules/apd/ is present and not stale
# ----------------------------------------------------------------------

echo "Check 6: .claude/rules/apd/ freshness"

if [[ -d ".claude/rules/apd" ]]; then
  pass ".claude/rules/apd/ exists"
  # Stale rule content: Stop-hook wording removed in 3.2.0
  if grep -rqE 'Stop ?フック' .claude/rules/apd/ 2>/dev/null; then
    fail ".claude/rules/apd/ still mentions 'Stop フック' (stale — re-copy from the plugin / run /apd:migrate)"
  else
    pass ".claude/rules/apd/ has no stale Stop-hook wording"
  fi
  # Stale rule content: goal/Task-tool wording removed in 3.4.0
  if grep -rqE '毎ターン後|TaskCreate）' .claude/rules/apd/ 2>/dev/null; then
    fail ".claude/rules/apd/ has pre-3.4.0 wording (毎ターン後 / TaskCreate) — re-copy from the plugin / run /apd:migrate"
  else
    pass ".claude/rules/apd/ has no pre-3.4.0 goal/Task-tool wording"
  fi
  # Compare against the installed plugin rules when available
  if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" && -d "${CLAUDE_PLUGIN_ROOT}/rules/apd" ]]; then
    drift=0
    for f in "${CLAUDE_PLUGIN_ROOT}/rules/apd/"*.md; do
      base=$(basename "$f")
      if [[ ! -f ".claude/rules/apd/${base}" ]] || ! diff -q ".claude/rules/apd/${base}" "$f" >/dev/null 2>&1; then
        drift=$((drift + 1))
      fi
    done
    if [[ "$drift" -gt 0 ]]; then
      warn ".claude/rules/apd/ differs from the installed plugin in ${drift} file(s) (version drift or local customization)"
    else
      pass ".claude/rules/apd/ matches the installed plugin rules"
    fi
  fi
else
  warn ".claude/rules/apd/ not found (run /apd:init or /apd:migrate to install rules)"
fi

echo ""

# ----------------------------------------------------------------------
# Check 7: Backup directory exists (recommended)
# ----------------------------------------------------------------------

echo "Check 7: Backup retention"
backup_count=$(find . -maxdepth 2 -type d -name "apd.backup-*" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$backup_count" -gt 0 ]]; then
  pass "Backup directory present (recommended to keep for several cycles)"
  find . -maxdepth 2 -type d -name "apd.backup-*" 2>/dev/null | sed 's/^/    /'
else
  warn "No backup directory found (expected docs/apd.backup-{timestamp}/). If you did the migration, consider keeping the backup for a few cycles."
fi

echo ""

# ----------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------

echo "==================================================="
echo "Summary: ${PASSED} passed, ${FAILED} failed, ${#WARNINGS[@]} warning(s)"
echo "==================================================="

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo ""
  echo "Warnings (not failures):"
  for w in "${WARNINGS[@]}"; do
    echo "  ! $w"
  done
fi

if [[ "$FAILED" -gt 0 ]]; then
  echo ""
  echo "Migration verification FAILED. Review the items marked [FAIL] above."
  echo "Run /apd:migrate to apply remaining migration steps, or fix manually."
  exit 1
fi

echo ""
echo "Migration verification passed."
exit 0
