#!/usr/bin/env bash
# Audit subflow calls for missing errorMessage output mapping when the called flow exposes errorMessage as output.
# Output: TSV listing parent flow/subflow calls that should map child errorMessage output.

set -euo pipefail

FLOWS_DIR="${1:-force-app/main/default/flows}"
OUT_TSV="${2:-.analysis/automation-audit/subflow_error_contract_audit.tsv}"

mkdir -p "$(dirname "$OUT_TSV")"
echo -e "ParentFlow\tSubflowElement\tCalledFlow\tMapsErrorMessageOutput\tViolationType" > "$OUT_TSV"

exposes_error_output() {
  local called_flow="$1"
  local called_file_meta="${FLOWS_DIR}/${called_flow}.flow-meta.xml"
  local called_file_legacy="${FLOWS_DIR}/${called_flow}.flow"
  local called_file=""

  if [ -f "$called_file_meta" ]; then
    called_file="$called_file_meta"
  elif [ -f "$called_file_legacy" ]; then
    called_file="$called_file_legacy"
  else
    return 1
  fi

  perl -0ne 'if (/<variables>[\s\S]*?<name>errorMessage<\/name>[\s\S]*?<isOutput>true<\/isOutput>[\s\S]*?<\/variables>/) { exit 0; } END { exit 1; }' "$called_file"
}

for parent_file in "$FLOWS_DIR"/*.flow-meta.xml "$FLOWS_DIR"/*.flow; do
  [ -f "$parent_file" ] || continue
  parent_flow="$(basename "$parent_file" | sed 's/\.flow-meta\.xml$//;s/\.flow$//')"

  while IFS=$'\t' read -r subflow_name called_flow maps_error; do
    [ -n "$called_flow" ] || continue
    if exposes_error_output "$called_flow" && [ "$maps_error" -eq 0 ]; then
      echo -e "${parent_flow}\t${subflow_name}\t${called_flow}\tno\tMISSING_ERRORMESSAGE_OUTPUT_MAPPING" >> "$OUT_TSV"
    fi
  done < <(
    perl -0ne '
      while (/<subflows>([\s\S]*?)<\/subflows>/g) {
        my $block = $1;
        my ($name) = $block =~ /<name>([^<]+)<\/name>/;
        my ($flow_name) = $block =~ /<flowName>([^<]+)<\/flowName>/;
        next unless defined $flow_name;
        $name ||= "(unnamed)";
        my $maps_error = ($block =~ /<outputAssignments>[\s\S]*?<name>errorMessage<\/name>[\s\S]*?<\/outputAssignments>/) ? 1 : 0;
        print "$name\t$flow_name\t$maps_error\n";
      }
    ' "$parent_file" 2>/dev/null || true
  )
done

violations="$(awk 'NR>1 {count++} END {print count+0}' "$OUT_TSV")"
echo "Subflow error-contract audit complete."
echo "Missing errorMessage output mappings: $violations"

if [ "$violations" -gt 0 ]; then
  echo "Top findings:"
  awk -F'\t' 'NR>1 {print "  " $1 " | " $2 " -> " $3 " | " $5}' "$OUT_TSV" | head -n 40
fi

echo "Report: $OUT_TSV"
