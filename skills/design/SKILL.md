---
name: design
description: >
  Creates the product Design document (the north star) through
  interactive dialogue. Writes to `docs/apd/design.md`. Use before
  writing any code when the user asks to build a new product or app,
  or to change a product's direction, and `docs/apd/design.md` does
  not exist yet, even if the user did not ask for a design. Also use
  when the user asks to create a design document, design a product,
  or run /apd:design ("Design 文書を作成", "プロダクトを設計").
---

# APD Design — Creating the Design document through dialogue

Create the product's Design document (the north star) through a few rounds of dialogue with the user.

## Always

- Do not write code until the Design is approved
- Once approved, proceed straight to the Spec following the `apd:spec` steps. Do not ask the user to type a command
- Do not include the tech stack or implementation approach in the Design. If the user brings them up, tell them "I'll handle that as technology selection in the Spec"
- Converse and write documents in the user's language; keep the templates' section names, IDs and frontmatter keys as they are (`rules/apd/00-principles.md` › Language)

## How to run the dialogue

### 1. Gather requirements

Listen to the product idea and ask about anything unclear.

### 2. Draft generation

Generate the full Design document draft in one go, in the following Amazon PR/FAQ format:

1. **Who (who it is for)**: target user persona, problem, context
2. **Why (why now)**: market opportunity, rationale for the timing, limits of existing solutions
3. **What (what it can do)**: features and experience described from the user's point of view (no technical service names or architecture)
4. **What Not (what it will not do)**: explicit out-of-scope items. Eliminate ambiguous boundaries (write them as product scope, not technical constraints)
5. **FAQ**: anticipated questions and answers. Include stakeholder, user, and engineer viewpoints (no technical implementation details; write from a product and operations perspective)
6. **Success Criteria**: quantitative and qualitative success metrics

### 3. State confidence

For each section, state the following:

- **Confident** — content clearly derived from the user's input
- **Filled in by inference (needs confirmation)** — content unclear from the user's input that the AI filled in
- **Moved to the Spec phase** — technology selection information the user provided that is outside the Design document's scope and will be handled in the Spec phase (only if any)

### 4. Feedback loop

Revise based on the user's feedback. Converge within a few rounds.

## Recording ToDos

If the dialogue produces "ideas outside this Design's scope that should be considered in the future", record them. Where GitHub issues are available, file them with `gh issue create`. Where they are not, append them to `docs/apd/todo.md`. Do not include them in the Design document itself.

## Constraints

- **Follow the template's section structure (Who / Why / What / What Not / FAQ / Success Criteria) strictly in the draft, and do not add your own sections (e.g. hosting setup, technical architecture)**
- **What Not must have at least 5 items**
- **FAQ must have at least 10 questions**
- **Success Criteria must include measurable metrics**

## Output

Write the Design document to `docs/apd/design.md` in Markdown (with YAML frontmatter). If CLAUDE.md defines a format, follow it.

## Review

When the Design document is complete, present the following checklist:

- [ ] Who: Is the target user clearly defined?
- [ ] Why: Are the reason to build it and the timing convincing?
- [ ] What: Is the user value described without technical terms?
- [ ] What Not: Is out-of-scope sufficiently explicit (at least 5 items)?
- [ ] FAQ: Are the main questions covered (at least 10)?
- [ ] Success Criteria: Are there measurable metrics?

If the user asks for revisions, continue the dialogue.
