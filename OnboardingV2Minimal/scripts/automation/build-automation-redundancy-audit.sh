#!/usr/bin/env bash

set -euo pipefail

ORG_ALIAS="${1:-OnboardV2}"
OUT_DIR="${2:-.analysis/automation-audit}"
# Focus on onboarding-related flows first to keep metadata extraction practical.
FLOW_NAME_FILTER_REGEX="${FLOW_NAME_FILTER_REGEX:-Onboard|Onboarding|Vendor|Credential|LearnUpon|Opportunity|Contract|Training|Contact}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd sf
require_cmd jq
require_cmd rg
require_cmd awk
require_cmd sed
require_cmd comm

mkdir -p "$OUT_DIR"

REPO_FLOW_NAMES="$OUT_DIR/repo_flow_names.txt"
REPO_APEX_CLASS_NAMES="$OUT_DIR/repo_apex_class_names.txt"
REPO_TRIGGER_NAMES="$OUT_DIR/repo_trigger_names.txt"
REPO_INVOCABLE_CLASS_NAMES="$OUT_DIR/repo_invocable_class_names.txt"

ORG_FLOW_DEFS_CSV="$OUT_DIR/org_flow_definitions.csv"
ORG_FLOWS_CSV="$OUT_DIR/org_flows.csv"
ORG_APEX_CLASSES_CSV="$OUT_DIR/org_apex_classes.csv"
ORG_APEX_TRIGGERS_CSV="$OUT_DIR/org_apex_triggers.csv"

ORG_FLOW_NAMES_UNMANAGED="$OUT_DIR/org_flow_names_unmanaged.txt"
ORG_ACTIVE_FLOW_NAMES="$OUT_DIR/org_active_flow_names.txt"
ORG_APEX_CLASS_NAMES_UNMANAGED="$OUT_DIR/org_apex_class_names_unmanaged.txt"
ORG_TRIGGER_NAMES_UNMANAGED="$OUT_DIR/org_trigger_names_unmanaged.txt"

FLOW_COMMON="$OUT_DIR/flow_common_repo_org_unmanaged.txt"
FLOW_REPO_ONLY="$OUT_DIR/flow_repo_only.txt"
FLOW_ORG_ONLY="$OUT_DIR/flow_org_only_unmanaged.txt"

APEX_CLASS_COMMON="$OUT_DIR/apex_class_common_repo_org_unmanaged.txt"
APEX_CLASS_REPO_ONLY="$OUT_DIR/apex_class_repo_only.txt"
APEX_CLASS_ORG_ONLY="$OUT_DIR/apex_class_org_only_unmanaged.txt"

TRIGGER_COMMON="$OUT_DIR/trigger_common_repo_org_unmanaged.txt"
TRIGGER_REPO_ONLY="$OUT_DIR/trigger_repo_only.txt"
TRIGGER_ORG_ONLY="$OUT_DIR/trigger_org_only_unmanaged.txt"

TARGET_FLOW_NAMES="$OUT_DIR/target_flow_names.txt"
TARGET_FLOW_MAP_TSV="$OUT_DIR/target_active_flow_matrix.tsv"
ACTIVE_ORG_NOT_IN_REPO_TSV="$OUT_DIR/active_target_flows_org_only.tsv"
DUPLICATE_TRIGGER_GROUPS_TSV="$OUT_DIR/duplicate_record_trigger_groups.tsv"
APEX_USAGE_BY_FLOW_TSV="$OUT_DIR/active_flow_apex_usage.tsv"
INVOCABLE_USAGE_TSV="$OUT_DIR/invocable_class_usage.tsv"
SUMMARY_TXT="$OUT_DIR/summary.txt"

echo "Building repo inventory..."
rg --files force-app/main/default/flows \
  | sed -E 's#^.*/##; s#\.flow(-meta\.xml)?$##' \
  | sort -u > "$REPO_FLOW_NAMES"

rg --files -g '*.cls' force-app/main/default/classes \
  | sed -E 's#^.*/##; s#\.cls$##' \
  | sort -u > "$REPO_APEX_CLASS_NAMES"

