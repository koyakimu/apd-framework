<!-- Spec template: YAML frontmatter + Markdown -->
<!-- Follows the default Spec format in CLAUDE.md -->

---
spec_id: "{CONTEXT_ID}-{NNN}"   # e.g. OM-001
context: "{context name}"       # e.g. order-management
version: 1
issue_ref: "{GitHub issue number, or null if none}"
title: "{feature title}"
decision_refs: []
# - D-001
# - D-002
---

## User Story

**As a** {who}
**I want** {what}
**So that** {why}

## Acceptance Criteria

### AC-001
- **Given**: {precondition}
- **When**: {triggering action}
- **Then**: {expected result}

### AC-002
- **Given**: {precondition}
- **When**: {triggering action}
- **Then**: {expected result}

### AC-003 (Error Case)
- **Given**: {precondition under which the error occurs}
- **When**: {action}
- **Then**: {expected behavior on error}

### AC-NFR-001 (Non-Functional / only when measurable)
- **Given**: {precondition (load, environment, etc.)}
- **When**: {action}
- **Then**: {measurable threshold (e.g. p95 < 200ms, a11y score ≥ 90)}

## UI Description

{screen layout, main elements, description of interactions}
{if there are instructions for a mock tool, write them here}

## Context Boundary

### Inputs
- **From**: {source context or external} — {description of the data}

### Outputs
- **To**: {destination context or external} — {description of the data}

### Dependencies
- **{context depended on}**: {reason for the dependency}

## Test Strategy

### AC Coverage

| AC ID | Test Type | Description |
|-------|-----------|-------------|
| AC-001 | unit / integration / e2e | {what is tested} |
| AC-002 | unit / integration / e2e | {what is tested} |
| AC-003 | unit / integration / e2e | {what is tested} |
| AC-NFR-001 | measurement / delegate such as `/security-review` | {measurement method / delegate's pass criteria} |

## Deliverable Previews

{types and descriptions of previews to generate (if applicable)}
{e.g. architecture diagram, UI mock, API specification, data model diagram}

## Delegated Non-Functional Requirements
- For things that cannot be written as measurable AC, such as security, state the delegate (/security-review etc.) and include its result in Build's completion condition.

## Notes

{additional considerations, constraints, assumptions, etc.}
