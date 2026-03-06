#!/usr/bin/env bash

set -euo pipefail

ORG_ALIAS="${1:-OnboardV2}"
INPUT_TSV="${2:-.analysis/automation-audit/wave11-execution-2026-02-23/wave11_legacy_active_domain_queue.tsv}"
OUTPUT_TSV="${3:-.analysis/automation-audit/wave12_legacy_profile.tsv}"
ERROR_LOG="${4:-.analysis/automation-audit/wave12_legacy_profile_errors.log}"

if [ ! -f "$INPUT_TSV" ]; then
  echo "Missing input: $INPUT_TSV" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_TSV")"
mkdir -p "$(dirname "$ERROR_LOG")"

echo -e "FlowName\tProcessType\tStartObject\tTriggerType\tRecordTriggerType\tSubflowRefs\tActionRefs\tStageActionRefs" > "$OUTPUT_TSV"
: > "$ERROR_LOG"

tail -n +2 "$INPUT_TSV" | cut -f1 | while IFS= read -r flow; do
  [ -z "$flow" ] && continue

  tmp_json="$(mktemp)"
  if ! sf data query --target-org "$ORG_ALIAS" --use-tooling-api \
    --query "SELECT Definition.DeveloperName, Metadata FROM Flow WHERE Definition.DeveloperName = '$flow' AND Status='Active' ORDER BY VersionNumber DESC LIMIT 1" \
    --result-format json > "$tmp_json" 2>> "$ERROR_LOG"; then
    echo "QUERY_FAIL|$flow" >> "$ERROR_LOG"
    rm -f "$tmp_json"
    continue
  fi

  jq -r '
    .result.records[0] as $r |
    [
      ($r.Definition.DeveloperName // ""),
      ($r.Metadata.processType // ""),
      ($r.Metadata.start.object // ""),
      ($r.Metadata.start.triggerType // ""),
      ($r.Metadata.start.recordTriggerType // ""),
      ([($r.Metadata.subflows // [])[]?.flowName] | map(select(. != null and . != "")) | unique | join(";")),
      ([($r.Metadata.actionCalls // [])[]?.actionName] | map(select(. != null and . != "")) | unique | join(";")),
      ([($r.Metadata.orchestratedStages // [])[]?.stageSteps[]?.actionName] | map(select(. != null and . != "")) | unique | join(";"))
    ] | @tsv
  ' "$tmp_json" >> "$OUTPUT_TSV" || true

  rm -f "$tmp_json"
done