if [ -d force-app/main/default/triggers ]; then
  rg --files -g '*.trigger' force-app/main/default/triggers \
    | sed -E 's#^.*/##; s#\.trigger$##' \
    | sort -u > "$REPO_TRIGGER_NAMES"
else
  : > "$REPO_TRIGGER_NAMES"
fi

rg -n "@InvocableMethod" force-app/main/default/classes/*.cls \
  | cut -d: -f1 \
  | sed -E 's#^.*/##; s#\.cls$##' \
  | sort -u > "$REPO_INVOCABLE_CLASS_NAMES"

echo "Exporting org inventory from alias '$ORG_ALIAS'..."
sf data query --target-org "$ORG_ALIAS" --use-tooling-api \
  --query "SELECT Id, DeveloperName, ActiveVersionId, LatestVersionId, NamespacePrefix, ManageableState FROM FlowDefinition ORDER BY DeveloperName" \
  --result-format csv > "$ORG_FLOW_DEFS_CSV"

sf data query --target-org "$ORG_ALIAS" --use-tooling-api \
  --query "SELECT Id, Definition.DeveloperName, VersionNumber, Status, ProcessType, LastModifiedDate FROM Flow ORDER BY Definition.DeveloperName, VersionNumber" \
  --result-format csv > "$ORG_FLOWS_CSV"

sf data query --target-org "$ORG_ALIAS" --use-tooling-api \
  --query "SELECT Id, Name, NamespacePrefix, ApiVersion, Status, LengthWithoutComments, LastModifiedDate FROM ApexClass ORDER BY Name" \
  --result-format csv > "$ORG_APEX_CLASSES_CSV"

sf data query --target-org "$ORG_ALIAS" --use-tooling-api \
  --query "SELECT Id, Name, NamespacePrefix, TableEnumOrId, ApiVersion, Status, LastModifiedDate FROM ApexTrigger ORDER BY Name" \
  --result-format csv > "$ORG_APEX_TRIGGERS_CSV"

echo "Computing repo/org overlap..."
awk -F, 'NR>1 && $5=="" {print $2}' "$ORG_FLOW_DEFS_CSV" | sort -u > "$ORG_FLOW_NAMES_UNMANAGED"
awk -F, 'NR>1 && $4=="Active" {print $2}' "$ORG_FLOWS_CSV" | sort -u > "$ORG_ACTIVE_FLOW_NAMES"
awk -F, 'NR>1 && $3=="" {print $2}' "$ORG_APEX_CLASSES_CSV" | sort -u > "$ORG_APEX_CLASS_NAMES_UNMANAGED"
awk -F, 'NR>1 && $3=="" {print $2}' "$ORG_APEX_TRIGGERS_CSV" | sort -u > "$ORG_TRIGGER_NAMES_UNMANAGED"

comm -12 "$REPO_FLOW_NAMES" "$ORG_FLOW_NAMES_UNMANAGED" > "$FLOW_COMMON"
comm -23 "$REPO_FLOW_NAMES" "$ORG_FLOW_NAMES_UNMANAGED" > "$FLOW_REPO_ONLY"
comm -13 "$REPO_FLOW_NAMES" "$ORG_FLOW_NAMES_UNMANAGED" > "$FLOW_ORG_ONLY"

comm -12 "$REPO_APEX_CLASS_NAMES" "$ORG_APEX_CLASS_NAMES_UNMANAGED" > "$APEX_CLASS_COMMON"
comm -23 "$REPO_APEX_CLASS_NAMES" "$ORG_APEX_CLASS_NAMES_UNMANAGED" > "$APEX_CLASS_REPO_ONLY"
comm -13 "$REPO_APEX_CLASS_NAMES" "$ORG_APEX_CLASS_NAMES_UNMANAGED" > "$APEX_CLASS_ORG_ONLY"

comm -12 "$REPO_TRIGGER_NAMES" "$ORG_TRIGGER_NAMES_UNMANAGED" > "$TRIGGER_COMMON"
comm -23 "$REPO_TRIGGER_NAMES" "$ORG_TRIGGER_NAMES_UNMANAGED" > "$TRIGGER_REPO_ONLY"
comm -13 "$REPO_TRIGGER_NAMES" "$ORG_TRIGGER_NAMES_UNMANAGED" > "$TRIGGER_ORG_ONLY"

