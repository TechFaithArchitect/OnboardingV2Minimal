#!/usr/bin/env bash
# Audit loop connector targets by element type.

set -euo pipefail

FLOWS_DIR="${1:-force-app/main/default/flows}"
OUT="${2:-.analysis/automation-audit/flow_loop_connector_audit.tsv}"

mkdir -p "$(dirname "$OUT")"
echo -e "FlowName\tLoopName\tConnectorType\tTargetReference\tTargetElementType" > "$OUT"

for f in "$FLOWS_DIR"/*.flow-meta.xml "$FLOWS_DIR"/*.flow; do
  [ -f "$f" ] || continue
  flow_name="$(basename "$f" | sed 's/\.flow-meta\.xml$//;s/\.flow$//')"

  FLOW_NAME="$flow_name" perl -0 -ne '
    my $flow = $ENV{FLOW_NAME} // "(unknown)";
    my $xml = $_;

    my %name_to_type = ();
    for my $type (qw(assignments decisions recordLookups recordCreates recordUpdates recordDeletes actionCalls subflows screens loops starts start collectionProcessors collectionSorts collectionChoices transforms)) {
      my $re = qr/<${type}>([\s\S]*?)<\/${type}>/;
      while ($xml =~ m/$re/g) {
        my $block = $1;
        my ($name) = $block =~ /<name>([^<]+)<\/name>/;
        next unless defined $name;
        $name_to_type{$name} = $type;
      }
    }

    while ($xml =~ m/<loops>([\s\S]*?)<\/loops>/g) {
      my $loop_block = $1;
      my ($loop_name) = $loop_block =~ /<name>([^<]+)<\/name>/;
      $loop_name ||= "(unnamed)";

      if ($loop_block =~ /<nextValueConnector>[\s\S]*?<targetReference>([^<]+)<\/targetReference>[\s\S]*?<\/nextValueConnector>/) {
        my $t = $1;
        my $tt = $name_to_type{$t} // "(unknown)";
        print "$flow\t$loop_name\tnextValueConnector\t$t\t$tt\n";
      }
      if ($loop_block =~ /<noMoreValuesConnector>[\s\S]*?<targetReference>([^<]+)<\/targetReference>[\s\S]*?<\/noMoreValuesConnector>/) {
        my $t = $1;
        my $tt = $name_to_type{$t} // "(unknown)";
        print "$flow\t$loop_name\tnoMoreValuesConnector\t$t\t$tt\n";
      }
    }
  ' "$f" >> "$OUT" 2>/dev/null || true
done

echo "Loop connectors by target type (top):"
awk -F'\t' 'NR>1 {c[$5]++} END {for (k in c) print c[k] "\t" k}' "$OUT" | sort -nr | head -n 20

echo "Potentially risky loop connectors (nextValue -> recordLookups/recordCreates/recordUpdates/recordDeletes/actionCalls):"
awk -F'\t' 'NR>1 && $3=="nextValueConnector" && ($5=="recordLookups" || $5=="recordCreates" || $5=="recordUpdates" || $5=="recordDeletes" || $5=="actionCalls") {print "  " $1 " | " $2 " | " $3 " -> " $4 " (" $5 ")"}' "$OUT" | head -n 120

echo "Review candidates (nextValue -> subflows):"
awk -F'\t' 'NR>1 && $3=="nextValueConnector" && $5=="subflows" {print "  " $1 " | " $2 " | " $3 " -> " $4 " (" $5 ")"}' "$OUT" | head -n 120

echo "Report: $OUT"
