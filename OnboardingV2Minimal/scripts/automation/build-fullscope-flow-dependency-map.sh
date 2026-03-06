#!/usr/bin/env bash

set -euo pipefail

ORG_ALIAS="${1:-OnboardV2}"
OUT_DIR="${2:-.analysis/automation-audit/fullscope-active-scan}"
INCLUDE_ALL_ACTIVE="${INCLUDE_ALL_ACTIVE:-false}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd sf
require_cmd jq
require_cmd awk
require_cmd sort

mkdir -p "$OUT_DIR"

SCOPE_CSV="$OUT_DIR/active_scope_names.csv"
SCOPE_TXT="$OUT_DIR/active_scope_names.txt"
INBOUND_TSV="$OUT_DIR/active_inbound_refs_fullscope.tsv"
ERROR_LOG="$OUT_DIR/active_scan_errors.log"
PROGRESS_LOG="$OUT_DIR/active_scan_progress.log"

if [ "$INCLUDE_ALL_ACTIVE" = "true" ]; then
  sf data query --target-org "$ORG_ALIAS" --use-tooling-api \
    --query "SELECT DeveloperName FROM FlowDefinition WHERE NamespacePrefix = null AND ActiveVersionId != null ORDER BY DeveloperName" \
    --result-format csv > "$SCOPE_CSV"
else
  sf data query --target-org "$ORG_ALIAS" --use-tooling-api \
    --query "SELECT DeveloperName FROM FlowDefinition WHERE NamespacePrefix = null AND ActiveVersionId != null AND (DeveloperName LIKE 'DOMAIN_%' OR DeveloperName LIKE 'BLL_%' OR DeveloperName LIKE 'APP_%' OR DeveloperName LIKE 'EXP_%') ORDER BY DeveloperName" \
    --result-format csv > "$SCOPE_CSV"
fi

awk -F, 'NR>1 {print $1}' "$SCOPE_CSV" > "$SCOPE_TXT"
: > "$INBOUND_TSV"
: > "$ERROR_LOG"
: > "$PROGRESS_LOG"

total="$(wc -l < "$SCOPE_TXT")"
i=0
while IFS= read -r flow; do
  [ -z "$flow" ] && continue
  i="$((i + 1))"
  echo "[$i/$total] $flow" >> "$PROGRESS_LOG"

  json_file="$OUT_DIR/.tmp_${i}.json"
  if ! sf data query --target-org "$ORG_ALIAS" --use-tooling-api \
    --query "SELECT Definition.DeveloperName, Metadata FROM Flow WHERE Definition.DeveloperName = '$flow' AND Status = 'Active' ORDER BY VersionNumber DESC LIMIT 1" \
    --result-format json > "$json_file" 2>> "$ERROR_LOG"; then
    echo "QUERY_FAIL|$flow" >> "$ERROR_LOG"
    rm -f "$json_file"
    continue
  fi

  jq -r '
    .result.records[0] | .Definition.DeveloperName as $d |
    [
      ((.Metadata.subflows // [])[]?.flowName),
      ((.Metadata.actionCalls // [])[]?.actionName),
      ((.Metadata.orchestratedStages // [])[]?.stageSteps[]?.actionName)
    ]
    | .[]
    | select(. != null and . != "")
    | "\($d)\t\(.)"
  ' "$json_file" >> "$INBOUND_TSV" || true

  rm -f "$json_file"
done < "$SCOPE_TXT"

{
  echo -e "CallerFlow\tCalleeFlow"
  sort -u "$INBOUND_TSV"
} > "$OUT_DIR/.tmp_inbound_with_header.tsv"

mv "$OUT_DIR/.tmp_inbound_with_header.tsv" "$INBOUND_TSV"
