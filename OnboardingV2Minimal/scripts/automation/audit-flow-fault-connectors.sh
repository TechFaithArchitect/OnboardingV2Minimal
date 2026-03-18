#!/usr/bin/env bash
# Audit flows for recordCreates, recordUpdates, actionCalls that lack faultConnector.
# Output: TSV of FlowName, ElementType, ElementName, HasFaultConnector

set -euo pipefail

FLOWS_DIR="${1:-force-app/main/default/flows}"
OUT_TSV="${2:-.analysis/automation-audit/flow_fault_connector_audit.tsv}"

mkdir -p "$(dirname "$OUT_TSV")"
echo -e "FlowName\tElementType\tElementName\tHasFaultConnector" > "$OUT_TSV"

for f in "$FLOWS_DIR"/*.flow-meta.xml "$FLOWS_DIR"/*.flow; do
  [ -f "$f" ] || continue
  flow_name="$(basename "$f" | sed 's/\.flow-meta\.xml$//;s/\.flow$//')"

  # Use perl for multiline regex (match each element type separately)
  FLOW_NAME="$flow_name" perl -0 -ne '
    my $flow = $ENV{FLOW_NAME} // "(unknown)";
    for my $type (qw(recordCreates recordUpdates actionCalls)) {
      my $re = qr/<${type}>([\s\S]*?)<\/${type}>/;
      while (m/$re/g) {
        my $block = $1;
        my ($name) = $block =~ /<name>([^<]+)<\/name>/;
        $name ||= "(unnamed)";
        my $has = $block =~ /<faultConnector>/ ? "yes" : "no";
        print "$flow\t$type\t$name\t$has\n";
      }
    }
  ' "$f" 2>/dev/null || true
done >> "$OUT_TSV"

echo "Audit complete. Gaps (no faultConnector):"
awk -F'\t' 'NR>1 && $4=="no" {print "  " $1 " | " $2 " | " $3}' "$OUT_TSV" 2>/dev/null || echo "  (none or empty audit)"
echo "Full report: $OUT_TSV"
