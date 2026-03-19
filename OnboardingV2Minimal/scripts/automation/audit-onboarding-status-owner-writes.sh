#!/usr/bin/env bash
# Audit direct Onboarding__c.Onboarding_Status__c writes outside the single-owner evaluator path.
# Output: TSV with artifact, location, and violation classification.

set -euo pipefail

FLOWS_DIR="${1:-force-app/main/default/flows}"
CLASSES_DIR="${2:-force-app/main/default/classes}"
OUT_TSV="${3:-.analysis/automation-audit/onboarding_status_owner_audit.tsv}"

mkdir -p "$(dirname "$OUT_TSV")"
echo -e "ArtifactType\tArtifactName\tElementType\tElementName\tReference\tViolationType" > "$OUT_TSV"

# Allowed production Apex writer(s) for onboarding status.
ALLOWED_APEX_WRITERS_REGEX='^(OnboardingStatusEvaluatorService\.cls)$'

for f in "$FLOWS_DIR"/*.flow-meta.xml "$FLOWS_DIR"/*.flow; do
  [ -f "$f" ] || continue
  flow_name="$(basename "$f" | sed 's/\.flow-meta\.xml$//;s/\.flow$//')"

  FLOW_NAME="$flow_name" perl -0 -ne '
    my $flow = $ENV{FLOW_NAME} // "(unknown)";
    my $xml = $_;

    while ($xml =~ m/<recordUpdates>([\s\S]*?)<\/recordUpdates>/g) {
      my $block = $1;
      my ($name) = $block =~ /<name>([^<]+)<\/name>/;
      $name ||= "(unnamed)";
      while ($block =~ m/<inputAssignments>([\s\S]*?)<\/inputAssignments>/g) {
        my $assign = $1;
        my ($field) = $assign =~ /<field>([^<]+)<\/field>/;
        next unless defined $field;
        if ($field eq "Onboarding_Status__c") {
          print "flow\t$flow\trecordUpdates\t$name\t$field\tDIRECT_FLOW_FIELD_WRITE\n";
        }
      }
    }

    while ($xml =~ m/<assignments>([\s\S]*?)<\/assignments>/g) {
      my $block = $1;
      my ($name) = $block =~ /<name>([^<]+)<\/name>/;
      $name ||= "(unnamed)";
      while ($block =~ m/<assignmentItems>([\s\S]*?)<\/assignmentItems>/g) {
        my $item = $1;
        my ($target) = $item =~ /<assignToReference>([^<]+)<\/assignToReference>/;
        next unless defined $target;
        if ($target =~ /(^|\.)Onboarding_Status__c$/) {
          print "flow\t$flow\tassignments\t$name\t$target\tDIRECT_FLOW_ASSIGNMENT\n";
        }
      }
    }
  ' "$f" >> "$OUT_TSV" 2>/dev/null || true
done

for cls in "$CLASSES_DIR"/*.cls; do
  [ -f "$cls" ] || continue
  class_name="$(basename "$cls")"

  # Skip tests; they often seed status data intentionally.
  if [[ "$class_name" == *Test.cls || "$class_name" == Test*.cls ]]; then
    continue
  fi

  if [[ "$class_name" =~ $ALLOWED_APEX_WRITERS_REGEX ]]; then
    continue
  fi

  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    line_no="${hit%%:*}"
    echo -e "apex\t${class_name}\tclass\t${class_name}\tline:${line_no}\tDIRECT_APEX_FIELD_WRITE" >> "$OUT_TSV"
  done < <(rg -n "Onboarding_Status__c\\s*=" "$cls" || true)
done

violations="$(awk 'NR>1 {count++} END {print count+0}' "$OUT_TSV")"
echo "Onboarding status owner-write audit complete."
echo "Violations found: $violations"

if [ "$violations" -gt 0 ]; then
  echo "Violations:"
  awk -F'\t' 'NR>1 {print "  " $1 " | " $2 " | " $3 " | " $4 " | " $5 " | " $6}' "$OUT_TSV"
else
  echo "No direct writes found outside allowed owner path."
fi

echo "Report: $OUT_TSV"
