# APD Framework — development rules

## Versioning

- Bump the version in every commit that adds a feature or fixes a bug
- Bump it with `scripts/bump-version.sh`, passing `major`, `minor` or `patch` (it updates `plugin.json` and `marketplace.json` together)
- Follow semver: breaking change → major, new feature → minor, bug fix → patch
- Add a matching entry at the top of `CHANGELOG.md` (CI checks that it matches the version)
- Release tags (`v{version}`, e.g. `v3.3.1`) are added by CI after merging to main. Do not tag by hand

## Language

- The plugin's skills, rules, templates and docs are written in English; the plugin itself works in the user's language (`rules/apd/00-principles.md` › Language)
- Keep `README.ja.md` in step with `README.md`
