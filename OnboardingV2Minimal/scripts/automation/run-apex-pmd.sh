#!/usr/bin/env bash

set -euo pipefail

RULESET_PATH="${1:-pmd-ruleset.xml}"
TARGET_DIR="${2:-force-app/main/default/classes}"

PMD_BIN=""
if command -v pmd >/dev/null 2>&1; then
  PMD_BIN="pmd"
elif [[ -x "node_modules/.bin/pmd" ]]; then
  PMD_BIN="node_modules/.bin/pmd"
fi

if [[ -z "$PMD_BIN" ]]; then
  echo "PMD CLI is not installed or not on PATH."
  echo "Install local PMD and rerun: npm install --save-dev pmd-bin && npm run pmd:apex"
  exit 1
fi

if "$PMD_BIN" --help 2>&1 | grep -q "check"; then
  "$PMD_BIN" check -d "$TARGET_DIR" -R "$RULESET_PATH" -f text
else
  "$PMD_BIN" -d "$TARGET_DIR" -R "$RULESET_PATH" -f text
fi
