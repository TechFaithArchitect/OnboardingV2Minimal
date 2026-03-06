#!/usr/bin/env bash

set -euo pipefail

ORG_ALIAS="${1:-OnboardV2}"
INPUT_FILE="${2:-.analysis/automation-audit/wave12-execution-2026-02-23/wave12_legacy_active_domain_queue.tsv}"
OUTPUT_TSV="${3:-.analysis/automation-audit/wave12-execution-2026-02-23/apex_flow_name_refs.tsv}"
ERROR_LOG="${4:-.analysis/automation-audit/wave12-execution-2026-02-23/apex_flow_name_refs_errors.log}"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Missing input: $INPUT_FILE" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_TSV")"
mkdir -p "$(dirname "$ERROR_LOG")"

echo -e "FlowName\tApexClassRefs\tApexTriggerRefs" > "$OUTPUT_TSV"
: > "$ERROR_LOG"

tmp_classes="$(mktemp)"
tmp_triggers="$(mktemp)"

if ! sf data query --target-org "$ORG_ALIAS" --use-tooling-api \
  --query "SELECT Name, Body FROM ApexClass WHERE NamespacePrefix = null" \
  --result-format json > "$tmp_classes" 2>> "$ERROR_LOG"; then
  echo "CLASS_EXPORT_FAIL" >> "$ERROR_LOG"
  rm -f "$tmp_classes" "$tmp_triggers"
  exit 1
fi

if ! sf data query --target-org "$ORG_ALIAS" --use-tooling-api \
  --query "SELECT Name, Body FROM ApexTrigger WHERE NamespacePrefix = null" \
  --result-format json > "$tmp_triggers" 2>> "$ERROR_LOG"; then
  echo "TRIGGER_EXPORT_FAIL" >> "$ERROR_LOG"
  rm -f "$tmp_classes" "$tmp_triggers"
  exit 1
fi

tail -n +2 "$INPUT_FILE" | cut -f1 | while IFS= read -r flow; do
  [ -z "$flow" ] && continue

  class_count="$(
    jq -r --arg f "$flow" '
      [.result.records[] | select((.Body // "") | contains($f))] | length
    ' "$tmp_classes"
  )"

  trigger_count="$(
    jq -r --arg f "$flow" '
      [.result.records[] | select((.Body // "") | contains($f))] | length
    ' "$tmp_triggers"
  )"

  printf "%s\t%s\t%s\n" "$flow" "$class_count" "$trigger_count" >> "$OUTPUT_TSV"
done

rm -f "$tmp_classes" "$tmp_triggers"
