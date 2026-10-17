# Building with `/goal`

Use only when the user wants a long unattended run. `/goal` is a Claude Code feature that keeps taking turns until a condition is met; an evaluator judges completion at the end of each turn. Only the user can send a slash command, so leave sending it to the user.

## Steps

1. Condense "3. Assemble the completion condition" from SKILL.md to within 4,000 characters to form the condition. Include a turn or time limit
2. Give the user the condition and the text to send it with `/goal`. Also tell them:
   - Paste it in auto mode (`⏵⏵ auto mode on` in the status bar). If in Manual mode, switch with Shift+Tab. `/goal` does not change the permission mode, so in Manual it will stop at permission prompts
   - Even in auto mode, it stops on consecutive classifier blocks, `permissions.ask`, and the first read outside the working directory
   - Keep a copy of the condition text. If a turn fails due to authentication failure, running out of credits, unresolvable context overflow, or model unavailability, the goal is cleared automatically, so fix the cause and paste it again (on rate limits the goal remains)
3. If parallelization is needed, also mention agent teams, dynamic workflows, and `/batch` as options besides subagents

## How the evaluator judges

- The evaluator calls no tools and judges only from information in the conversation. Put test run logs, the changes, and the PR in the conversation
- If a turn ends while subagents or background shells are still running, that turn is not evaluated; judgement happens on the next turn with no background work

## Troubleshooting

| Symptom | Fix |
|---|---|
| The evaluator keeps returning no | The condition is abstract. Make it concrete by quoting the AC wording |
| High token consumption | Put a turn or time limit in the condition |
| Stops at permission prompts | It was pasted in Manual mode. Switch to auto mode with Shift+Tab. The goal remains, so no need to paste again |
| Stops after a run of turns with no tool use | Claude Code stops the loop and returns control. The goal remains, and evaluation resumes on the next prompt |
| `/goal` is unavailable | Check the Claude Code version, workspace trust, `disableAllHooks`, and `allowManagedHooksOnly` in managed settings |
