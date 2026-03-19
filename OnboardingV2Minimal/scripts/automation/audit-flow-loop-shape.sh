#!/usr/bin/env bash
# Audit flow loop shape for potential in-loop query/DML anti-patterns.
# Produces two TSVs:
#  - flow_loop_lookup_dependency.tsv
#  - flow_loop_dml_dependency.tsv

set -euo pipefail

FLOWS_DIR="${1:-force-app/main/default/flows}"
OUT_DIR="${2:-.analysis/automation-audit}"
LOOKUP_OUT="$OUT_DIR/flow_loop_lookup_dependency.tsv"
DML_OUT="$OUT_DIR/flow_loop_dml_dependency.tsv"

mkdir -p "$OUT_DIR"

echo -e "FlowName\tLookupName\tLoopReference" > "$LOOKUP_OUT"
echo -e "FlowName\tElementType\tElementName\tLoopReference" > "$DML_OUT"

for f in "$FLOWS_DIR"/*.flow-meta.xml "$FLOWS_DIR"/*.flow; do
  [ -f "$f" ] || continue
  flow_name="$(basename "$f" | sed 's/\.flow-meta\.xml$//;s/\.flow$//')"

  FLOW_NAME="$flow_name" perl -0 -ne '
    my $flow = $ENV{FLOW_NAME} // "(unknown)";
    while (m/<recordLookups>([\s\S]*?)<\/recordLookups>/g) {
      my $block = $1;
      my ($name) = $block =~ /<name>([^<]+)<\/name>/;
      $name ||= "(unnamed)";
      while ($block =~ /<elementReference>((?:Loop_|currentItem_)[^<]+)<\/elementReference>/g) {
        print "$flow\t$name\t$1\n";
      }
    }
  ' "$f" >> "$LOOKUP_OUT" 2>/dev/null || true

  FLOW_NAME="$flow_name" perl -0 -ne '
    my $flow = $ENV{FLOW_NAME} // "(unknown)";
    for my $type (qw(recordCreates recordUpdates recordDeletes actionCalls)) {
      my $re = qr/<${type}>([\s\S]*?)<\/${type}>/;
      while (m/$re/g) {
        my $block = $1;
        my ($name) = $block =~ /<name>([^<]+)<\/name>/;
        $name ||= "(unnamed)";
        while ($block =~ /<elementReference>((?:Loop_|currentItem_)[^<]+)<\/elementReference>/g) {
          print "$flow\t$type\t$name\t$1\n";
        }
      }
    }
  ' "$f" >> "$DML_OUT" 2>/dev/null || true
done

# De-dupe
sort -u "$LOOKUP_OUT" -o "$LOOKUP_OUT"
sort -u "$DML_OUT" -o "$DML_OUT"

echo "Loop-dependent lookups:"
awk -F'\t' 'NR==1 {next} {print "  " $1 " | " $2 " | " $3}' "$LOOKUP_OUT" | head -n 120

echo "Loop-dependent DML/actions:"
awk -F'\t' 'NR==1 {next} {print "  " $1 " | " $2 " | " $3 " | " $4}' "$DML_OUT" | head -n 120

echo "Lookup count: $(awk -F'\t' 'NR>1 {c++} END{print c+0}' "$LOOKUP_OUT")"
echo "DML/action count: $(awk -F'\t' 'NR>1 {c++} END{print c+0}' "$DML_OUT")"
echo "Reports:"
echo "  $LOOKUP_OUT"
echo "  $DML_OUT"
