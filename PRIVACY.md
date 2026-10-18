# Privacy Policy

Last updated: 2026-10-18

This policy covers the APD (Autopilot Development) plugin for Claude Code, published at https://github.com/koyakimu/apd-framework by Koya Kimura.

## What the plugin collects

Nothing. The plugin has no server, no analytics and no telemetry. It does not collect, store or transmit personal data, and the author receives no data from your use of it.

## What the plugin does on your machine

The plugin consists of instructions (skills and rules), document templates, a session-start hook that prints text into Claude's context, and helper scripts. When you use it, Claude Code:

- reads and writes files in your project, such as `docs/apd/` and `.claude/rules/apd/`
- may run commands you already use, such as `git`, or your issue tracker's tool (for example `gh` for GitHub issues), to open pull requests and issues in your own repository

These actions run locally under your own account and permissions, and any data they send goes only to services you already use (for example your Git host). The plugin does not read your credentials.

## Claude and other services

Your conversations with Claude, and the files Claude reads while using this plugin, are processed by Anthropic under Anthropic's own terms and privacy policy. Services you connect to (for example GitHub) handle data under their own policies.

## Changes and contact

Changes to this policy are recorded in this file's history in the repository. For questions, open an issue at https://github.com/koyakimu/apd-framework/issues.
