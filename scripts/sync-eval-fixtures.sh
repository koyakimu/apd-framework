#!/usr/bin/env bash
# evals/_fixture/fixture.sh を、scaffold_script を使う各ケースのディレクトリへコピーする。
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT_DIR/evals/_fixture/fixture.sh"

for case_yaml in "$ROOT_DIR"/evals/*/case.yaml; do
  case_dir="$(dirname "$case_yaml")"
  if grep -q 'scaffold_script: fixture.sh' "$case_yaml"; then
    cp "$SRC" "$case_dir/fixture.sh"
    echo "synced: ${case_dir#"$ROOT_DIR"/}"
  fi
done
