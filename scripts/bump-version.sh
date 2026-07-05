#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/bump-version.sh <major|minor|patch>
# Updates version in plugin.json and marketplace.json

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_JSON="$ROOT_DIR/.claude-plugin/plugin.json"
MARKETPLACE_JSON="$ROOT_DIR/.claude-plugin/marketplace.json"

if [[ $# -ne 1 ]] || [[ ! "$1" =~ ^(major|minor|patch)$ ]]; then
  echo "Usage: $0 <major|minor|patch>"
  exit 1
fi

BUMP_TYPE="$1"

# Get current version from plugin.json
CURRENT_VERSION=$(python3 -c "import json; print(json.load(open('$PLUGIN_JSON'))['version'])")

if [[ ! "$CURRENT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: unsupported version format '$CURRENT_VERSION' (expected MAJOR.MINOR.PATCH)" >&2
  exit 1
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

case "$BUMP_TYPE" in
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  patch) PATCH=$((PATCH + 1)) ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Update plugin.json
python3 -c "
import json
with open('$PLUGIN_JSON', 'r') as f:
    data = json.load(f)
data['version'] = '$NEW_VERSION'
with open('$PLUGIN_JSON', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"

# Update marketplace.json
python3 -c "
import json, sys
with open('$MARKETPLACE_JSON', 'r') as f:
    data = json.load(f)
updated = False
for plugin in data.get('plugins', []):
    if plugin.get('name') == 'apd':
        plugin['version'] = '$NEW_VERSION'
        updated = True
if not updated:
    sys.exit(\"Error: plugin 'apd' not found in marketplace.json\")
with open('$MARKETPLACE_JSON', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"

echo "$CURRENT_VERSION -> $NEW_VERSION"
