#!/usr/bin/env bash
# Audit all flows that call DOMAIN_OmniSObject_SFL_CREATE_Fault_Message.
# Enforce required context inputs on each call:
# - SourceElementApiName
# - SourceElementLabel
# - SourceFlowApiName
# - InterviewGuid
#
# One flow is intentionally deferred by user direction and excluded:
# - DOMAIN_OmniSObject_SFL_Send_Email_Communication

set -euo pipefail

FLOWS_DIR="${1:-force-app/main/default/flows}"
OUT_TSV="${2:-.analysis/automation-audit/fault_message_context_contract_audit.tsv}"
DEFERRED_FLOW="DOMAIN_OmniSObject_SFL_Send_Email_Communication"

mkdir -p "$(dirname "$OUT_TSV")"
echo -e "FlowName\tSubflowElement\tRequirement\tPass\tNotes" > "$OUT_TSV"

for f in "$FLOWS_DIR"/*.flow-meta.xml "$FLOWS_DIR"/*.flow; do
  [ -f "$f" ] || continue
  flow_name="$(basename "$f" | sed 's/\.flow-meta\.xml$//;s/\.flow$//')"

  if [ "$flow_name" = "$DEFERRED_FLOW" ]; then
    continue
  fi

  FLOW_NAME="$flow_name" perl -0 -ne '
    my $flow = $ENV{FLOW_NAME} // "(unknown)";
    my $xml = $_;

    while ($xml =~ m/<subflows>([\s\S]*?)<\/subflows>/g) {
      my $block = $1;
      next unless $block =~ /<flowName>DOMAIN_OmniSObject_SFL_CREATE_Fault_Message<\/flowName>/;
      my ($name) = $block =~ /<name>([^<]+)<\/name>/;
      $name ||= "(unnamed)";

      my $has_source_element_api = ($block =~ /<inputAssignments>[\s\S]*?<name>SourceElementApiName<\/name>[\s\S]*?<\/inputAssignments>/) ? "yes" : "no";
      my $has_source_element_label = ($block =~ /<inputAssignments>[\s\S]*?<name>SourceElementLabel<\/name>[\s\S]*?<\/inputAssignments>/) ? "yes" : "no";
      my $has_source_flow_api = ($block =~ /<inputAssignments>[\s\S]*?<name>SourceFlowApiName<\/name>[\s\S]*?<\/inputAssignments>/) ? "yes" : "no";
      my $has_interview_guid = ($block =~ /<inputAssignments>[\s\S]*?<name>InterviewGuid<\/name>[\s\S]*?<\/inputAssignments>/) ? "yes" : "no";

      print "$flow\t$name\tPASS_SOURCEELEMENTAPINAME\t$has_source_element_api\t-\n";
      print "$flow\t$name\tPASS_SOURCEELEMENTLABEL\t$has_source_element_label\t-\n";
      print "$flow\t$name\tPASS_SOURCEFLOWAPINAME\t$has_source_flow_api\t-\n";
      print "$flow\t$name\tPASS_INTERVIEWGUID\t$has_interview_guid\t-\n";
    }
  ' "$f" >> "$OUT_TSV" 2>/dev/null || true
done

violations="$(awk -F'\t' 'NR>1 && $4=="no" {count++} END {print count+0}' "$OUT_TSV")"
echo "Fault-message context contract audit complete."
echo "Violations found: $violations"

if [ "$violations" -gt 0 ]; then
  echo "Violations:"
  awk -F'\t' 'NR>1 && $4=="no" {print "  " $1 " | " $2 " | " $3}' "$OUT_TSV" | head -n 120
fi

echo "Report: $OUT_TSV"
