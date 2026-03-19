#!/usr/bin/env bash
# Audit user-facing Screen Flows that call shared fault handler:
# enforce UserFacingMessage mapping + InterviewGuid + SourceElementLabel inputs.

set -euo pipefail

FLOWS_DIR="${1:-force-app/main/default/flows}"
OUT_TSV="${2:-.analysis/automation-audit/screen_flow_fault_user_messaging_audit.tsv}"

mkdir -p "$(dirname "$OUT_TSV")"
echo -e "FlowName\tSubflowElement\tRequirement\tPass" > "$OUT_TSV"

for f in "$FLOWS_DIR"/*.flow-meta.xml "$FLOWS_DIR"/*.flow; do
  [ -f "$f" ] || continue
  flow_name="$(basename "$f" | sed 's/\.flow-meta\.xml$//;s/\.flow$//')"

  FLOW_NAME="$flow_name" perl -0 -ne '
    my $flow = $ENV{FLOW_NAME} // "(unknown)";
    my $xml = $_;

    my $is_screen_flow = ($xml =~ /<processType>Flow<\/processType>/ && $xml =~ /<screens>/) ? 1 : 0;
    exit 0 unless $is_screen_flow;

    while ($xml =~ m/<subflows>([\s\S]*?)<\/subflows>/g) {
      my $block = $1;
      next unless $block =~ /<flowName>DOMAIN_OmniSObject_SFL_CREATE_Fault_Message<\/flowName>/;
      my ($name) = $block =~ /<name>([^<]+)<\/name>/;
      $name ||= "(unnamed)";

      my $maps_user_message = ($block =~ /<outputAssignments>[\s\S]*?<name>UserFacingMessage<\/name>[\s\S]*?<\/outputAssignments>/) ? "yes" : "no";
      my $has_interview_guid = ($block =~ /<inputAssignments>[\s\S]*?<name>InterviewGuid<\/name>[\s\S]*?<\/inputAssignments>/) ? "yes" : "no";
      my $has_source_label = ($block =~ /<inputAssignments>[\s\S]*?<name>SourceElementLabel<\/name>[\s\S]*?<\/inputAssignments>/) ? "yes" : "no";

      print "$flow\t$name\tMAP_USERFACINGMESSAGE_OUTPUT\t$maps_user_message\n";
      print "$flow\t$name\tPASS_INTERVIEWGUID\t$has_interview_guid\n";
      print "$flow\t$name\tPASS_SOURCEELEMENTLABEL\t$has_source_label\n";
    }
  ' "$f" >> "$OUT_TSV" 2>/dev/null || true
done

violations="$(awk -F'\t' 'NR>1 && $4=="no" {count++} END {print count+0}' "$OUT_TSV")"
echo "Screen-flow fault user-messaging audit complete."
echo "Violations found: $violations"

if [ "$violations" -gt 0 ]; then
  echo "Violations:"
  awk -F'\t' 'NR>1 && $4=="no" {print "  " $1 " | " $2 " | " $3}' "$OUT_TSV" | head -n 80
fi

echo "Report: $OUT_TSV"