echo "Selecting target flows by name pattern..."
grep -Ei "$FLOW_NAME_FILTER_REGEX" "$ORG_FLOW_NAMES_UNMANAGED" | sort -u > "$TARGET_FLOW_NAMES" || true

echo -e "FlowName\tInRepo\tHasActiveVersion\tActiveVersion\tProcessType\tStartObject\tTriggerType\tRecordTriggerType\tApexClasses\tActionCalls\tSubflows" > "$TARGET_FLOW_MAP_TSV"

while IFS= read -r flow_name; do
  [ -z "$flow_name" ] && continue

  if grep -Fxq "$flow_name" "$REPO_FLOW_NAMES"; then
    in_repo="Y"
  else
    in_repo="N"
  fi

  query_json="$(sf data query --target-org "$ORG_ALIAS" --use-tooling-api \
    --query "SELECT Id, VersionNumber, Metadata FROM Flow WHERE Definition.DeveloperName = '$flow_name' AND Status = 'Active' ORDER BY VersionNumber DESC LIMIT 1" \
    --result-format json)"

  active_count="$(printf '%s' "$query_json" | jq -r '.result.totalSize // 0')"
  if [ "$active_count" = "0" ]; then
    printf "%s\t%s\tN\t\t\t\t\t\t\t\t\n" "$flow_name" "$in_repo" >> "$TARGET_FLOW_MAP_TSV"
    continue
  fi

  active_version="$(printf '%s' "$query_json" | jq -r '.result.records[0].VersionNumber // ""')"
  process_type="$(printf '%s' "$query_json" | jq -r '.result.records[0].Metadata.processType // ""')"
  start_object="$(printf '%s' "$query_json" | jq -r '.result.records[0].Metadata.start.object // ""')"
  trigger_type="$(printf '%s' "$query_json" | jq -r '.result.records[0].Metadata.start.triggerType // ""')"
  record_trigger_type="$(printf '%s' "$query_json" | jq -r '.result.records[0].Metadata.start.recordTriggerType // ""')"

  apex_classes="$(printf '%s' "$query_json" | jq -r '[.result.records[0].Metadata.apexPluginCalls[]?.apexClass | select(. != null and . != "")] | unique | join(";")')"
  action_calls="$(printf '%s' "$query_json" | jq -r '[.result.records[0].Metadata.actionCalls[]?.actionName | select(. != null and . != "")] | unique | join(";")')"
  subflows="$(printf '%s' "$query_json" | jq -r '[.result.records[0].Metadata.subflows[]?.flowName | select(. != null and . != "")] | unique | join(";")')"

  printf "%s\t%s\tY\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$flow_name" \
    "$in_repo" \
    "$active_version" \
    "$process_type" \
    "$start_object" \
    "$trigger_type" \
    "$record_trigger_type" \
    "$apex_classes" \
    "$action_calls" \
    "$subflows" >> "$TARGET_FLOW_MAP_TSV"
done < "$TARGET_FLOW_NAMES"

awk -F'\t' 'NR==1 || ($2=="N" && $3=="Y") {print}' "$TARGET_FLOW_MAP_TSV" > "$ACTIVE_ORG_NOT_IN_REPO_TSV"

{
  echo -e "StartObject\tTriggerType\tRecordTriggerType\tFlowCount\tFlows"
  awk -F'\t' '
    NR==1 {next}
    $3=="Y" && $6!="" && $7!="" {
      key=$6 "|" $7 "|" $8
      if (flows[key] == "") {
        flows[key]=$1
        count[key]=1
      } else {
        flows[key]=flows[key] ";" $1
        count[key]++
      }
    }
    END {
      for (k in flows) {
        if (count[k] > 1) {
          split(k, parts, "|")
          print parts[1] "\t" parts[2] "\t" parts[3] "\t" count[k] "\t" flows[k]
        }
      }
    }
  ' "$TARGET_FLOW_MAP_TSV" | sort
} > "$DUPLICATE_TRIGGER_GROUPS_TSV"

awk -F'\t' '
  function add_ref(name, flow_name) {
    gsub(/^ +| +$/, "", name)
    if (name == "") {
      return
    }
    if (flow_map[name] == "") {
      flow_map[name] = flow_name
    } else if (index(";" flow_map[name] ";", ";" flow_name ";") == 0) {
      flow_map[name] = flow_map[name] ";" flow_name
    }
  }

  NR==1 {next}
  $3=="Y" {
    if ($9 != "") {
      n=split($9, classes, ";")
      for (i=1; i<=n; i++) {
        add_ref(classes[i], $1)
      }
    }
    if ($10 != "") {
      m=split($10, actions, ";")
      for (j=1; j<=m; j++) {
        add_ref(actions[j], $1)
      }
    }
  }
  END {
    print "ApexClass\tFlows"
    for (cls in flow_map) {
      print cls "\t" flow_map[cls]
    }
  }
' "$TARGET_FLOW_MAP_TSV" | sort > "$APEX_USAGE_BY_FLOW_TSV"

echo -e "ApexClass\tIsInvocableInRepo\tReferencedByActiveTargetFlows\tTargetFlows" > "$INVOCABLE_USAGE_TSV"
while IFS= read -r class_name; do
  [ -z "$class_name" ] && continue
  ref_flows="$(awk -F'\t' -v cls="$class_name" 'NR>1 && $1==cls {print $2}' "$APEX_USAGE_BY_FLOW_TSV")"
  if [ -n "$ref_flows" ]; then
    referenced="Y"
  else
    referenced="N"
  fi
  printf "%s\tY\t%s\t%s\n" "$class_name" "$referenced" "$ref_flows" >> "$INVOCABLE_USAGE_TSV"
done < "$REPO_INVOCABLE_CLASS_NAMES"

{
  echo "Org Alias: $ORG_ALIAS"
  echo "Generated At: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo
  echo "Counts"
  echo "repo_flows=$(wc -l < "$REPO_FLOW_NAMES")"
  echo "org_unmanaged_flows=$(wc -l < "$ORG_FLOW_NAMES_UNMANAGED")"
  echo "flow_common=$(wc -l < "$FLOW_COMMON")"
  echo "flow_repo_only=$(wc -l < "$FLOW_REPO_ONLY")"
  echo "flow_org_only=$(wc -l < "$FLOW_ORG_ONLY")"
  echo
  echo "repo_apex_classes=$(wc -l < "$REPO_APEX_CLASS_NAMES")"
  echo "org_unmanaged_apex_classes=$(wc -l < "$ORG_APEX_CLASS_NAMES_UNMANAGED")"
  echo "apex_class_common=$(wc -l < "$APEX_CLASS_COMMON")"
  echo "apex_class_repo_only=$(wc -l < "$APEX_CLASS_REPO_ONLY")"
  echo "apex_class_org_only=$(wc -l < "$APEX_CLASS_ORG_ONLY")"
  echo
  echo "repo_triggers=$(wc -l < "$REPO_TRIGGER_NAMES")"
  echo "org_unmanaged_triggers=$(wc -l < "$ORG_TRIGGER_NAMES_UNMANAGED")"
  echo "trigger_common=$(wc -l < "$TRIGGER_COMMON")"
  echo "trigger_repo_only=$(wc -l < "$TRIGGER_REPO_ONLY")"
  echo "trigger_org_only=$(wc -l < "$TRIGGER_ORG_ONLY")"
  echo
  echo "target_flows=$(($(wc -l < "$TARGET_FLOW_NAMES")))"
  echo "active_target_flows_not_in_repo=$(($(wc -l < "$ACTIVE_ORG_NOT_IN_REPO_TSV") - 1))"
  echo "duplicate_record_trigger_groups=$(($(wc -l < "$DUPLICATE_TRIGGER_GROUPS_TSV") - 1))"
  echo "repo_invocable_classes=$(wc -l < "$REPO_INVOCABLE_CLASS_NAMES")"
} > "$SUMMARY_TXT"

echo "Done. Outputs:"
echo "  $SUMMARY_TXT"
echo "  $TARGET_FLOW_MAP_TSV"
echo "  $ACTIVE_ORG_NOT_IN_REPO_TSV"
echo "  $DUPLICATE_TRIGGER_GROUPS_TSV"
echo "  $INVOCABLE_USAGE_TSV"
